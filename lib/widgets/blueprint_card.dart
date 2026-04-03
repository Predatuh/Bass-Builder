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
        Text('Blueprint Views',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF7EC8E3),
                )),
        const SizedBox(height: 8),
        Text(
          'Engineering drawing — front, side, top orthographic projections.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: const Color(0xFF7EC8E3)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B2A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E3A5F)),
            ),
            clipBehavior: Clip.antiAlias,
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

  // Colors
  static const _bg = Color(0xFF0D1B2A);
  static const _grid = Color(0xFF112237);
  static const _construction = Color(0xFF1E3A5F);
  static const _outline = Color(0xFF7EC8E3);
  static const _dim = Color(0xFF48B0D5);
  static const _hatch = Color(0xFF2A5A8A);
  static const _sub = Color(0xFFE11D48);
  static const _port = Color(0xFFF97316);
  static const _terminal = Color(0xFFEAB308);
  static const _centerline = Color(0xFF3B82F6);
  static const _label = Color(0xFFCBE8F5);
  static const _dimText = Color(0xFF48B0D5);
  static const _titleText = Color(0xFF7EC8E3);

  @override
  void paint(Canvas canvas, Size size) {
    // Background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = _bg,
    );

    _drawGrid(canvas, size);

    final margin = 24.0;
    final titleH = 50.0;
    final drawH = size.height - margin * 2 - titleH;
    final drawW = size.width - margin * 2;

    // Three panels side by side: FRONT | SIDE | TOP
    final panelW = (drawW - 32) / 3;
    final panelH = drawH;

    final frontRect = Rect.fromLTWH(margin, margin, panelW, panelH);
    final sideRect = Rect.fromLTWH(margin + panelW + 16, margin, panelW, panelH);
    final topRect = Rect.fromLTWH(margin + (panelW + 16) * 2, margin, panelW, panelH);

    _drawPanel(canvas, frontRect, 'FRONT', config.width, config.height);
    _drawPanel(canvas, sideRect, 'SIDE', result.externalDepth, config.height);
    _drawPanel(canvas, topRect, 'TOP', config.width, result.externalDepth);

    _drawFrontComponents(canvas, frontRect);
    _drawSideComponents(canvas, sideRect);
    _drawTopComponents(canvas, topRect);

    // Dimension lines on each panel
    _drawPanelDimensions(canvas, frontRect, config.width, config.height, showHeight: true, showWidth: true);
    _drawPanelDimensions(canvas, sideRect, result.externalDepth, config.height, showHeight: false, showWidth: true, widthLabel: 'DEPTH');
    _drawPanelDimensions(canvas, topRect, config.width, result.externalDepth, showHeight: false, showWidth: true, heightLabel: 'DEPTH');

    // Wood thickness callout on front panel
    _drawWoodThicknessCallout(canvas, frontRect);
    // Port/sub info callout
    _drawComponentCallout(canvas, size, margin, titleH);

    _drawTitleBlock(canvas, size, margin, titleH);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 0.5;
    const step = 30.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  // Draw a single panel with outer border and wood-thickness hatch
  void _drawPanel(Canvas canvas, Rect rect, String label, double w, double h) {
    final scale = _fitScale(rect, w, h);
    final boxW = w * scale;
    final boxH = h * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;
    final boxRect = Rect.fromLTWH(ox, oy, boxW, boxH);

    // Construction fill
    canvas.drawRect(
      boxRect,
      Paint()..color = _construction.withValues(alpha: 0.15),
    );

    // Wood hatch on all 4 walls
    final t = config.woodThickness * scale;
    _drawHatchRect(canvas, Rect.fromLTWH(ox, oy, boxW, t)); // top wall
    _drawHatchRect(
        canvas, Rect.fromLTWH(ox, oy + boxH - t, boxW, t)); // bottom
    _drawHatchRect(canvas, Rect.fromLTWH(ox, oy + t, t, boxH - t * 2)); // left
    _drawHatchRect(
        canvas, Rect.fromLTWH(ox + boxW - t, oy + t, t, boxH - t * 2)); // right

    // Outline
    canvas.drawRect(
      boxRect,
      Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Inner cavity outline
    final innerRect = Rect.fromLTWH(ox + t, oy + t, boxW - t * 2, boxH - t * 2);
    canvas.drawRect(
      innerRect,
      Paint()
        ..color = _construction
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Panel label
    _drawText(
      canvas,
      label,
      Offset(ox + boxW / 2, oy - 14),
      _titleText,
      fontSize: 10,
      bold: true,
      center: true,
    );
  }

  void _drawHatchRect(Canvas canvas, Rect r) {
    if (r.width <= 0 || r.height <= 0) return;
    final paint = Paint()
      ..color = _hatch
      ..strokeWidth = 0.7;
    canvas.clipRect(r);
    const spacing = 5.0;
    final diag = (r.width + r.height);
    for (double d = -diag; d < diag; d += spacing) {
      canvas.drawLine(
        Offset(r.left + d, r.top),
        Offset(r.left + d + r.height, r.bottom),
        paint,
      );
    }
    canvas.restore();
    canvas.save(); // restore the clip
  }

  void _drawFrontComponents(Canvas canvas, Rect rect) {
    final scale = _fitScale(rect, config.width, config.height);
    final boxW = config.width * scale;
    final boxH = config.height * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;
    final t = config.woodThickness * scale;

    // Subs
    final spacing = config.outerDiameter + 0.5;
    final offset = (config.numberOfSubs - 1) / 2;
    for (var i = 0; i < config.numberOfSubs; i++) {
      final xOff = config.arrangement == SubArrangement.rowVertical
          ? 0.0
          : (i - offset) * spacing * scale;
      final yOff = config.arrangement == SubArrangement.rowVertical
          ? (i - offset) * spacing * scale
          : 0.0;
      final cx = ox + (config.subX * scale) + xOff;
      final cy = oy + boxH - (config.subZ * scale) + yOff;

      // Outer ring (filled dark)
      _drawCircle(
          canvas,
          Offset(cx, cy),
          config.outerDiameter / 2 * scale,
          fill: const Color(0xFF111827),
          stroke: _sub);
      // Cutout ring
      _drawCircle(
          canvas,
          Offset(cx, cy),
          config.cutoutDiameter / 2 * scale,
          fill: null,
          stroke: _sub,
          dashed: false);
      // Dashed centerlines
      _drawCenterlines(canvas, Offset(cx, cy), config.outerDiameter / 2 * scale + 4);
      // Leader label
      _drawLeader(canvas, Offset(cx, cy), 'SUB ${i + 1}', _sub);
    }

    // Port (front baffle only for FRONT view)
    if (config.isPorted &&
        (config.portPlacement == PortPlacement.frontBaffle ||
            config.portPlacement == PortPlacement.center)) {
      if (config.portType == PortType.round) {
        final pcx = ox + config.portX * scale;
        final pcy = oy + boxH - config.portZ * scale;
        _drawCircle(canvas, Offset(pcx, pcy),
            config.roundPortDiameter / 2 * scale,
            fill: null, stroke: _port);
        _drawCenterlines(
            canvas, Offset(pcx, pcy), config.roundPortDiameter / 2 * scale + 4);
        _drawLeader(canvas, Offset(pcx, pcy), 'PORT', _port);
      } else {
        // Slot port
        final pw = config.slotPortWidth * scale;
        final ph =
            (config.height - config.woodThickness * 2) * scale;
        final px = ox + t;
        final py = oy + t;
        canvas.drawRect(
          Rect.fromLTWH(px, py, pw, ph),
          Paint()
            ..color = _port.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
        canvas.drawRect(
          Rect.fromLTWH(px, py, pw, ph),
          Paint()
            ..color = _port
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    // Terminal
    if (config.showTerminal &&
        (config.portPlacement == PortPlacement.frontBaffle ||
            config.portPlacement == PortPlacement.center ||
            config.portPlacement == PortPlacement.rear)) {
      final tx = ox + config.terminalX * scale;
      final ty = oy + boxH - config.terminalZ * scale;
      _drawCircle(canvas, Offset(tx, ty), 1.75 * scale,
          fill: null, stroke: _terminal);
      _drawLeader(canvas, Offset(tx, ty), 'TERM', _terminal);
    }
  }

  void _drawSideComponents(Canvas canvas, Rect rect) {
    // Side view: depth x height - just shows the box outline and port if side-mounted
    // No sub circles needed unless mount side is left/right
    if (config.mountSide != MountSide.left && config.mountSide != MountSide.right) return;

    final scale = _fitScale(rect, result.externalDepth, config.height);
    final boxW = result.externalDepth * scale;
    final boxH = config.height * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;

    final cx = ox + config.subX * scale;
    final cy = oy + boxH - config.subZ * scale;
    _drawCircle(canvas, Offset(cx, cy), config.outerDiameter / 2 * scale,
        fill: const Color(0xFF111827), stroke: _sub);
    _drawCircle(canvas, Offset(cx, cy), config.cutoutDiameter / 2 * scale,
        fill: null, stroke: _sub);
    _drawCenterlines(
        canvas, Offset(cx, cy), config.outerDiameter / 2 * scale + 4);
  }

  void _drawTopComponents(Canvas canvas, Rect rect) {
    // Top view shows sub positions projected on top face
    if (config.mountSide != MountSide.top) return;

    final scale = _fitScale(rect, config.width, result.externalDepth);
    final boxW = config.width * scale;
    final boxH = result.externalDepth * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;

    final cx = ox + config.subX * scale;
    final cy = oy + config.subZ * scale;
    _drawCircle(canvas, Offset(cx, cy), config.outerDiameter / 2 * scale,
        fill: const Color(0xFF111827), stroke: _sub);
    _drawCenterlines(
        canvas, Offset(cx, cy), config.outerDiameter / 2 * scale + 4);
  }

  // Draw dimension lines on all sides of a panel  
  void _drawPanelDimensions(Canvas canvas, Rect rect, double w, double h,
      {bool showWidth = true, bool showHeight = true, String? widthLabel, String? heightLabel}) {
    final scale = _fitScale(rect, w, h);
    final boxW = w * scale;
    final boxH = h * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;
    const off = 14.0; // pixel offset from box edge

    if (showWidth) {
      // Width arrow below
      _drawArrow(canvas,
        Offset(ox, oy + boxH + off),
        Offset(ox + boxW, oy + boxH + off),
        widthLabel != null ? '$widthLabel: ${w.toStringAsFixed(2)}"' : '${w.toStringAsFixed(2)}"',
      );
      // Extension lines
      _drawExtLine(canvas, Offset(ox, oy + boxH), Offset(ox, oy + boxH + off + 2));
      _drawExtLine(canvas, Offset(ox + boxW, oy + boxH), Offset(ox + boxW, oy + boxH + off + 2));
    }

    if (showHeight) {
      // Height arrow left
      _drawArrow(canvas,
        Offset(ox - off, oy + boxH),
        Offset(ox - off, oy),
        heightLabel != null ? '$heightLabel: ${h.toStringAsFixed(2)}"' : '${h.toStringAsFixed(2)}"',
        vertical: true,
      );
      _drawExtLine(canvas, Offset(ox, oy), Offset(ox - off - 2, oy));
      _drawExtLine(canvas, Offset(ox, oy + boxH), Offset(ox - off - 2, oy + boxH));
    }

    // Inner cavity width (net interior)
    if (showWidth) {
      final t = config.woodThickness * scale;
      final innerW = boxW - t * 2;
      if (innerW > 20) {
        _drawArrow(canvas,
          Offset(ox + t, oy - off),
          Offset(ox + t + innerW, oy - off),
          'INT: ${(w - config.woodThickness * 2).toStringAsFixed(2)}"',
        );
        _drawExtLine(canvas, Offset(ox + t, oy), Offset(ox + t, oy - off - 2));
        _drawExtLine(canvas, Offset(ox + t + innerW, oy), Offset(ox + t + innerW, oy - off - 2));
      }
    }
  }

  void _drawExtLine(Canvas canvas, Offset from, Offset to) {
    canvas.drawLine(from, to, Paint()
      ..color = _dim.withValues(alpha: 0.5)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke);
  }

  void _drawWoodThicknessCallout(Canvas canvas, Rect rect) {
    final scale = _fitScale(rect, config.width, config.height);
    final boxW = config.width * scale;
    final boxH = config.height * scale;
    final ox = rect.left + (rect.width - boxW) / 2;
    final oy = rect.top + (rect.height - boxH) / 2;
    final t = config.woodThickness * scale;

    // Leader from top-left corner wall
    final from = Offset(ox + t / 2, oy + t / 2);
    final to = Offset(ox - 20, oy - 18);
    canvas.drawLine(from, to, Paint()
      ..color = _hatch.withValues(alpha: 0.8)
      ..strokeWidth = 0.8);
    canvas.drawCircle(from, 1.5, Paint()..color = _hatch);
    _drawText(canvas, '${config.woodThickness.toStringAsFixed(3)}" MDF',
        to + const Offset(-2, -10), _hatch, fontSize: 7.5, bold: true, alignRight: true);
  }

  void _drawComponentCallout(Canvas canvas, Size size, double margin, double titleH) {
    // Right-side info column
    final x = size.width - margin - 2.0;
    var y = margin + 4.0;
    void line(String text, Color color, {bool bold = false}) {
      _drawText(canvas, text, Offset(x, y), color,
          fontSize: 8.5, bold: bold, alignRight: true);
      y += 12;
    }

    _drawText(canvas, 'SPECIFICATIONS', Offset(x, y), _titleText,
        fontSize: 8, bold: true, alignRight: true);
    y += 14;

    line('${config.numberOfSubs}x ${config.subModel}', _label, bold: true);
    line('Outer dia: ${config.outerDiameter.toStringAsFixed(2)}"', _dimText);
    line('Cutout: ${config.cutoutDiameter.toStringAsFixed(2)}"', _dimText);
    line('Mount: ${config.mountSide.label}', _dimText);
    y += 6;
    if (config.isPorted) {
      line('PORT', _port, bold: true);
      if (config.portType == PortType.round) {
        line('Round dia: ${config.roundPortDiameter.toStringAsFixed(2)}"', _dimText);
      } else {
        line('Slot: ${config.slotPortWidth.toStringAsFixed(2)}" W', _dimText);
      }
      line('Tuning: ${config.tuning.toStringAsFixed(1)} Hz', _dimText);
    } else {
      line('SEALED', _label, bold: true);
    }
    y += 6;
    line('Wood: ${config.woodThickness.toStringAsFixed(3)}"', _label);
    line('Net vol: ${config.targetNetVolume.toStringAsFixed(3)} cf', _label);
    if (config.isPorted) {
      line('Ext depth: ${result.externalDepth.toStringAsFixed(3)}"', _label);
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, String label,
      {bool vertical = false}) {
    final paint = Paint()
      ..color = _dim
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(from, to, paint);
    final dir = (to - from) / (to - from).distance;
    // Arrowheads
    _arrowHead(canvas, to, dir, paint);
    _arrowHead(canvas, from, -dir, paint);
    // Label
    final mid = (from + to) / 2;
    _drawText(
      canvas,
      label,
      vertical ? Offset(mid.dx - 14, mid.dy) : Offset(mid.dx, mid.dy - 10),
      _dimText,
      fontSize: 8,
      center: true,
    );
  }

  void _arrowHead(Canvas canvas, Offset tip, Offset dir, Paint paint) {
    const size = 5.0;
    const angle = 0.4;
    final a = tip - Offset(
      dir.dx * size * math.cos(angle) - dir.dy * size * math.sin(angle),
      dir.dy * size * math.cos(angle) + dir.dx * size * math.sin(angle),
    );
    final b = tip - Offset(
      dir.dx * size * math.cos(angle) + dir.dy * size * math.sin(angle),
      dir.dy * size * math.cos(angle) - dir.dx * size * math.sin(angle),
    );
    canvas.drawLine(tip, a, paint);
    canvas.drawLine(tip, b, paint);
  }

  void _drawTitleBlock(Canvas canvas, Size size, double margin, double titleH) {
    final y = size.height - titleH;
    canvas.drawLine(
      Offset(margin, y),
      Offset(size.width - margin, y),
      Paint()
        ..color = _construction
        ..strokeWidth = 1.0,
    );
    _drawText(
      canvas,
      config.designName.toUpperCase(),
      Offset(margin + 8, y + 8),
      _titleText,
      fontSize: 11,
      bold: true,
    );
    _drawText(
      canvas,
      '${config.width.toStringAsFixed(1)}" W x ${config.height.toStringAsFixed(1)}" H x ${result.externalDepth.toStringAsFixed(2)}" D   '
      '${result.externalDepth > 0 ? config.targetNetVolume.toStringAsFixed(2) : '--'} cf   '
      '${config.isPorted ? '${config.tuning.toStringAsFixed(1)} Hz' : config.enclosureType.label}',
      Offset(margin + 8, y + 26),
      _dim,
      fontSize: 9,
    );
    _drawText(
      canvas,
      '${config.numberOfSubs}x ${config.subModel}',
      Offset(size.width - margin - 8, y + 8),
      _label,
      fontSize: 9,
      alignRight: true,
    );
    _drawText(
      canvas,
      config.portType == PortType.slot
          ? 'Slot ${config.slotPortWidth.toStringAsFixed(1)}" x ${config.slotPortHeight.toStringAsFixed(1)}"'
          : config.portType == PortType.round
              ? 'Round ${config.roundPortDiameter.toStringAsFixed(1)}" dia.'
              : 'Sealed',
      Offset(size.width - margin - 8, y + 24),
      _dim,
      fontSize: 9,
      alignRight: true,
    );
  }

  double _fitScale(Rect rect, double w, double h) {
    const pad = 28.0;
    if (w <= 0 || h <= 0) return 1;
    return math.min(
      (rect.width - pad * 2) / w,
      (rect.height - pad * 2) / h,
    );
  }

  void _drawCircle(Canvas canvas, Offset center, double radius,
      {Color? fill, required Color stroke, bool dashed = false}) {
    if (fill != null) {
      canvas.drawCircle(center, radius, Paint()..color = fill);
    }
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = stroke
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }

  void _drawCenterlines(Canvas canvas, Offset center, double extent) {
    final paint = Paint()
      ..color = _centerline
      ..strokeWidth = 0.7;
    // Dashed horizontal
    _dashedLine(
        canvas, Offset(center.dx - extent, center.dy),
        Offset(center.dx + extent, center.dy), paint);
    // Dashed vertical
    _dashedLine(
        canvas, Offset(center.dx, center.dy - extent),
        Offset(center.dx, center.dy + extent), paint);
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dashLen = 4.0;
    const gapLen = 3.0;
    final total = (to - from).distance;
    final dir = (to - from) / total;
    double d = 0;
    bool drawing = true;
    while (d < total) {
      final segLen = drawing ? dashLen : gapLen;
      final end = math.min(d + segLen, total);
      if (drawing) {
        canvas.drawLine(from + dir * d, from + dir * end, paint);
      }
      d = end;
      drawing = !drawing;
    }
  }

  void _drawLeader(Canvas canvas, Offset from, String label, Color color) {
    final to = from + const Offset(14, -14);
    canvas.drawLine(
      from,
      to,
      Paint()
        ..color = color.withValues(alpha: 0.7)
        ..strokeWidth = 0.8,
    );
    _drawText(canvas, label, to + const Offset(2, -8), color,
        fontSize: 8, bold: true);
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    Color color, {
    double fontSize = 10,
    bool bold = false,
    bool center = false,
    bool alignRight = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight
        ? pos.dx - tp.width
        : center
            ? pos.dx - tp.width / 2
            : pos.dx;
    tp.paint(canvas, Offset(dx, pos.dy));
  }

  @override
  bool shouldRepaint(covariant BlueprintSheetPainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.result != result;
  }

  // Static export helpers retained from original
  static Future<Uint8List?> renderPng(EnclosureConfig config, EnclosureResult result, {double width = 1200, double height = 800}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    BlueprintSheetPainter(config, result).paint(canvas, Size(width, height));
    final picture = recorder.endRecording();
    final image = await picture.toImage(width.round(), height.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  static String buildFrontPanelSvg(EnclosureConfig config, EnclosureResult result) {
    final w = config.width;
    final h = config.height;
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${w * 10} ${h * 10}">'
        '<rect width="${w * 10}" height="${h * 10}" fill="#0D1B2A"/>'
        '<rect x="7.5" y="7.5" width="${(w - 1.5) * 10}" height="${(h - 1.5) * 10}" '
        'fill="none" stroke="#7EC8E3" stroke-width="1.5"/>'
        '</svg>';
  }
}
