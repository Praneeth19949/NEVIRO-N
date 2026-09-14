import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/fuel_entry.dart';
import '../models/region_profile.dart';
import '../models/station_price.dart';
import '../services/local_store.dart';

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
    if (suggested == 'Premium 95' && widget.profile.fuelTypes.contains('Premium 95')) return 'Premium 95';
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
          const Text('Only price and litres are required. Everything else is optional.', style: TextStyle(color: kNeviroMuted)),
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
            decoration: const InputDecoration(prefixIcon: Icon(Icons.place_rounded), hintText: 'e.g. Shell Osborne Park'),
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
              color: kNeviroGreen.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: kNeviroGreen.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: <Widget>[
                const Expanded(child: Text('Total Amount', style: TextStyle(color: kNeviroMuted))),
                Text(money(widget.store, widget.profile, total), style: const TextStyle(color: kNeviroGreen, fontSize: 24, fontWeight: FontWeight.w900)),
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
              style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: kNeviroDark, textStyle: const TextStyle(fontWeight: FontWeight.w800)),
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
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFD9E8E2))),
    );
  }
}
