import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class SaveLoadCard extends StatelessWidget {
  const SaveLoadCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final savedNames = controller.savedDesigns.keys.toList()..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Save / Load', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton(
                  onPressed: () => controller.saveCurrentDesign(),
                  child: const Text('Save Current Design'),
                ),
                if (savedNames.isNotEmpty)
                  DropdownButton<String>(
                    hint: const Text('Load saved design'),
                    value: null,
                    items: savedNames
                        .map((name) => DropdownMenuItem(value: name, child: Text(name)))
                        .toList(),
                    onChanged: (name) {
                      if (name != null) {
                        controller.loadDesign(name);
                      }
                    },
                  ),
              ],
            ),
            if (savedNames.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: savedNames
                    .map(
                      (name) => Chip(
                        label: Text(name),
                        onDeleted: () => controller.deleteDesign(name),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Text('Share Query', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SelectableText('?${controller.result.shareQuery}'),
          ],
        ),
      ),
    );
  }
}