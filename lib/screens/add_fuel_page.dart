import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/fuel_entry.dart';
import '../models/region_profile.dart';
import '../models/station_price.dart';
import '../services/local_store.dart';
import '../services/receipt_scan_service.dart';

class AddFuelPage extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;
  final FuelEntry? existing;
  final StationPrice? suggestedStation;

  const AddFuelPage({
    super.key,
    required this.store,
    required this.profile,
    this.existing,
    this.suggestedStation,
  });

  @override
  State<AddFuelPage> createState() => _AddFuelPageState();
}

class _AddFuelPageState extends State<AddFuelPage> {
  late DateTime date;
  late String fuelType;
  late TextEditingController stationController;
  late TextEditingController priceController;
  late TextEditingController litresController;
  late TextEditingController odometerController;
  late TextEditingController notesController;

  double total = 0.0;
  bool scanningReceipt = false;
  bool receiptScanned = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final stationSuggestion = widget.suggestedStation;
    date = existing?.date ?? DateTime.now();
    fuelType = existing?.fuelType ?? _matchedFuelType(stationSuggestion?.fuelType) ?? widget.profile.fuelTypes.first;
    stationController = TextEditingController(text: existing?.station ?? stationSuggestion?.station ?? '');
    priceController = TextEditingController(
      text: existing != null
          ? existing.pricePerLitre.toStringAsFixed(3)
          : (stationSuggestion != null ? stationSuggestion.pricePerLitre.toStringAsFixed(3) : ''),
    );
    litresController = TextEditingController(text: existing == null ? '' : existing.litres.toStringAsFixed(2));
    odometerController = TextEditingController(text: existing?.odometer?.toStringAsFixed(0) ?? '');
    notesController = TextEditingController(text: existing?.notes ?? '');
    priceController.addListener(_recalculate);
    litresController.addListener(_recalculate);
    _recalculate();
  }

  String? _matchedFuelType(String? suggested) {
    if (suggested == null) return null;
    if (widget.profile.fuelTypes.contains(suggested)) return suggested;

    final normalized = suggested.toLowerCase();
    for (final item in widget.profile.fuelTypes) {
      if (item.toLowerCase() == normalized) return item;
    }
    if (normalized.contains('91')) {
      return widget.profile.fuelTypes.cast<String?>().firstWhere(
            (item) => item?.contains('91') ?? false,
            orElse: () => null,
          );
    }
    if (normalized.contains('95')) {
      return widget.profile.fuelTypes.cast<String?>().firstWhere(
            (item) => item?.contains('95') ?? false,
            orElse: () => null,
          );
    }
    if (normalized.contains('98')) {
      return widget.profile.fuelTypes.cast<String?>().firstWhere(
            (item) => item?.contains('98') ?? false,
            orElse: () => null,
          );
    }
    if (normalized.contains('diesel')) {
      return widget.profile.fuelTypes.cast<String?>().firstWhere(
            (item) => item?.toLowerCase().contains('diesel') ?? false,
            orElse: () => null,
          );
    }
    return null;
  }

  @override
  void dispose() {
    priceController.removeListener(_recalculate);
    litresController.removeListener(_recalculate);
    stationController.dispose();
    priceController.dispose();
    litresController.dispose();
    odometerController.dispose();
    notesController.dispose();
    super.dispose();
  }

  void _recalculate() {
    final price = double.tryParse(priceController.text.trim()) ?? 0.0;
    final litres = double.tryParse(litresController.text.trim()) ?? 0.0;
    final next = price * litres;
    if (mounted && next != total) setState(() => total = next);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _chooseReceiptSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('Scan fuel receipt', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: kNeviroGreen),
                title: const Text('Take a photo'),
                subtitle: const Text('Use the camera to scan the receipt'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: kNeviroGreen),
                title: const Text('Choose from gallery'),
                subtitle: const Text('Upload a receipt photo already on your phone'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
    if (source != null) await _scanReceipt(source);
  }

  Future<void> _scanReceipt(ImageSource source) async {
    setState(() => scanningReceipt = true);
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 88,
        maxWidth: 2200,
      );
      if (file == null) return;

      final scan = await ReceiptScanService.scan(file.path);
      if (!mounted) return;

      final matched = _matchedFuelType(scan.fuelType);
      setState(() {
        if (scan.date != null) date = scan.date!;
        if ((scan.station ?? '').trim().isNotEmpty) stationController.text = scan.station!.trim();
        if (matched != null) fuelType = matched;
        if (scan.pricePerLitre != null) priceController.text = scan.pricePerLitre!.toStringAsFixed(3);
        if (scan.litres != null) litresController.text = scan.litres!.toStringAsFixed(2);
        receiptScanned = true;
      });
      _recalculate();

      final found = <String>[];
      if (scan.date != null) found.add('date');
      if (scan.station != null) found.add('station');
      if (scan.pricePerLitre != null) found.add('price');
      if (scan.litres != null) found.add('litres');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(found.isEmpty
              ? 'Receipt read, but no fuel details were detected. Please enter them manually.'
              : 'Receipt scanned. Please check the detected details before saving.'),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Receipt could not be read. Try a clearer photo or enter the details manually.')),
        );
      }
    } finally {
      if (mounted) setState(() => scanningReceipt = false);
    }
  }

  Future<void> _save() async {
    final price = double.tryParse(priceController.text.trim());
    final litres = double.tryParse(litresController.text.trim());
    final odometer = odometerController.text.trim().isEmpty ? null : double.tryParse(odometerController.text.trim());

    if (price == null || price <= 0 || litres == null || litres <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid price per litre and litres.')));
      return;
    }
    if (odometerController.text.trim().isNotEmpty && odometer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Odometer reading must be a number.')));
      return;
    }

    if (odometer != null) {
      final previous = widget.store.entries
          .where((FuelEntry e) => e.id != widget.existing?.id && e.date.isBefore(date) && e.odometer != null)
          .toList()
        ..sort((FuelEntry a, FuelEntry b) => b.date.compareTo(a.date));
      if (previous.isNotEmpty) {
        final newKm = (widget.existing?.odometerUnit ?? widget.store.distanceUnit) == 'mi' ? odometer * 1.609344 : odometer;
        final prevKm = previous.first.odometerUnit == 'mi' ? previous.first.odometer! * 1.609344 : previous.first.odometer!;
        if (newKm < prevKm) {
          final proceed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Check odometer'),
              content: Text('This reading is lower than the previous reading (${previous.first.odometer!.toStringAsFixed(0)}). Save anyway?'),
              actions: <Widget>[
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Save anyway')),
              ],
            ),
          );
          if (proceed != true) return;
        }
      }
    }

    final entry = FuelEntry(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      date: date,
      fuelType: fuelType,
      pricePerLitre: price,
      litres: litres,
      station: stationController.text.trim(),
      notes: notesController.text.trim(),
      odometer: odometer,
      odometerUnit: widget.existing?.odometerUnit ?? widget.store.distanceUnit,
    );

    if (widget.existing == null) {
      await widget.store.addEntry(entry);
    } else {
      await widget.store.updateEntry(entry);
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final code = effectiveCurrencyCode(widget.store, widget.profile);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Fuel' : 'Edit Fuel Entry'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
        children: <Widget>[
          const Text('Fill-up details', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          const Text('Scan a receipt or enter the details yourself.', style: TextStyle(color: kNeviroMuted)),
          if (widget.existing == null) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: scanningReceipt ? null : _chooseReceiptSource,
              icon: scanningReceipt
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.document_scanner_rounded),
              label: Text(scanningReceipt ? 'Reading receipt...' : 'Scan / Upload Receipt'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                foregroundColor: kNeviroGreenDark,
                side: const BorderSide(color: kNeviroGreen),
              ),
            ),
            if (receiptScanned) ...<Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kNeviroCard2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kNeviroGreen.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: <Widget>[
                    Icon(Icons.check_circle_rounded, color: kNeviroGreen),
                    SizedBox(width: 9),
                    Expanded(child: Text('Receipt data added. Check the values below before saving.')),
                  ],
                ),
              ),
            ],
          ],
          const SizedBox(height: 20),
          _FieldLabel('Date'),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _pickDate,
            child: InputDecorator(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_rounded)),
              child: Text(DateFormat('dd MMM yyyy').format(date)),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Fuel Type'),
          DropdownButtonFormField<String>(
            key: ValueKey<String>(fuelType),
            initialValue: fuelType,
            items: widget.profile.fuelTypes.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
            onChanged: (value) => setState(() => fuelType = value ?? fuelType),
            decoration: const InputDecoration(prefixIcon: Icon(Icons.local_gas_station_rounded)),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Station (Optional)'),
          TextField(
            controller: stationController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.place_rounded), hintText: 'e.g. Vibe Beechboro'),
          ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _FieldLabel('Price per litre ($code)'),
                    TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.attach_money_rounded), hintText: '1.899'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _FieldLabel('Litres'),
                    TextField(
                      controller: litresController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(prefixIcon: Icon(Icons.water_drop_rounded), hintText: '42.5'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kNeviroCard2,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kNeviroGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Total Amount', style: TextStyle(color: kNeviroMuted))),
                Text(money(widget.store, widget.profile, total), style: const TextStyle(color: kNeviroGreenDark, fontSize: 24, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Odometer Reading (Optional)'),
          TextField(
            controller: odometerController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.speed_rounded),
              suffixText: widget.existing?.odometerUnit ?? widget.store.distanceUnit,
              hintText: '85420',
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Notes (Optional)'),
          TextField(
            controller: notesController,
            maxLines: 3,
            decoration: const InputDecoration(prefixIcon: Icon(Icons.notes_rounded), hintText: 'Work trip, long drive...'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
              label: Text(widget.existing == null ? 'Save Fill-up' : 'Save Changes'),
              style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: Colors.white, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 7),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: kNeviroDark)),
    );
  }
}
