import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class ExportCard extends StatelessWidget {
  const ExportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    return ListView(
      children: [
        Text('Export', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Export the current design as a JSON file, PDF cut sheet, blueprint image, or SVG front panel.'),
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _ExportButton(label: 'Export JSON', onPressed: () => _runExport(context, controller.exportDesignJson)),
            _ExportButton(label: 'Export Cut Sheet PDF', onPressed: () => _runExport(context, controller.exportCutSheetPdf)),
            _ExportButton(label: 'Export Blueprint PNG', onPressed: () => _runExport(context, controller.exportBlueprintPng)),
            _ExportButton(label: 'Export Front Panel SVG', onPressed: () => _runExport(context, controller.exportFrontPanelSvg)),
          ],
        ),
        const SizedBox(height: 24),
        Text('Current Share Query', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SelectableText('?${controller.result.shareQuery}'),
      ],
    );
  }

  static Future<void> _runExport(BuildContext context, Future<String> Function() operation) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final location = await operation();
      messenger.showSnackBar(SnackBar(content: Text('Exported to $location')));
    } catch (error) {
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onPressed,
      child: Text(label),
    );
  }
}