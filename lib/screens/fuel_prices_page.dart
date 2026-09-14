import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app.dart';
import '../models/region_profile.dart';
import '../models/station_price.dart';
import '../services/fuelwatch_service.dart';
import '../services/local_store.dart';
import '../services/location_service.dart';
import '../services/sri_lanka_price_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/neviro_brand.dart';

class FuelPricesPage extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;
  final bool active;
  final ValueChanged<StationPrice> onUseForFillUp;

  const FuelPricesPage({
    super.key,
    required this.store,
    required this.profile,
    this.active = false,
    required this.onUseForFillUp,
  });

  @override
  State<FuelPricesPage> createState() => _FuelPricesPageState();
}

class _FuelPricesPageState extends State<FuelPricesPage> {
  final suburbController = TextEditingController();
  bool loading = false;
  bool mapView = true;
  String? error;
  String selectedWaFuel = 'Unleaded 91';
  String detectedArea = '';
  String detectedState = '';
  double? userLat;
  double? userLng;
  DateTime? lastUpdated;
  List<StationPrice> waPrices = <StationPrice>[];
  List<NationalFuelPrice> lkPrices = <NationalFuelPrice>[];

  bool get isAustralia => widget.profile.code == 'AU';
  bool get isSriLanka => widget.profile.code == 'LK';

  @override
  void initState() {
    super.initState();
    if (widget.active) Future.microtask(_initialLoad);
  }

