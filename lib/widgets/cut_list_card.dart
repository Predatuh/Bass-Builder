import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class CutListCard extends StatelessWidget {
  const CutListCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final result = controller.result;
    final config = controller.config;

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
                    color: const Color(0xFFFBF7F1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7D9C4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(panel.name, style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Text('Qty ${panel.quantity}'),
                      const SizedBox(width: 20),
                      Text('${panel.width.toStringAsFixed(2)} x ${panel.height.toStringAsFixed(2)} in'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Material Summary', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (result.sheetsNeeded > 0 || result.totalPanelAreaSqFt > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F1),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7D9C4)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('Sheets (4×8)', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${result.sheetsNeeded}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text('Total Area', style: Theme.of(context).textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Text(
                            '${result.totalPanelAreaSqFt.toStringAsFixed(1)} sq ft',
                            style: Theme.of(context).textTheme.titleLarge,
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
                  child: Text('${entry.key}: \$${entry.value.toStringAsFixed(2)}'),
                ),
              ),
              const SizedBox(height: 12),
              Text('Notes', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Net volume: ${config.targetNetVolume.toStringAsFixed(2)} cf'),
              Text('Gross volume: ${result.grossVolume.toStringAsFixed(3)} cf'),
              if (config.isPorted) Text('Port length: ${result.portLength.toStringAsFixed(2)} in'),
              if (result.slotNeedsBend) Text('Slot bend: leg1 ${result.slotLeg1Length.toStringAsFixed(2)} in, leg2 ${result.slotLeg2Length.toStringAsFixed(2)} in'),
            ],
          ),
        ),
      ],
    );
  }
}