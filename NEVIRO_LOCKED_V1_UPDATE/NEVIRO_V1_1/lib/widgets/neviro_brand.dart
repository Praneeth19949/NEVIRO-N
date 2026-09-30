import 'package:flutter/material.dart';

import '../app.dart';

class NeviroBrand extends StatelessWidget {
  final bool compact;

  const NeviroBrand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: compact ? 34 : 42,
          height: compact ? 34 : 42,
          decoration: BoxDecoration(
            color: kNeviroGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.eco_rounded, color: kNeviroGreen),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              'NEVIRO',
              style: TextStyle(
                fontSize: compact ? 20 : 25,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            if (!compact)
              const Text(
                'Drive Smarter. Live Greener.',
                style: TextStyle(color: kNeviroMuted, fontSize: 11.5),
              ),
          ],
        ),
      ],
    );
  }
}