  @override
  void didUpdateWidget(covariant FuelPricesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.code != widget.profile.code) {
      waPrices = <StationPrice>[];
      lkPrices = <NationalFuelPrice>[];
      error = null;
      if (widget.active) Future.microtask(_initialLoad);
      return;
    }
    if (!oldWidget.active && widget.active) {
      Future.microtask(_initialLoad);
    }
  }

  @override
  void dispose() {
    suburbController.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    if (isSriLanka) {
      await _loadSriLanka();
      return;
    }
    if (isAustralia) {
      await _useMyLocation(silent: true);
    }
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await LocationService.currentArea();
      userLat = result.position.latitude;
      userLng = result.position.longitude;
      detectedArea = result.suburb;
      detectedState = result.state;
      if (result.suburb.isNotEmpty) suburbController.text = result.suburb;

      final isWa = result.state.toLowerCase().contains('western australia') ||
          result.state.toLowerCase() == 'wa';
      if (!isWa) {
        setState(() {
          error = 'Live station-by-station prices are currently enabled for Western Australia first. You can still track fuel manually anywhere.';
        });
        return;
      }
      if (result.suburb.isEmpty) {
        setState(() => error = 'Your location was found, but the suburb could not be identified. Enter a WA suburb or postcode below.');
        return;
      }
      await _loadWaPrices();
    } catch (e) {
      if (!silent) {
        setState(() => error = 'Location could not be detected. Enter a WA suburb below instead.');
      } else {
        setState(() => error = 'Use your location or enter a WA suburb to compare prices.');
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadWaPrices() async {
    final suburb = suburbController.text.trim();
    if (suburb.isEmpty) {
      setState(() => error = 'Enter a WA suburb, for example Cannington, Joondalup or Perth.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await FuelWatchService.fetchWaPrices(
        suburb: suburb,
        fuelType: selectedWaFuel,
        userLatitude: userLat,
        userLongitude: userLng,
      );
      final updated = DateTime.now();
      setState(() {
        waPrices = rows;
        lastUpdated = updated;
        detectedArea = suburb;
        if (rows.isEmpty) error = 'No FuelWatch prices were found for that area and fuel type.';
      });
      if (rows.isNotEmpty) {
        await widget.store.cacheCheapest(station: rows.first, area: suburb, updated: updated);
      }
    } catch (_) {
      setState(() => error = 'FuelWatch could not be loaded. Check your internet connection and try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _loadSriLanka() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await SriLankaPriceService.fetchCurrentPrices();
      setState(() {
        lkPrices = rows;
        lastUpdated = DateTime.now();
      });
    } catch (_) {
      setState(() => error = 'Official Sri Lanka fuel prices are unavailable right now. You can still add fuel manually.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openDirections(StationPrice station) async {
    final lat = station.latitude;
    final lng = station.longitude;
    final query = Uri.encodeComponent('${station.station}, ${station.address}, ${station.suburb}');
    Uri uri;
    if (lat != null && lng != null) {
      if (Platform.isIOS) {
        uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
      } else {
        uri = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
      }
    } else {
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: <Widget>[
        const Row(
          children: <Widget>[
            Expanded(child: NeviroBrand(compact: true)),
          ],
        ),
        const SizedBox(height: 18),
        const Text('Fuel Prices', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        Text(
          isSriLanka ? 'Latest official national fuel prices' : 'FuelWatch prices within 10 km of your location',
          style: const TextStyle(color: kNeviroMuted),
        ),
        const SizedBox(height: 18),
        if (isAustralia) _buildAustralia(),
        if (isSriLanka) _buildSriLanka(),
        if (!isAustralia && !isSriLanka)
          const EmptyState(
            icon: Icons.public_rounded,
            title: 'Live prices are not available here yet',
            message: 'NEVIRO still works as a fuel tracker. Live station-price integrations will expand country by country.',
          ),
      ],
    );
  }

  Widget _buildAustralia() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
          child: Row(
            children: <Widget>[
              const Icon(Icons.location_on_rounded, color: kNeviroGreen),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(detectedArea.isEmpty ? 'Western Australia' : '$detectedArea${detectedState.isEmpty ? '' : ', WA'}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    Text(detectedArea.isEmpty ? 'Location loads automatically' : 'Showing FuelWatch results within 10 km', style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Locate',
                onPressed: loading ? null : () => _useMyLocation(),
                icon: const Icon(Icons.my_location_rounded, color: kNeviroGreenDark),
              ),
              IconButton(
                tooltip: 'Refresh prices',
                onPressed: loading ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded, color: kNeviroGreenDark),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: suburbController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _loadWaPrices(),
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Suburb, e.g. Cannington'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 56,
              child: FilledButton(
                onPressed: loading ? null : _loadWaPrices,
                style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: Colors.white),
                child: const Icon(Icons.arrow_forward_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: selectedWaFuel,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.local_gas_station_rounded)),
          items: FuelWatchService.products.keys.map((String fuel) => DropdownMenuItem<String>(value: fuel, child: Text(fuel))).toList(),
          onChanged: loading
              ? null
              : (value) async {
                  setState(() => selectedWaFuel = value ?? selectedWaFuel);
                  if (suburbController.text.trim().isNotEmpty) await _loadWaPrices();
                },
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _ModeButton(active: mapView, icon: Icons.map_rounded, label: 'Map', onTap: () => setState(() => mapView = true))),
            const SizedBox(width: 10),
            Expanded(child: _ModeButton(active: !mapView, icon: Icons.list_rounded, label: 'List', onTap: () => setState(() => mapView = false))),
          ],
        ),
        if (loading) ...<Widget>[
          const SizedBox(height: 22),
          const Center(child: CircularProgressIndicator(color: kNeviroGreen)),
        ],
        if (error != null) ...<Widget>[
          const SizedBox(height: 14),
          _InfoBox(text: error!, icon: Icons.info_outline_rounded),
        ],
        if (waPrices.isNotEmpty) ...<Widget>[
          const SizedBox(height: 14),
          if (mapView) _buildMap(),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Stations within 10 km', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900))),
              if (lastUpdated != null) Text(_timeText(lastUpdated!), style: const TextStyle(color: kNeviroMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          ...waPrices.asMap().entries.map((entry) => _StationCard(
                station: entry.value,
                cheapest: entry.key == 0,
                onDirections: () => _openDirections(entry.value),
                onUse: () => widget.onUseForFillUp(entry.value),
              )),
          const SizedBox(height: 10),
          const _InfoBox(
            icon: Icons.verified_rounded,
            text: 'Prices are sourced from the official FuelWatch RSS feed and filtered to 10 km when location coordinates are available. FuelWatch RSS supplies up to the 10 cheapest results for the searched area.',
          ),
        ],
      ],
    );
  }

  Widget _buildMap() {
    final withCoords = waPrices.where((StationPrice e) => e.latitude != null && e.longitude != null).toList();
    if (withCoords.isEmpty) {
      return const _InfoBox(icon: Icons.map_outlined, text: 'Map coordinates were not included for these results. Use List view to compare stations.');
    }
    final center = userLat != null && userLng != null
        ? LatLng(userLat!, userLng!)
        : LatLng(withCoords.first.latitude!, withCoords.first.longitude!);

    return SizedBox(
      height: 320,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: <Widget>[
            FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 11.5),
              children: <Widget>[
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.neviro.neviro',
                ),
                MarkerLayer(
                  markers: <Marker>[
                    if (userLat != null && userLng != null)
                      Marker(
                        point: LatLng(userLat!, userLng!),
                        width: 38,
                        height: 38,
                        child: const Icon(Icons.my_location_rounded, color: Color(0xFF3A83F7), size: 30),
                      ),
                    ...withCoords.map(
                      (StationPrice station) => Marker(
                        point: LatLng(station.latitude!, station.longitude!),
                        width: 70,
                        height: 58,
                        child: GestureDetector(
                          onTap: () => _showStationSheet(station),
                          child: Column(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                                decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(10), border: Border.all(color: kNeviroGreen)),
                                child: Text(station.priceCentsPerLitre.toStringAsFixed(1), style: const TextStyle(color: kNeviroGreenDark, fontWeight: FontWeight.w900, fontSize: 11)),
                              ),
                              const Icon(Icons.location_on_rounded, color: kNeviroGreen, size: 24),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 8,
              bottom: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.62), borderRadius: BorderRadius.circular(8)),
                child: const Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9, color: Colors.white70)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showStationSheet(StationPrice station) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kNeviroCard,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(station.station, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 5),
            Text('${station.address}, ${station.suburb}', style: const TextStyle(color: kNeviroMuted)),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: Text('${station.priceCentsPerLitre.toStringAsFixed(1)} c/L', style: const TextStyle(color: kNeviroGreen, fontWeight: FontWeight.w900, fontSize: 24))),
                if (station.distanceKm != null) Text('${station.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(color: kNeviroMuted)),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                Expanded(child: OutlinedButton.icon(onPressed: () => _openDirections(station), icon: const Icon(Icons.directions_rounded), label: const Text('Directions'))),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onUseForFillUp(station);
                    },
                    style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: Colors.white),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add Fill-up'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSriLanka() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
          child: const Row(
            children: <Widget>[
              Icon(Icons.public_rounded, color: kNeviroGreen),
              SizedBox(width: 10),
              Expanded(child: Text('Sri Lanka • Official national fuel prices', style: TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        ),
        if (loading) ...<Widget>[
          const SizedBox(height: 22),
          const Center(child: CircularProgressIndicator(color: kNeviroGreen)),
        ],
        if (error != null) ...<Widget>[
          const SizedBox(height: 14),
          _InfoBox(icon: Icons.info_outline, text: error!),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: _loadSriLanka, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again')),
        ],
        if (lkPrices.isNotEmpty) ...<Widget>[
          const SizedBox(height: 16),
          ...lkPrices.map(
            (NationalFuelPrice item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: <Widget>[
                  const CircleAvatar(backgroundColor: kNeviroCard2, child: Icon(Icons.local_gas_station_rounded, color: kNeviroGreenDark)),
                  const SizedBox(width: 12),
                  Expanded(child: Text(item.fuelType, style: const TextStyle(fontWeight: FontWeight.w800))),
                  Text('Rs. ${item.pricePerLitre.toStringAsFixed(2)}', style: const TextStyle(color: kNeviroGreen, fontWeight: FontWeight.w900, fontSize: 18)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          const _InfoBox(
            icon: Icons.verified_rounded,
            text: 'Sri Lanka does not currently use the same FuelWatch-style station-by-station feed here. NEVIRO shows the latest official national price it can read from Ceypetco.',
          ),
        ],
      ],
    );
  }

  Future<void> _refresh() async {
    if (isSriLanka) {
      await _loadSriLanka();
      return;
    }
    if (isAustralia) {
      if (userLat == null || userLng == null || suburbController.text.trim().isEmpty) {
        await _useMyLocation();
      } else {
        await _loadWaPrices();
      }
    }
  }

  static String _timeText(DateTime value) {
    final minutes = DateTime.now().difference(value).inMinutes;
    if (minutes <= 0) return 'Updated just now';
    if (minutes == 1) return 'Updated 1 min ago';
    if (minutes < 60) return 'Updated $minutes min ago';
    final h = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final m = value.minute.toString().padLeft(2, '0');
    final ap = value.hour >= 12 ? 'PM' : 'AM';
    return 'Updated $h:$m $ap';
  }
}

class _ModeButton extends StatelessWidget {
  final bool active;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ModeButton({required this.active, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? kNeviroGreen : kNeviroCard,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: active ? kNeviroGreen : kNeviroBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: active ? Colors.white : kNeviroMuted),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: active ? Colors.white : kNeviroDark, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _StationCard extends StatelessWidget {
  final StationPrice station;
  final bool cheapest;
  final VoidCallback onDirections;
  final VoidCallback onUse;

  const _StationCard({required this.station, required this.cheapest, required this.onDirections, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: kNeviroCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cheapest ? kNeviroGreen : kNeviroBorder, width: cheapest ? 1.4 : 1),
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              const CircleAvatar(backgroundColor: kNeviroCard2, child: Icon(Icons.local_gas_station_rounded, color: kNeviroGreenDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(child: Text(station.station, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
                        if (cheapest) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: kNeviroGreen, borderRadius: BorderRadius.circular(9)),
                            child: const Text('Cheapest', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text('${station.address}${station.suburb.isEmpty ? '' : ', ${station.suburb}'}', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text('${station.priceCentsPerLitre.toStringAsFixed(1)} c/L', style: TextStyle(color: cheapest ? kNeviroGreenDark : kNeviroDark, fontWeight: FontWeight.w900, fontSize: 18)),
                  if (station.distanceKm != null) Text('${station.distanceKm!.toStringAsFixed(1)} km', style: const TextStyle(color: kNeviroMuted, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: OutlinedButton.icon(onPressed: onDirections, icon: const Icon(Icons.directions_rounded, size: 18), label: const Text('Directions'))),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onUse,
                  style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: Colors.white),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Use Price'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoBox({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kNeviroCard2,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kNeviroBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: kNeviroGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: kNeviroDark, fontSize: 12.5, height: 1.4))),
        ],
      ),
    );
  }
}
