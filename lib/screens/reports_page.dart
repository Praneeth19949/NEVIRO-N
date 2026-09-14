import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app.dart';
import '../models/fuel_entry.dart';
import '../models/region_profile.dart';
import '../services/export_service.dart';
import '../services/fuel_math.dart';
import '../services/local_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/metric_card.dart';
import '../widgets/neviro_brand.dart';

class ReportsPage extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;

  const ReportsPage({super.key, required this.store, required this.profile});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String period = 'Monthly';
  bool exporting = false;

  List<FuelEntry> get filtered {
    final now = DateTime.now();
    DateTime start;
    if (period == 'Weekly') {
      start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
    } else if (period == 'Yearly') {
      start = DateTime(now.year, 1, 1);
    } else {
      start = DateTime(now.year, now.month, 1);
    }
    return widget.store.entries.where((FuelEntry e) => !e.date.isBefore(start)).toList();
  }

  Future<void> _export() async {
    setState(() => exporting = true);
    try {
      await ExportService.shareExcel(
        entries: widget.store.entries,
        currencyCode: effectiveCurrencyCode(widget.store, widget.profile),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel export could not be created.')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entries = filtered;
    final spend = FuelMath.totalSpend(entries);
    final litres = FuelMath.totalLitres(entries);
    final avgPrice = FuelMath.averagePricePerLitre(entries);
    final distance = FuelMath.totalMeasuredDistance(entries);
    final efficiency = FuelMath.averageEfficiencyLPer100Km(entries);

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      children: <Widget>[
        const NeviroBrand(compact: true),
        const SizedBox(height: 18),
        const Text('Reports', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 4),
        const Text('See your fuel trends, costs and efficiency.', style: TextStyle(color: kNeviroMuted)),
        const SizedBox(height: 18),
        SegmentedButton<String>(
          segments: const <ButtonSegment<String>>[
            ButtonSegment<String>(value: 'Weekly', label: Text('Weekly')),
            ButtonSegment<String>(value: 'Monthly', label: Text('Monthly')),
            ButtonSegment<String>(value: 'Yearly', label: Text('Yearly')),
          ],
          selected: <String>{period},
          showSelectedIcon: false,
          onSelectionChanged: (Set<String> selected) => setState(() => period = selected.first),
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? kNeviroGreen : kNeviroCard),
            foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) => states.contains(WidgetState.selected) ? kNeviroDark : Colors.white),
          ),
        ),
        const SizedBox(height: 18),
        if (entries.isEmpty)
          EmptyState(
            icon: Icons.bar_chart_rounded,
            title: 'No report data yet',
            message: 'Add fuel entries and NEVIRO will build your spending and efficiency reports automatically.',
            action: OutlinedButton.icon(onPressed: _export, icon: const Icon(Icons.file_download_outlined), label: const Text('Export all data')),
          )
        else ...<Widget>[
          Row(
            children: <Widget>[
              Expanded(child: MetricCard(label: 'Total Spend', value: money(widget.store, widget.profile, spend), icon: Icons.payments_rounded, emphasize: true)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Total Litres', value: '${litres.toStringAsFixed(1)} L', icon: Icons.water_drop_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(child: MetricCard(label: 'Avg. Price/L', value: money(widget.store, widget.profile, avgPrice), icon: Icons.price_check_rounded)),
              const SizedBox(width: 12),
              Expanded(child: MetricCard(label: 'Distance', value: distance <= 0 ? '—' : distanceText(widget.store, distance), icon: Icons.route_rounded)),
            ],
          ),
          const SizedBox(height: 12),
          MetricCard(
            label: 'Average Fuel Efficiency',
            value: efficiency == null ? 'Add odometer readings to calculate' : efficiencyText(widget.store, efficiency),
            icon: Icons.eco_rounded,
            emphasize: efficiency != null,
          ),
          const SizedBox(height: 20),
          const Text('Spending Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _SpendingChart(entries: entries, period: period, moneyLabel: (double v) => money(widget.store, widget.profile, v)),
          const SizedBox(height: 20),
          const Text('Efficiency Trend', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _EfficiencyTrend(entries: entries, store: widget.store),
          const SizedBox(height: 20),
          const Text('Fuel Type Breakdown', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _FuelTypeBreakdown(entries: entries, store: widget.store, profile: widget.profile),
          const SizedBox(height: 22),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: exporting ? null : _export,
              style: FilledButton.styleFrom(backgroundColor: kNeviroGreen, foregroundColor: kNeviroDark),
              icon: exporting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download_rounded),
              label: Text(exporting ? 'Preparing Excel...' : 'Export to Excel'),
            ),
          ),
        ],
      ],
    );
  }
}

