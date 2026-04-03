import 'dart:convert';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/enclosure_config.dart';
import '../models/enclosure_result.dart';
import '../widgets/blueprint_card.dart';
import 'file_save_service.dart';

class ExportService {
  static Future<String> exportDesignJson(EnclosureConfig config) async {
    final bytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(config.toMap()));
    return saveBytes(
      fileName: '${_safeBaseName(config.designName)}_design.json',
      bytes: bytes,
      mimeType: 'application/json',
    );
  }

  static Future<String> exportCutSheetPdf(EnclosureConfig config, EnclosureResult result) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Bass Builder Cut Sheet')),
          pw.Text('Design: ${config.designName}'),
          pw.Text('Subwoofer: ${config.subModel}'),
          pw.Text('Dimensions: ${config.width.toStringAsFixed(2)} x ${config.height.toStringAsFixed(2)} x ${result.externalDepth.toStringAsFixed(2)} in'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: ['Panel', 'Qty', 'Width (in)', 'Height (in)'],
            data: result.cutPanels
                .map(
                  (panel) => [
                    panel.name,
                    '${panel.quantity}',
                    panel.width.toStringAsFixed(2),
                    panel.height.toStringAsFixed(2),
                  ],
                )
                .toList(),
          ),
          pw.SizedBox(height: 12),
          pw.Bullet(text: 'Net volume: ${config.targetNetVolume.toStringAsFixed(2)} cf'),
          pw.Bullet(text: 'Gross volume: ${result.grossVolume.toStringAsFixed(3)} cf'),
          pw.Bullet(text: 'Estimated weight: ${result.boxWeight.toStringAsFixed(1)} lbs'),
          pw.Bullet(text: 'Estimated cost: \$${result.totalCost.toStringAsFixed(0)}'),
          if (config.isPorted) pw.Bullet(text: 'Port area: ${result.portArea.toStringAsFixed(1)} in²'),
          if (config.isPorted) pw.Bullet(text: 'Port length: ${result.portLength.toStringAsFixed(2)} in'),
        ],
      ),
    );
    final bytes = await document.save();
    return saveBytes(
      fileName: '${_safeBaseName(config.designName)}_cutsheet.pdf',
      bytes: bytes,
      mimeType: 'application/pdf',
    );
  }

  static Future<String> exportBlueprintPng(EnclosureConfig config, EnclosureResult result) async {
    final bytes = await BlueprintSheetPainter.renderPng(config, result);
    if (bytes == null) throw Exception('Blueprint render failed');
    return saveBytes(
      fileName: '${_safeBaseName(config.designName)}_blueprint.png',
      bytes: bytes,
      mimeType: 'image/png',
    );
  }

  static Future<String> exportFrontPanelSvg(EnclosureConfig config, EnclosureResult result) async {
    final svg = BlueprintSheetPainter.buildFrontPanelSvg(config, result);
    return saveBytes(
      fileName: '${_safeBaseName(config.designName)}_front_panel.svg',
      bytes: utf8.encode(svg),
      mimeType: 'image/svg+xml',
    );
  }

  static String _safeBaseName(String input) {
    final value = input.trim().isEmpty ? 'bass_builder' : input.trim();
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_|_$'), '');
  }
}