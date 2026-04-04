import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class MetricsPanel extends StatelessWidget {
  const MetricsPanel({super.key});

  Color _velocityColor(double fps) {
    if (fps <= 0) return const Color(0xFF6B7280);
    if (fps < 15) return const Color(0xFF16A34A);
    if (fps < 20) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Color _suitabilityColor(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('excellent')) return const Color(0xFF16A34A);
    if (lower.contains('good')) return const Color(0xFF2563EB);
    if (lower.contains('marginal')) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }

  Widget _volRow(BuildContext context, String label, String value, {bool bold = false}) {
    final ts = Theme.of(context).textTheme.bodySmall;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: ts),
          Text(value,
              style: ts?.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
                color: bold ? Theme.of(context).colorScheme.primary : null,
              )),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final result = controller.result;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        ...result.metrics
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
            ),
        if (result.portVelocityFps > 0)
          SizedBox(
            width: 190,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Port Velocity', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Text(
                      '${result.portVelocityFps.toStringAsFixed(1)} fps',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: _velocityColor(result.portVelocityFps),
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.portVelocityFps < 15
                          ? 'Acceptable'
                          : result.portVelocityFps < 20
                              ? 'Borderline — chuffing risk'
                              : 'Too high — chuffing likely',
                      style: TextStyle(
                        fontSize: 12,
                        color: _velocityColor(result.portVelocityFps),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (result.bandpassSuitability.isNotEmpty)
          SizedBox(
            width: 190,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Bandpass Suitability', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _suitabilityColor(result.bandpassSuitability).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _suitabilityColor(result.bandpassSuitability)),
                      ),
                      child: Text(
                        result.bandpassSuitability,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _suitabilityColor(result.bandpassSuitability),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (result.grossVolume > 0)
          SizedBox(
            width: 190,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Volume Summary', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    _volRow(context, 'Gross', '${result.grossVolume.toStringAsFixed(3)} cf'),
                    _volRow(context, 'Sub disp.', '−${result.totalSubDisplacement.toStringAsFixed(3)} cf'),
                    if (result.portDisplacement > 0)
                      _volRow(context, 'Port disp.', '−${result.portDisplacement.toStringAsFixed(3)} cf'),
                    if (result.effectiveBraceDisplacement > 0)
                      _volRow(context, 'Braces', '−${result.effectiveBraceDisplacement.toStringAsFixed(3)} cf'),
                    const Divider(height: 10, thickness: 0.5),
                    _volRow(context, 'Net', '${(result.grossVolume - result.totalDisplacement).toStringAsFixed(3)} cf', bold: true),
                  ],
                ),
              ),
            ),
          ),
      ]
          .toList(),
    );
  }
}