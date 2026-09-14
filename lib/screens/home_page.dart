import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/fuel_entry.dart';
import '../models/region_profile.dart';
import '../services/fuel_math.dart';
import '../services/local_store.dart';
import '../widgets/metric_card.dart';
import '../widgets/neviro_brand.dart';
import 'settings_page.dart';

class HomePage extends StatelessWidget {
  final LocalStore store;
  final RegionProfile profile;
  final VoidCallback onOpenFuelPrices;
  final VoidCallback onAddFuel;

  const HomePage({
    super.key,
    required this.store,
    required this.profile,
    required this.onOpenFuelPrices,
    required this.onAddFuel,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthEntries = store.entries.where((FuelEntry e) => e.date.year == now.year && e.date.month == now.month).toList();
    final totalSpend = FuelMath.totalSpend(monthEntries);
    final totalLitres = FuelMath.totalLitres(monthEntries);
    final avgPrice = FuelMath.averagePricePerLitre(monthEntries);
    final avgEfficiency = FuelMath.averageEfficiencyLPer100Km(store.entries);
    final latest = store.entries.isEmpty ? null : store.entries.first;
    final latestDistance = latest == null ? null : FuelMath.distanceForEntry(latest, store.entries);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: <Widget>[
          Row(
            children: <Widget>[
              const Expanded(child: NeviroBrand()),
              IconButton(
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => SettingsPage(store: store, profile: profile)),
                  );
                },
                icon: const Icon(Icons.settings_rounded),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(_greeting(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Keep track. Save more. Go further.', style: TextStyle(color: kNeviroMuted)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFF0B4B3C), Color(0xFF0B332B)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: kNeviroGreen.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('This Month', style: TextStyle(color: kNeviroMuted)),
                const SizedBox(height: 6),
                Text(money(store, profile, totalSpend), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(child: _SmallValue(label: 'Litres', value: '${totalLitres.toStringAsFixed(1)} L')),
                    const SizedBox(width: 10),
                    Expanded(child: _SmallValue(label: 'Avg. Price/L', value: money(store, profile, avgPrice))),
                    const SizedBox(width: 10),
                    Expanded(child: _SmallValue(label: 'Avg. Efficiency', value: avgEfficiency == null ? '—' : efficiencyText(store, avgEfficiency))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: MetricCard(
                  label: 'Last Fill-up',
                  value: latest == null ? 'No data' : DateFormat('dd MMM').format(latest.date),
                  icon: Icons.local_gas_station_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Distance since previous',
                  value: latestDistance == null ? '—' : distanceText(store, latestDistance),
                  icon: Icons.route_rounded,
                ),
              ),
            ],
          ),
          if (store.cachedCheapest != null) ...<Widget>[
            const SizedBox(height: 18),
            Row(
              children: <Widget>[
                const Expanded(child: Text('Cheapest Nearby', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
                TextButton(onPressed: onOpenFuelPrices, child: const Text('View prices')),
              ],
            ),
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onOpenFuelPrices,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kNeviroCard,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kNeviroGreen.withValues(alpha: 0.35)),
                ),
                child: Row(
                  children: <Widget>[
                    const CircleAvatar(backgroundColor: Color(0xFF124838), child: Icon(Icons.local_gas_station_rounded, color: kNeviroGreen)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(store.cachedCheapest!.station, style: const TextStyle(fontWeight: FontWeight.w800)),
                          Text(store.cachedCheapestArea ?? store.cachedCheapest!.suburb, style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('${store.cachedCheapest!.priceCentsPerLitre.toStringAsFixed(1)} c/L', style: const TextStyle(color: kNeviroGreen, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: <Widget>[
              const Expanded(child: Text('Recent Fill-ups', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              FilledButton.icon(
                onPressed: onAddFuel,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Fuel'),
                style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: kNeviroDark),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (store.entries.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
              child: const Text('No fuel entries yet. Add your first fill-up to start tracking.', style: TextStyle(color: kNeviroMuted)),
            )
          else
            ...store.entries.take(3).map((FuelEntry entry) => _RecentTile(entry: entry, store: store, profile: profile)),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 18) return 'Good Afternoon 👋';
    return 'Good Evening 👋';
  }
}

class _SmallValue extends StatelessWidget {
  final String label;
  final String value;

  const _SmallValue({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          const SizedBox(height: 3),
          Text(label, maxLines: 2, style: const TextStyle(color: kNeviroMuted, fontSize: 10.5)),
        ],
      ),
    );
  }
}

class _RecentTile extends StatelessWidget {
  final FuelEntry entry;
  final LocalStore store;
  final RegionProfile profile;

  const _RecentTile({required this.entry, required this.store, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: <Widget>[
          const CircleAvatar(backgroundColor: Color(0xFF124838), child: Icon(Icons.local_gas_station, color: kNeviroGreen, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(entry.station.isEmpty ? entry.fuelType : entry.station, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('${DateFormat('dd MMM yyyy').format(entry.date)} • ${entry.litres.toStringAsFixed(1)} L', style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
              ],
            ),
          ),
          Text(money(store, profile, entry.total), style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