class _SpendingChart extends StatelessWidget {
  final List<FuelEntry> entries;
  final String period;
  final String Function(double) moneyLabel;

  const _SpendingChart({required this.entries, required this.period, required this.moneyLabel});

  @override
  Widget build(BuildContext context) {
    final buckets = _buckets(entries, period);
    final maxValue = buckets.fold<double>(0.0, (double m, _Bucket b) => math.max(m, b.value).toDouble());
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
      decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 180,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: buckets.map((bucket) {
                final ratio = maxValue <= 0 ? 0.0 : bucket.value / maxValue;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: ratio.clamp(0.03, 1.0).toDouble(),
                              widthFactor: 0.72,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: kNeviroGreen.withValues(alpha: 0.85),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(bucket.label, style: const TextStyle(color: kNeviroMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Text('Total: ${moneyLabel(FuelMath.totalSpend(entries))}', style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  static List<_Bucket> _buckets(List<FuelEntry> entries, String period) {
    final now = DateTime.now();
    if (period == 'Weekly') {
      return List<_Bucket>.generate(7, (int i) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
        final value = entries
            .where((FuelEntry e) => e.date.year == day.year && e.date.month == day.month && e.date.day == day.day)
            .fold<double>(0.0, (double s, FuelEntry e) => s + e.total);
        return _Bucket(DateFormat('E').format(day).substring(0, 1), value);
      });
    }
    if (period == 'Yearly') {
      return List<_Bucket>.generate(12, (int i) {
        final month = i + 1;
        final value = entries.where((FuelEntry e) => e.date.month == month).fold<double>(0.0, (double s, FuelEntry e) => s + e.total);
        return _Bucket(DateFormat('MMM').format(DateTime(now.year, month)).substring(0, 1), value);
      });
    }
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    final spans = <List<int>>[[1, 7], [8, 14], [15, 21], [22, lastDay]];
    return spans.asMap().entries.map((entry) {
      final start = entry.value[0];
      final end = entry.value[1];
      final value = entries.where((FuelEntry e) => e.date.day >= start && e.date.day <= end).fold<double>(0.0, (double s, FuelEntry e) => s + e.total);
      return _Bucket('W${entry.key + 1}', value);
    }).toList();
  }
}

class _Bucket {
  final String label;
  final double value;
  const _Bucket(this.label, this.value);
}

class _EfficiencyTrend extends StatelessWidget {
  final List<FuelEntry> entries;
  final LocalStore store;
  const _EfficiencyTrend({required this.entries, required this.store});

  @override
  Widget build(BuildContext context) {
    final measured = entries
        .map((FuelEntry e) => MapEntry<FuelEntry, double?>(e, FuelMath.efficiencyLPer100Km(e, entries)))
        .where((entry) => entry.value != null)
        .take(5)
        .toList();
    if (measured.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
        child: const Text('Add odometer readings on consecutive fill-ups to see efficiency trends.', style: TextStyle(color: kNeviroMuted)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: measured.map((entry) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              children: <Widget>[
                Expanded(child: Text(DateFormat('dd MMM').format(entry.key.date), style: const TextStyle(color: kNeviroMuted))),
                Text(efficiencyText(store, entry.value!), style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FuelTypeBreakdown extends StatelessWidget {
  final List<FuelEntry> entries;
  final LocalStore store;
  final RegionProfile profile;

  const _FuelTypeBreakdown({required this.entries, required this.store, required this.profile});

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final entry in entries) {
      totals[entry.fuelType] = (totals[entry.fuelType] ?? 0.0) + entry.total;
    }
    final sorted = totals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
      child: Column(
        children: sorted.map((entry) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: <Widget>[
              const Icon(Icons.local_gas_station_rounded, color: kNeviroGreen, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(entry.key)),
              Text(money(store, profile, entry.value), style: const TextStyle(fontWeight: FontWeight.w800)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}
