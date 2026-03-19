import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enclosure_config.dart';
import '../models/enclosure_result.dart';
import '../models/enums.dart';
import '../state/bass_builder_controller.dart';

class BlueprintCard extends StatelessWidget {
  const BlueprintCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Blueprint Views', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Front, side, and top plans are rendered from the same config/result model that powers export.'),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7F1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7D9C4)),
            ),
            child: CustomPaint(
              painter: BlueprintSheetPainter(controller.config, controller.result),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class BlueprintSheetPainter extends CustomPainter {
  const BlueprintSheetPainter(this.config, this.result);

  final EnclosureConfig config;
  final EnclosureResult result;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFE8E1D3);
    canvas.drawRect(Offset.zero & size, background);

    final frontRect = Rect.fromLTWH(24, 24, size.width * 0.44, size.height * 0.42);
    final sideRect = Rect.fromLTWH(size.width * 0.52, 24, size.width * 0.42, size.height * 0.42);
    final topRect = Rect.fromLTWH(24, size.height * 0.54, size.width * 0.7, size.height * 0.32);

    _drawFront(canvas, frontRect);
    _drawSide(canvas, sideRect);
    _drawTop(canvas, topRect);
  }

  void _drawFront(Canvas canvas, Rect rect) {
    _drawSheetBox(canvas, rect, 'FRONT VIEW');
    final box = _fitRect(rect, config.width, config.height);
    final outline = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.stroke..strokeWidth = 2;
    final lightFill = Paint()..color = Colors.white.withValues(alpha: 0.7);
    canvas.drawRect(box, lightFill);
    canvas.drawRect(box, outline);

    for (final center in _frontCenters(box)) {
      canvas.drawCircle(center, _scaleFor(box, config.width, config.height) * (config.outerDiameter / 2), Paint()..color = const Color(0xFF374151));
      canvas.drawCircle(center, _scaleFor(box, config.width, config.height) * (config.cutoutDiameter / 2), Paint()..color = const Color(0xFFE11D48)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    if (config.isPorted) {
      if (config.portType == PortType.slot) {
        final scale = _scaleFor(box, config.width, config.height);
        final portHeight = (config.height - (config.woodThickness * 2)) * scale;
        final portWidth = config.slotPortWidth * scale;
        final portCenterX = box.left + (config.portX * scale);
        final portCenterY = box.top + (config.portZ * scale);
        final portRect = Rect.fromLTWH(portCenterX - portWidth / 2, portCenterY - portHeight / 2, portWidth, portHeight);
        canvas.drawRect(portRect, Paint()..color = const Color(0xFF93C5FD));
        canvas.drawRect(portRect, Paint()..color = const Color(0xFF1D4ED8)..style = PaintingStyle.stroke..strokeWidth = 2);
      } else {
        final scale = _scaleFor(box, config.width, config.height);
        final portCenter = Offset(box.left + (config.portX * scale), box.top + (config.portZ * scale));
        canvas.drawCircle(portCenter, config.roundPortDiameter * scale / 2, Paint()..color = const Color(0xFF93C5FD));
      }
    }

    if (config.showTerminal) {
      final scale = _scaleFor(box, config.width, config.height);
      final terminalCenter = Offset(box.left + (config.terminalX * scale), box.top + (config.terminalZ * scale));
      canvas.drawCircle(terminalCenter, 1.75 * scale, Paint()..color = const Color(0xFFEAB308)..style = PaintingStyle.stroke..strokeWidth = 2);
    }
  }

  void _drawSide(Canvas canvas, Rect rect) {
    _drawSheetBox(canvas, rect, 'SIDE VIEW');
    final box = _fitRect(rect, result.externalDepth, config.height);
    final outline = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(box, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.drawRect(box, outline);

    final scale = _scaleFor(box, result.externalDepth, config.height);
    final frontThickness = config.woodThickness * config.frontLayers * scale;
    final topBottomThickness = config.woodThickness * config.topBottomLayers * scale;
    final cavity = Rect.fromLTWH(box.left + frontThickness, box.top + topBottomThickness, result.internalDepth * scale, result.internalHeight * scale);
    canvas.drawRect(cavity, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRect(cavity, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke);

    if (config.isPorted && config.portType == PortType.slot) {
      final dividerRect = Rect.fromLTWH(cavity.left, cavity.top, result.portLength.clamp(0.0, result.internalDepth) * scale, config.woodThickness * scale);
      canvas.drawRect(dividerRect, Paint()..color = const Color(0xFFD9A066));
    }

    if (config.isBandpass) {
      final ratio = result.portedChamberVolume / math.max(0.01, result.portedChamberVolume + result.sealedChamberVolume);
      final dividerX = cavity.left + (cavity.width * ratio);
      canvas.drawLine(Offset(dividerX, cavity.top), Offset(dividerX, cavity.bottom), Paint()..color = const Color(0xFF8B4513)..strokeWidth = 2);
    }
  }

  void _drawTop(Canvas canvas, Rect rect) {
    _drawSheetBox(canvas, rect, 'TOP VIEW');
    final box = _fitRect(rect, config.width, result.externalDepth);
    final outline = Paint()..color = const Color(0xFF1F2937)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawRect(box, Paint()..color = Colors.white.withValues(alpha: 0.7));
    canvas.drawRect(box, outline);

    final scale = _scaleFor(box, config.width, result.externalDepth);
    final cavity = Rect.fromLTWH(
      box.left + (config.woodThickness * config.sideLayers * scale),
      box.top + (config.woodThickness * config.frontLayers * scale),
      result.internalWidth * scale,
      result.internalDepth * scale,
    );
    canvas.drawRect(cavity, Paint()..color = const Color(0xFFF8FAFC));
    canvas.drawRect(cavity, Paint()..color = const Color(0xFF64748B)..style = PaintingStyle.stroke);

    if (config.isPorted && config.portType == PortType.slot) {
      final portRect = Rect.fromLTWH(cavity.left + ((config.portX - config.slotPortWidth / 2) * scale), cavity.top, config.slotPortWidth * scale, result.portLength.clamp(0.0, result.internalDepth) * scale);
      canvas.drawRect(portRect, Paint()..color = const Color(0xFF93C5FD));
      canvas.drawRect(portRect, Paint()..color = const Color(0xFF1D4ED8)..style = PaintingStyle.stroke..strokeWidth = 2);
    }

    _drawTopBraces(canvas, cavity, scale);
  }

  void _drawSheetBox(Canvas canvas, Rect rect, String title) {
    final border = Paint()..color = const Color(0xFFB8A891)..style = PaintingStyle.stroke..strokeWidth = 1;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(16)), border);
    final painter = TextPainter(
      text: TextSpan(text: title, style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 14)),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(rect.left + 12, rect.top + 10));
  }

  Rect _fitRect(Rect available, double width, double height) {
    final inner = available.deflate(18);
    final drawTop = inner.top + 20;
    final maxHeight = inner.height - 28;
    final scale = _scaleFor(Rect.fromLTWH(inner.left, drawTop, inner.width, maxHeight), width, height);
    final drawWidth = width * scale;
    final drawHeight = height * scale;
    return Rect.fromLTWH(inner.center.dx - drawWidth / 2, drawTop + (maxHeight - drawHeight) / 2, drawWidth, drawHeight);
  }

  double _scaleFor(Rect rect, double width, double height) {
    return math.min(rect.width / math.max(width, 1), rect.height / math.max(height, 1));
  }

  List<Offset> _frontCenters(Rect box) {
    final centers = <Offset>[];
    final spacing = (config.outerDiameter + 0.5) * _scaleFor(box, config.width, config.height);
    final offset = (config.numberOfSubs - 1) / 2;
    for (var index = 0; index < config.numberOfSubs; index++) {
      final baseX = box.left + (config.subX * _scaleFor(box, config.width, config.height));
      final baseY = box.top + (config.subZ * _scaleFor(box, config.width, config.height));
      final x = config.arrangement == SubArrangement.rowVertical ? baseX : baseX + ((index - offset) * spacing);
      final y = config.arrangement == SubArrangement.rowVertical ? baseY + ((index - offset) * spacing) : baseY;
      centers.add(Offset(x, y));
    }
    return centers;
  }

  void _drawTopBraces(Canvas canvas, Rect cavity, double scale) {
    if (config.braceType == BraceType.none) {
      return;
    }
    final paint = Paint()
      ..color = const Color(0xFF7C4A20)
      ..strokeWidth = config.braceType == BraceType.dowel ? 4 : 2;
    final count = config.braceCount.clamp(1, 6);
    for (var index = 0; index < count; index++) {
      final t = count == 1 ? 0.5 : 0.2 + (index * (0.6 / (count - 1)));
      switch (config.braceDirection) {
        case BraceDirection.sideToSide:
          final y = cavity.top + (cavity.height * t);
          canvas.drawLine(Offset(cavity.left, y), Offset(cavity.right, y), paint);
        case BraceDirection.frontToBack:
          final x = cavity.left + (cavity.width * t);
          canvas.drawLine(Offset(x, cavity.top), Offset(x, cavity.bottom), paint);
        case BraceDirection.topToBottom:
          final x = cavity.left + (cavity.width * t);
          canvas.drawLine(Offset(x, cavity.top), Offset(x, cavity.bottom), paint);
      }
    }
  }

  static Future<Uint8List> renderPng(EnclosureConfig config, EnclosureResult result) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = Size(1600, 1000);
    BlueprintSheetPainter(config, result).paint(canvas, size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  static String buildFrontPanelSvg(EnclosureConfig config, EnclosureResult result) {
    final subCenters = _staticFrontCenters(config);
    final buffer = StringBuffer()
      ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
      ..writeln('<svg xmlns="http://www.w3.org/2000/svg" width="${config.width}" height="${config.height}" viewBox="0 0 ${config.width} ${config.height}">')
      ..writeln('  <rect x="0" y="0" width="${config.width}" height="${config.height}" fill="none" stroke="black" stroke-width="0.1"/>');
    for (final center in subCenters) {
      buffer.writeln('  <circle cx="${center.dx}" cy="${config.height - center.dy}" r="${config.cutoutDiameter / 2}" fill="none" stroke="red" stroke-width="0.1"/>');
    }
    if (config.isPorted && config.portType == PortType.round) {
      buffer.writeln('  <circle cx="${config.portX}" cy="${config.height - config.portZ}" r="${config.roundPortDiameter / 2}" fill="none" stroke="blue" stroke-width="0.1"/>');
    }
    if (config.isPorted && config.portType == PortType.slot) {
      buffer.writeln('  <rect x="${config.portX - (config.slotPortWidth / 2)}" y="${config.woodThickness}" width="${config.slotPortWidth}" height="${config.height - (config.woodThickness * 2)}" fill="none" stroke="blue" stroke-width="0.1"/>');
    }
    if (config.showTerminal) {
      buffer.writeln('  <circle cx="${config.terminalX}" cy="${config.height - config.terminalZ}" r="1.75" fill="none" stroke="green" stroke-width="0.1"/>');
    }
    buffer.writeln('</svg>');
    return buffer.toString();
  }

  static List<Offset> _staticFrontCenters(EnclosureConfig config) {
    final positions = <Offset>[];
    final spacing = config.outerDiameter + 0.5;
    final offset = (config.numberOfSubs - 1) / 2;
    for (var index = 0; index < config.numberOfSubs; index++) {
      final x = config.arrangement == SubArrangement.rowVertical ? config.subX : config.subX + ((index - offset) * spacing);
      final y = config.arrangement == SubArrangement.rowVertical ? config.subZ + ((index - offset) * spacing) : config.subZ;
      positions.add(Offset(x, y));
    }
    return positions;
  }

  @override
  bool shouldRepaint(covariant BlueprintSheetPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.result != result;
  }
}