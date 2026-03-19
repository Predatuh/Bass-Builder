import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<BassBuilderController>().result;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: result.metrics
          .map(
            (metric) => SizedBox(
              width: 190,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 10),
                      Text(metric.value, style: Theme.of(context).textTheme.titleLarge),
                      if (metric.emphasis != null) ...[
                        const SizedBox(height: 8),
                        Text(metric.emphasis!, style: const TextStyle(color: Color(0xFFC26B2D))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}