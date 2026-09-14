import 'package:flutter/material.dart';

import '../app.dart';
import '../models/region_profile.dart';
import '../services/export_service.dart';
import '../services/local_store.dart';
import '../services/region_service.dart';

class SettingsPage extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;

  const SettingsPage({super.key, required this.store, required this.profile});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool exporting = false;

  Future<void> _export() async {
    setState(() => exporting = true);
    try {
      final profile = RegionService.profileFor(overrideCode: widget.store.regionOverride);
      await ExportService.shareExcel(
        entries: widget.store.entries,
        currencyCode: effectiveCurrencyCode(widget.store, profile),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Excel export could not be created.')));
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> _clearData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all local data?'),
        content: const Text('This removes all saved fuel entries from this device. Export first if you want a backup.'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear data')),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.store.clearAllData();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local fuel history cleared.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentProfile = RegionService.profileFor(overrideCode: widget.store.regionOverride);
    final currency = widget.store.currencyOverride ?? currentProfile.currencyCode;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
        children: <Widget>[
          const Text('Region & Units', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _SettingsCard(
            children: <Widget>[
              _SettingDropdown(
                icon: Icons.public_rounded,
                title: 'Region',
                subtitle: widget.store.regionOverride == 'AUTO' ? 'Automatic (${currentProfile.name})' : currentProfile.name,
                value: widget.store.regionOverride,
                items: const <MapEntry<String, String>>[
                  MapEntry<String, String>('AUTO', 'Automatic'),
                  MapEntry<String, String>('AU', 'Australia'),
                  MapEntry<String, String>('LK', 'Sri Lanka'),
                  MapEntry<String, String>('US', 'United States'),
                  MapEntry<String, String>('GB', 'United Kingdom'),
                  MapEntry<String, String>('NZ', 'New Zealand'),
                  MapEntry<String, String>('CA', 'Canada'),
                ],
                onChanged: (value) async {
                  if (value != null) await widget.store.setRegionOverride(value);
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1, color: Color(0xFF17463B)),
              _SettingDropdown(
                icon: Icons.attach_money_rounded,
                title: 'Currency',
                subtitle: widget.store.currencyOverride == null ? 'Automatic ($currency)' : currency,
                value: widget.store.currencyOverride ?? 'AUTO',
                items: const <MapEntry<String, String>>[
                  MapEntry<String, String>('AUTO', 'Automatic'),
                  MapEntry<String, String>('AUD', 'AUD - Australian Dollar'),
                  MapEntry<String, String>('LKR', 'LKR - Sri Lankan Rupee'),
                  MapEntry<String, String>('USD', 'USD - US Dollar'),
                  MapEntry<String, String>('GBP', 'GBP - British Pound'),
                  MapEntry<String, String>('NZD', 'NZD - New Zealand Dollar'),
                  MapEntry<String, String>('CAD', 'CAD - Canadian Dollar'),
                  MapEntry<String, String>('EUR', 'EUR - Euro'),
                ],
                onChanged: (value) async {
                  await widget.store.setCurrencyOverride(value == 'AUTO' ? null : value);
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1, color: Color(0xFF17463B)),
              _SettingDropdown(
                icon: Icons.straighten_rounded,
                title: 'Distance Unit',
                subtitle: widget.store.distanceUnit == 'km' ? 'Kilometres' : 'Miles',
                value: widget.store.distanceUnit,
                items: const <MapEntry<String, String>>[
                  MapEntry<String, String>('km', 'Kilometres (km)'),
                  MapEntry<String, String>('mi', 'Miles (mi)'),
                ],
                onChanged: (value) async {
                  if (value != null) await widget.store.setDistanceUnit(value);
                  if (mounted) setState(() {});
                },
              ),
              const Divider(height: 1, color: Color(0xFF17463B)),
              _SettingDropdown(
                icon: Icons.eco_rounded,
                title: 'Fuel Efficiency Unit',
                subtitle: widget.store.efficiencyUnit,
                value: widget.store.efficiencyUnit,
                items: const <MapEntry<String, String>>[
                  MapEntry<String, String>('L/100km', 'L/100km'),
                  MapEntry<String, String>('km/L', 'km/L'),
                ],
                onChanged: (value) async {
                  if (value != null) await widget.store.setEfficiencyUnit(value);
                  if (mounted) setState(() {});
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          _SettingsCard(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.file_download_rounded, color: kNeviroGreen),
                title: const Text('Export to Excel'),
                subtitle: const Text('Create a backup/shareable spreadsheet', style: TextStyle(color: kNeviroMuted, fontSize: 12)),
                trailing: exporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.chevron_right_rounded),
                onTap: exporting ? null : _export,
              ),
              const Divider(height: 1, color: Color(0xFF17463B)),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                title: const Text('Clear All Data'),
                subtitle: const Text('Deletes local fuel history from this device', style: TextStyle(color: kNeviroMuted, fontSize: 12)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _clearData,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text('About', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          const _SettingsCard(
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.info_outline_rounded, color: kNeviroGreen),
                title: Text('NEVIRO'),
                subtitle: Text('Version 1.0.0 • Fuel tracking first', style: TextStyle(color: kNeviroMuted, fontSize: 12)),
              ),
              Divider(height: 1, color: Color(0xFF17463B)),
              ListTile(
                leading: Icon(Icons.lock_outline_rounded, color: kNeviroGreen),
                title: Text('Privacy'),
                subtitle: Text('No account. Fuel records stay on this device. Location is used only when you request nearby prices.', style: TextStyle(color: kNeviroMuted, fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: kNeviroCard, borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _SettingDropdown extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<MapEntry<String, String>> items;
  final ValueChanged<String?> onChanged;

  const _SettingDropdown({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: kNeviroGreen),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
      trailing: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items.map((item) => DropdownMenuItem<String>(value: item.key, child: Text(item.value))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
        ),
      ),
    );
  }
}
