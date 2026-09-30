import 'package:flutter/material.dart';

import '../app.dart';

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool emphasize;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: emphasize ? kNeviroCard2 : kNeviroCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: emphasize ? kNeviroGreen.withValues(alpha: 0.35) : kNeviroBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: emphasize ? kNeviroGreen : kNeviroMuted, size: 20),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: kNeviroMuted, fontSize: 12)),
        ],
      ),
    );
  }
}
