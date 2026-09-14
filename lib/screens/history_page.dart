import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/fuel_entry.dart';
import '../models/region_profile.dart';
import '../services/fuel_math.dart';
import '../services/local_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/neviro_brand.dart';
import 'add_fuel_page.dart';

class HistoryPage extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;

  const HistoryPage({super.key, required this.store, required this.profile});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final searchController = TextEditingController();
  String fuelFilter = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<FuelEntry> get filtered {
    final q = searchController.text.trim().toLowerCase();
    return widget.store.entries.where((FuelEntry e) {
      final matchesFilter = fuelFilter == 'All' || e.fuelType == fuelFilter;
      final matchesSearch = q.isEmpty ||
          e.station.toLowerCase().contains(q) ||
          e.fuelType.toLowerCase().contains(q) ||
          e.notes.toLowerCase().contains(q);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  Future<void> _edit(FuelEntry entry) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFuelPage(store: widget.store, profile: widget.profile, existing: entry),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _delete(FuelEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete fill-up?'),
        content: const Text('This entry will be removed from your local history.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed == true) await widget.store.deleteEntry(entry.id);
  }

  @override
  Widget build(BuildContext context) {
    final entries = filtered;
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: <Widget>[
        const NeviroBrand(compact: true),
        const SizedBox(height: 18),
        const Text('History', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('All your fuel fill-ups in one place.', style: TextStyle(color: kNeviroMuted)),
        const SizedBox(height: 16),
        TextField(
          controller: searchController,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search_rounded), hintText: 'Search station, fuel type or note'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: fuelFilter,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.filter_alt_rounded)),
          items: <String>['All', ...widget.profile.fuelTypes].map((String f) => DropdownMenuItem<String>(value: f, child: Text(f))).toList(),
          onChanged: (value) => setState(() => fuelFilter = value ?? 'All'),
        ),
        const SizedBox(height: 16),
        if (widget.store.entries.isEmpty)
          const EmptyState(
            icon: Icons.history_rounded,
            title: 'No fill-ups yet',
            message: 'Your saved fuel entries will appear here. There is no demo data in NEVIRO.',
          )
        else if (entries.isEmpty)
          const EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching entries',
            message: 'Try a different search or fuel-type filter.',
          )
        else
          ...entries.map((FuelEntry entry) => _HistoryCard(
                entry: entry,
                allEntries: widget.store.entries,
                store: widget.store,
                profile: widget.profile,
                onTap: () => _showDetails(entry),
                onEdit: () => _edit(entry),
                onDelete: () => _delete(entry),
              )),
      ],
    );
  }

  Future<void> _showDetails(FuelEntry entry) async {
    final efficiency = FuelMath.efficiencyLPer100Km(entry, widget.store.entries);
    final distance = FuelMath.distanceForEntry(entry, widget.store.entries);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: kNeviroCard,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(entry.station.isEmpty ? entry.fuelType : entry.station, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 4),
            Text(DateFormat('dd MMM yyyy').format(entry.date), style: const TextStyle(color: kNeviroMuted)),
            const SizedBox(height: 18),
            _DetailRow('Fuel type', entry.fuelType),
            _DetailRow('Litres', '${entry.litres.toStringAsFixed(2)} L'),
            _DetailRow('Price / L', money(widget.store, widget.profile, entry.pricePerLitre)),
            _DetailRow('Total', money(widget.store, widget.profile, entry.total)),
            if (entry.odometer != null) _DetailRow('Odometer', '${entry.odometer!.toStringAsFixed(0)} ${entry.odometerUnit}'),
            if (distance != null) _DetailRow('Distance since previous', distanceText(widget.store, distance)),
            if (efficiency != null) _DetailRow('Efficiency', efficiencyText(widget.store, efficiency)),
            if (entry.notes.isNotEmpty) _DetailRow('Notes', entry.notes),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final FuelEntry entry;
  final List<FuelEntry> allEntries;
  final LocalStore store;
  final RegionProfile profile;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _HistoryCard({
    required this.entry,
    required this.allEntries,
    required this.store,
    required this.profile,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final efficiency = FuelMath.efficiencyLPer100Km(entry, allEntries);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: <Widget>[
            const CircleAvatar(backgroundColor: kNeviroCard2, child: Icon(Icons.local_gas_station_rounded, color: kNeviroGreenDark)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(entry.station.isEmpty ? entry.fuelType : entry.station, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('${DateFormat('dd MMM yyyy').format(entry.date)} • ${entry.litres.toStringAsFixed(1)} L • ${entry.fuelType}', style: const TextStyle(color: kNeviroMuted, fontSize: 11.5)),
                  if (efficiency != null) Text(efficiencyText(store, efficiency), style: const TextStyle(color: kNeviroGreen, fontSize: 11.5)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(money(store, profile, entry.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.more_horiz_rounded, color: kNeviroMuted),
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(value: 'edit', child: Text('Edit')),
                    PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(width: 150, child: Text(label, style: const TextStyle(color: kNeviroMuted))),
          Expanded(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}
