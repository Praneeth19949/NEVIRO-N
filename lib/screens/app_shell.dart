import 'package:flutter/material.dart';

import '../app.dart';
import '../models/region_profile.dart';
import '../models/station_price.dart';
import '../services/local_store.dart';
import 'add_fuel_page.dart';
import 'fuel_prices_page.dart';
import 'history_page.dart';
import 'home_page.dart';
import 'reports_page.dart';

class AppShell extends StatefulWidget {
  final LocalStore store;
  final RegionProfile profile;

  const AppShell({super.key, required this.store, required this.profile});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  Future<void> openAddFuel({StationPrice? station}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddFuelPage(
          store: widget.store,
          profile: widget.profile,
          suggestedStation: station,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        store: widget.store,
        profile: widget.profile,
        onOpenFuelPrices: () => setState(() => index = 1),
        onAddFuel: () => openAddFuel(),
      ),
      FuelPricesPage(
        store: widget.store,
        profile: widget.profile,
        onUseForFillUp: (station) => openAddFuel(station: station),
      ),
      ReportsPage(store: widget.store, profile: widget.profile),
      HistoryPage(store: widget.store, profile: widget.profile),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF062821),
          border: Border(top: BorderSide(color: Color(0xFF17463B))),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(
          children: <Widget>[
            _NavItem(
              selected: index == 0,
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => setState(() => index = 0),
            ),
            _NavItem(
              selected: index == 1,
              icon: Icons.local_gas_station_rounded,
              label: 'Fuel Prices',
              onTap: () => setState(() => index = 1),
            ),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => openAddFuel(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 54,
                      height: 54,
                      decoration: const BoxDecoration(color: kNeviroGreen, shape: BoxShape.circle),
                      child: const Icon(Icons.add_rounded, color: kNeviroDark, size: 32),
                    ),
                    const SizedBox(height: 4),
                    const Text('Add Fuel', style: TextStyle(fontSize: 10.5, color: Colors.white)),
                  ],
                ),
              ),
            ),
            _NavItem(
              selected: index == 2,
              icon: Icons.bar_chart_rounded,
              label: 'Reports',
              onTap: () => setState(() => index = 2),
            ),
            _NavItem(
              selected: index == 3,
              icon: Icons.history_rounded,
              label: 'History',
              onTap: () => setState(() => index = 3),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavItem({required this.selected, required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? kNeviroGreen : kNeviroMuted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, maxLines: 1, style: TextStyle(color: color, fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }
}
