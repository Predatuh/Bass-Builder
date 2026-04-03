import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enums.dart';
import '../state/bass_builder_controller.dart';

class CutListCard extends StatelessWidget {
  const CutListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final result = controller.result;
    final config = controller.config;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelBg = isDark ? cs.surfaceContainerHighest : const Color(0xFFFBF7F1);
    final panelBorder = isDark ? cs.outlineVariant : const Color(0xFFE7D9C4);
    final nameColor = cs.primary;
    final detailColor = cs.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cut List', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              ...result.cutPanels.map(
                (panel) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: panelBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(panel.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(color: nameColor)),
                      ),
                      Text('Qty ${panel.quantity}',
                          style: TextStyle(color: detailColor, fontWeight: FontWeight.w500)),
                      const SizedBox(width: 20),
                      Text('${panel.width.toStringAsFixed(2)} x ${panel.height.toStringAsFixed(2)} in',
                          style: TextStyle(color: detailColor)),
                    ],
                  ),
                ),
              ),

              // Port length section
              if (config.isPorted) ...[
                const SizedBox(height: 16),
                Text('Port Calculations', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: panelBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow(context, 'Port Type', config.portType.label, detailColor),
                      _infoRow(context, 'Port Length', '${result.portLength.toStringAsFixed(2)}"', cs.primary),
                      _infoRow(context, 'Port Area', '${result.portArea.toStringAsFixed(1)} in²', detailColor),
                      if (config.portType == PortType.round)
                        _infoRow(context, 'Port Diameter', '${config.roundPortDiameter.toStringAsFixed(2)}" x ${config.numberOfPorts} port(s)', detailColor),
                      if (config.portType == PortType.slot) ...[
                        _infoRow(context, 'Slot Width', '${config.slotPortWidth.toStringAsFixed(2)}"', detailColor),
                        _infoRow(context, 'Slot Height', '${config.slotPortHeight.toStringAsFixed(2)}"', detailColor),
                      ],
                      if (result.slotNeedsBend) ...[
                        const SizedBox(height: 4),
                        Text('⚠ Port needs bend', style: TextStyle(color: cs.error, fontWeight: FontWeight.w600, fontSize: 13)),
                        _infoRow(context, 'Leg 1', '${result.slotLeg1Length.toStringAsFixed(2)}"', detailColor),
                        _infoRow(context, 'Leg 2', '${result.slotLeg2Length.toStringAsFixed(2)}"', detailColor),
                      ],
                      _infoRow(context, 'Port Velocity', '${result.portVelocityFps.toStringAsFixed(1)} fps',
                          result.portVelocityFps > 38 ? cs.error : result.portVelocityFps > 22 ? Colors.orange : cs.primary),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),
              Text('Displacement Breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: panelBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: panelBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow(context, 'Target Net Volume', '${config.targetNetVolume.toStringAsFixed(2)} cf', cs.primary),
                    _infoRow(context, 'Sub Displacement', '${result.totalSubDisplacement.toStringAsFixed(3)} cf', detailColor),
                    if (config.isPorted)
                      _infoRow(context, 'Port Displacement', '${result.portDisplacement.toStringAsFixed(3)} cf', detailColor),
                    _infoRow(context, 'Brace Displacement', '${result.effectiveBraceDisplacement.toStringAsFixed(3)} cf', detailColor),
                    if (result.dividerDisplacement > 0)
                      _infoRow(context, 'Divider Displacement', '${result.dividerDisplacement.toStringAsFixed(3)} cf', detailColor),
                    _infoRow(context, 'Baffle Hole Gain', '-${result.baffleGain.toStringAsFixed(3)} cf', Colors.green),
                    const Divider(),
                    _infoRow(context, 'Gross Volume', '${result.grossVolume.toStringAsFixed(3)} cf', cs.primary),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              Text('Material Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (result.sheetsNeeded > 0 || result.totalPanelAreaSqFt > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: panelBg,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: panelBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Sheets (4×8)', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: detailColor)),
                          const SizedBox(height: 4),
                          Text(
                            '${result.sheetsNeeded}',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Total Area', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: detailColor)),
                          const SizedBox(height: 4),
                          Text(
                            '${result.totalPanelAreaSqFt.toStringAsFixed(1)} sq ft',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: cs.primary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Text('Material Breakdown', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...result.materialBreakdown.entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('${entry.key}: \$${entry.value.toStringAsFixed(2)}',
                      style: TextStyle(color: detailColor)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Net volume: ${config.targetNetVolume.toStringAsFixed(2)} cf', style: TextStyle(color: detailColor)),
              Text('Gross volume: ${result.grossVolume.toStringAsFixed(3)} cf', style: TextStyle(color: detailColor)),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _infoRow(BuildContext context, String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: TextStyle(color: valueColor, fontWeight: FontWeight.w700, fontSize: 14)),
        ],
      ),
    );
  }
}