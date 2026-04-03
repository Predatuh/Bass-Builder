import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enclosure_config.dart';
import '../models/enums.dart';
import '../screens/fullscreen_preview_page.dart';
import '../state/bass_builder_controller.dart';

enum _InteractionMode { rotate, place }

enum _PlaceTarget { none, sub, port, terminal }

class PreviewSceneCard extends StatefulWidget {
  const PreviewSceneCard({super.key});

  @override
  State<PreviewSceneCard> createState() => _PreviewSceneCardState();
}

class _PreviewSceneCardState extends State<PreviewSceneCard> {
  double _yaw = -0.55;
  double _pitch = 0.45;
  double _zoom = 1.0;
  _InteractionMode _mode = _InteractionMode.rotate;
  _PlaceTarget _activeTarget = _PlaceTarget.none;
  Size _canvasSize = Size.zero;

  // Project a 3D point to screen using current yaw/pitch/zoom and canvas size
  Offset _projectPoint(_Vec3 point) {
    final center = Offset(_canvasSize.width / 2, _canvasSize.height / 2 + 24);
    final config = context.read<BassBuilderController>().config;
    final result = context.read<BassBuilderController>().result;
    final scale = math.min(
          _canvasSize.width / (config.width + result.externalDepth),
          _canvasSize.height / (config.height + result.externalDepth),
        ) *
        3.5 *
        _zoom;

    final rotY = _Vec3(
      (point.x * math.cos(_yaw)) - (point.z * math.sin(_yaw)),
      point.y,
      (point.x * math.sin(_yaw)) + (point.z * math.cos(_yaw)),
    );
    final rot = _Vec3(
      rotY.x,
      (rotY.y * math.cos(_pitch)) - (rotY.z * math.sin(_pitch)),
      (rotY.y * math.sin(_pitch)) + (rotY.z * math.cos(_pitch)),
    );
    final p = 1.0 / (1 + (rot.z / 220));
    return Offset(center.dx + rot.x * scale * p, center.dy + rot.y * scale * p);
  }

  // Hit test: returns which component was tapped
  _PlaceTarget _hitTest(Offset tap) {
    final controller = context.read<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;
    final externalDepth = result.externalDepth;

    // Sub center (front face)
    final subX = config.subX - config.width / 2;
    final subY = config.height / 2 - config.subZ;
    final subScreen = _projectPoint(_Vec3(subX, subY, externalDepth / 2 + 0.02));
    if ((tap - subScreen).distance < 24) return _PlaceTarget.sub;

    // Port center (front baffle only for hit-test simplification)
    if (config.isPorted) {
      final px = config.portX - config.width / 2;
      final py = config.height / 2 - config.portZ;
      final portScreen =
          _projectPoint(_Vec3(px, py, externalDepth / 2 + 0.02));
      if ((tap - portScreen).distance < 20) return _PlaceTarget.port;
    }

    // Terminal
    if (config.showTerminal) {
      final tx = config.terminalX - config.width / 2;
      final ty = config.height / 2 - config.terminalZ;
      final termScreen =
          _projectPoint(_Vec3(tx, ty, externalDepth / 2 + 0.02));
      if ((tap - termScreen).distance < 18) return _PlaceTarget.terminal;
    }

    return _PlaceTarget.none;
  }

  // Convert screen drag delta to inch delta using current scale
  double _pxToInches(double px) {
    final controller = context.read<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;
    return px /
        (math.min(
              _canvasSize.width / (config.width + result.externalDepth),
              _canvasSize.height / (config.height + result.externalDepth),
            ) *
            3.5 *
            _zoom);
  }

  void _handleDrag(DragUpdateDetails details, EnclosureConfig config) {
    if (_activeTarget == _PlaceTarget.none) return;
    final dx = _pxToInches(details.delta.dx);
    final dy = _pxToInches(-details.delta.dy); // invert Y
    final controller = context.read<BassBuilderController>();
    switch (_activeTarget) {
      case _PlaceTarget.sub:
        controller.updatePlacement(
          subX: (config.subX + dx).clamp(1.0, config.width - 1),
          subZ: (config.subZ + dy).clamp(1.0, config.height - 1),
        );
      case _PlaceTarget.port:
        controller.updatePlacement(
          portX: (config.portX + dx).clamp(1.0, config.width - 1),
          portZ: (config.portZ + dy).clamp(1.0, config.height - 1),
        );
      case _PlaceTarget.terminal:
        controller.updatePlacement(
          terminalX: (config.terminalX + dx).clamp(1.0, config.width - 1),
          terminalZ: (config.terminalZ + dy).clamp(1.0, config.height - 1),
        );
      case _PlaceTarget.none:
        break;
    }
  }

  String _activeTargetLabel() {
    switch (_activeTarget) {
      case _PlaceTarget.sub:
        return 'Sub';
      case _PlaceTarget.port:
        return 'Port';
      case _PlaceTarget.terminal:
        return 'Terminal';
      case _PlaceTarget.none:
        return 'Tap to select component';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;
    final cs = Theme.of(context).colorScheme;
    final labelColor = Theme.of(context).colorScheme.onSurface;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('3D Preview',
                        style: Theme.of(context).textTheme.titleLarge)),
                Wrap(
                  spacing: 8,
                  children: [
                    FilterChip(
                      label: const Text('Transparent'),
                      selected: config.showTransparent,
                      onSelected: (v) =>
                          controller.updateDisplaySettings(showTransparent: v),
                    ),
                    FilterChip(
                      label: const Text('Exploded'),
                      selected: config.showExploded,
                      onSelected: (v) =>
                          controller.updateDisplaySettings(showExploded: v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 400,
              child: LayoutBuilder(
            builder: (ctx, constraints) {
              _canvasSize = constraints.biggest;
              return Stack(
                children: [
                  // Canvas
                  GestureDetector(
                    onScaleUpdate: _mode == _InteractionMode.rotate
                        ? (details) {
                            setState(() {
                              _yaw += details.focalPointDelta.dx * 0.01;
                              _pitch -= details.focalPointDelta.dy * 0.01;
                              _zoom = (_zoom * details.scale).clamp(0.3, 4.0);
                            });
                          }
                        : null,
                    onTapDown: _mode == _InteractionMode.place
                        ? (details) {
                            setState(() {
                              _activeTarget =
                                  _hitTest(details.localPosition);
                            });
                          }
                        : null,
                    onPanUpdate: _mode == _InteractionMode.place
                        ? (details) => _handleDrag(details, config)
                        : null,
                    child: CustomPaint(
                      painter: ScenePainter(
                        config: config,
                        externalDepth: result.externalDepth,
                        yaw: _yaw,
                        pitch: _pitch,
                        zoom: _zoom,
                        labelColor: labelColor,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),

                  // Fullscreen button
                  Positioned(
                    top: 6,
                    right: 6,
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen),
                      tooltip: 'Fullscreen',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FullscreenPreviewPage(),
                        ),
                      ),
                    ),
                  ),

                  // Mode toggle
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Row(
                      children: [
                        _ModeChip(
                          icon: Icons.rotate_90_degrees_ccw,
                          label: 'Rotate',
                          selected: _mode == _InteractionMode.rotate,
                          onTap: () => setState(() {
                            _mode = _InteractionMode.rotate;
                            _activeTarget = _PlaceTarget.none;
                          }),
                          cs: cs,
                        ),
                        const SizedBox(width: 6),
                        _ModeChip(
                          icon: Icons.open_with,
                          label: 'Place',
                          selected: _mode == _InteractionMode.place,
                          onTap: () => setState(() =>
                              _mode = _InteractionMode.place),
                          cs: cs,
                        ),
                      ],
                    ),
                  ),

                  // Zoom buttons
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _IconFab(
                          icon: Icons.add,
                          onTap: () => setState(
                              () => _zoom = (_zoom * 1.2).clamp(0.2, 5.0)),
                        ),
                        const SizedBox(height: 8),
                        _IconFab(
                          icon: Icons.remove,
                          onTap: () => setState(
                              () => _zoom = (_zoom / 1.2).clamp(0.2, 5.0)),
                        ),
                        const SizedBox(height: 8),
                        _IconFab(
                          icon: Icons.refresh,
                          onTap: () => setState(() {
                            _yaw = -0.55;
                            _pitch = 0.45;
                            _zoom = 1.0;
                          }),
                        ),
                      ],
                    ),
                  ),

                  // Place mode: coordinate readout
                  if (_mode == _InteractionMode.place)
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: _PlaceReadout(
                        target: _activeTargetLabel(),
                        config: config,
                        activeTarget: _activeTarget,
                        cs: cs,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
        ),
      ),
    );
  }
}

// ─── Overlay Helpers ──────────────────────────────────────────────────────────

class _ModeChip extends StatelessWidget {
  const _ModeChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.cs,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected
              ? cs.primary.withValues(alpha: 0.9)
              : cs.surface.withValues(alpha: 0.80),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? cs.onPrimary : cs.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? cs.onPrimary : cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconFab extends StatelessWidget {
  const _IconFab({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: cs.primary),
        ),
      ),
    );
  }
}

class _PlaceReadout extends StatelessWidget {
  const _PlaceReadout({
    required this.target,
    required this.config,
    required this.activeTarget,
    required this.cs,
  });
  final String target;
  final EnclosureConfig config;
  final _PlaceTarget activeTarget;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    String coords = '';
    switch (activeTarget) {
      case _PlaceTarget.sub:
        coords = 'X:${config.subX.toStringAsFixed(1)}" Z:${config.subZ.toStringAsFixed(1)}"';
      case _PlaceTarget.port:
        coords = 'X:${config.portX.toStringAsFixed(1)}" Z:${config.portZ.toStringAsFixed(1)}"';
      case _PlaceTarget.terminal:
        coords =
            'X:${config.terminalX.toStringAsFixed(1)}" Z:${config.terminalZ.toStringAsFixed(1)}"';
      case _PlaceTarget.none:
        coords = '';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            target,
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          if (coords.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              coords,
              style: TextStyle(color: cs.onSurface, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Scene Painter (public — also used by FullscreenPreviewPage) ──────────────

class ScenePainter extends CustomPainter {
  const ScenePainter({
    required this.config,
    required this.externalDepth,
    required this.yaw,
    required this.pitch,
    required this.zoom,
    this.labelColor = const Color(0xFF111827),
  });

  final EnclosureConfig config;
  final double externalDepth;
  final double yaw;
  final double pitch;
  final double zoom;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 24);
    final scale = math.min(
          size.width / (config.width + externalDepth),
          size.height / (config.height + externalDepth),
        ) *
        3.5 *
        zoom;
    final explode = config.showExploded ? 0.5 : 0.0;
    final faces = _buildFaces(explode);

    final projectedFaces = faces
        .map((face) {
          final points =
              face.points.map((p) => _project(p, center, scale)).toList();
          final depth = face.points.fold<double>(
                0,
                (sum, p) => sum + p.z,
              ) /
              face.points.length;
          return _ProjectedFace(
            points: points,
            depth: depth,
            color: face.color,
            stroke: face.stroke,
          );
        })
        .toList()
      ..sort((a, b) => a.depth.compareTo(b.depth));

    for (final face in projectedFaces) {
      final path = Path()..addPolygon(face.points, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = face.color
              .withValues(alpha: config.showTransparent ? 0.22 : 0.92)
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = face.stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    _drawComponentRings(canvas, center, scale);
    _drawDimensionLines(canvas, center, scale);

    // Compact info line top-left
    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text:
            '${config.width.toStringAsFixed(1)}" W  ×  ${config.height.toStringAsFixed(1)}" H  ×  ${externalDepth.toStringAsFixed(1)}" D',
        style: TextStyle(
            color: labelColor, fontWeight: FontWeight.w700, fontSize: 13),
      ),
    )..layout();
    labelPainter.paint(canvas, const Offset(20, 16));
  }

  void _drawDimensionLines(Canvas canvas, Offset center, double scale) {
    final halfW = config.width / 2;
    final halfH = config.height / 2;
    final halfD = externalDepth / 2;
    const gap = 1.8; // inch gap from box edge to dimension line

    final dimPaint = Paint()
      ..color = const Color(0xFF7EC8E3)
      ..strokeWidth = 1.0;

    // Width line — along bottom edge, offset below (yMax side)
    final wA = _project(_v(-halfW, halfH + gap, halfD), center, scale);
    final wB = _project(_v(halfW, halfH + gap, halfD), center, scale);
    canvas.drawLine(wA, wB, dimPaint);
    _drawArrowHead3D(canvas, wA, wB, dimPaint);
    _drawArrowHead3D(canvas, wB, wA, dimPaint);
    _drawLabel3D(canvas, (wA + wB) / 2 + const Offset(0, 8),
        '${config.width.toStringAsFixed(2)}"', const Color(0xFF7EC8E3));

    // Height line — along left edge, offset left (xMin side)
    final hA = _project(_v(-halfW - gap, -halfH, halfD), center, scale);
    final hB = _project(_v(-halfW - gap, halfH, halfD), center, scale);
    canvas.drawLine(hA, hB, dimPaint);
    _drawArrowHead3D(canvas, hA, hB, dimPaint);
    _drawArrowHead3D(canvas, hB, hA, dimPaint);
    _drawLabel3D(canvas, (hA + hB) / 2 + const Offset(-28, 0),
        '${config.height.toStringAsFixed(2)}"', const Color(0xFF7EC8E3));

    // Depth line — along top-right edge
    final dA = _project(_v(halfW + gap, -halfH - gap, halfD), center, scale);
    final dB = _project(_v(halfW + gap, -halfH - gap, -halfD), center, scale);
    canvas.drawLine(dA, dB, dimPaint);
    _drawArrowHead3D(canvas, dA, dB, dimPaint);
    _drawArrowHead3D(canvas, dB, dA, dimPaint);
    _drawLabel3D(canvas, (dA + dB) / 2 + const Offset(6, -6),
        '${externalDepth.toStringAsFixed(2)}"', const Color(0xFF7EC8E3));

    // Tick marks at ends
    for (final pt in [wA, wB, hA, hB, dA, dB]) {
      canvas.drawCircle(pt, 2, Paint()..color = const Color(0xFF7EC8E3));
    }
  }

  void _drawArrowHead3D(Canvas canvas, Offset from, Offset to, Paint paint) {
    const size = 5.0;
    const angle = 0.45;
    final dir = (to - from);
    final d = dir.distance;
    if (d < 0.01) return;
    final nDir = dir / d;
    final tip = from + nDir * (size * 0.5);
    final a = tip - Offset(
      nDir.dx * size * math.cos(angle) - nDir.dy * size * math.sin(angle),
      nDir.dy * size * math.cos(angle) + nDir.dx * size * math.sin(angle),
    );
    final b = tip - Offset(
      nDir.dx * size * math.cos(angle) + nDir.dy * size * math.sin(angle),
      nDir.dy * size * math.cos(angle) - nDir.dx * size * math.sin(angle),
    );
    canvas.drawLine(tip, a, paint);
    canvas.drawLine(tip, b, paint);
  }

  void _drawLabel3D(Canvas canvas, Offset pos, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
      textDirection: TextDirection.ltr,
    )..layout();
    // Small background pill for readability
    final rect = Rect.fromCenter(center: pos + Offset(tp.width / 2, tp.height / 2), width: tp.width + 6, height: tp.height + 4);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        Paint()..color = const Color(0xCC0D1B2A));
    tp.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant ScenePainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.externalDepth != externalDepth ||
        oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.labelColor != labelColor;
  }

  List<_Face3D> _buildFaces(double explode) {
    final t = config.woodThickness;
    final halfW = config.width / 2;
    final halfH = config.height / 2;
    final halfD = externalDepth / 2;

    // Outer shell corners
    final xMin = -halfW - explode;
    final xMax = halfW + explode;
    final yMin = -halfH - explode;
    final yMax = halfH + explode;
    final zMin = -halfD - explode;
    final zMax = halfD + explode;

    // Inner cavity corners (inset by wood thickness)
    final ixMin = xMin + t;
    final ixMax = xMax - t;
    final iyMin = yMin + t;
    final iyMax = yMax - t;
    final izMin = zMin + t;
    final izMax = zMax - t;

    // Wood colors: outer faces slightly darker, inner cavity lighter
    const woodSide = Color(0xFFB8843A);
    const woodSideStroke = Color(0xFF7C4A20);
    const woodFront = Color(0xFFCB9A52);
    const woodFrontStroke = Color(0xFF7C4A20);
    const woodTop = Color(0xFFD9A870);
    const cavityColor = Color(0xFF1A0F00); // dark interior
    const cavityStroke = Color(0xFF3A2000);

    final faces = <_Face3D>[];

    // ── Outer faces ────────────────────────────────────────
    // Front face (zMax)
    faces.add(_Face3D(
      points: [_v(xMin, yMin, zMax), _v(xMax, yMin, zMax), _v(xMax, yMax, zMax), _v(xMin, yMax, zMax)],
      color: woodFront, stroke: woodFrontStroke,
    ));
    // Back face (zMin)
    faces.add(_Face3D(
      points: [_v(xMin, yMin, zMin), _v(xMax, yMin, zMin), _v(xMax, yMax, zMin), _v(xMin, yMax, zMin)],
      color: woodFront.withValues(alpha: 0.85), stroke: woodFrontStroke,
    ));
    // Left face (xMin)
    faces.add(_Face3D(
      points: [_v(xMin, yMin, zMin), _v(xMin, yMin, zMax), _v(xMin, yMax, zMax), _v(xMin, yMax, zMin)],
      color: woodSide, stroke: woodSideStroke,
    ));
    // Right face (xMax)
    faces.add(_Face3D(
      points: [_v(xMax, yMin, zMin), _v(xMax, yMin, zMax), _v(xMax, yMax, zMax), _v(xMax, yMax, zMin)],
      color: woodSide, stroke: woodSideStroke,
    ));
    // Top face (yMin — y axis is inverted, yMin = visual top)
    faces.add(_Face3D(
      points: [_v(xMin, yMin, zMin), _v(xMax, yMin, zMin), _v(xMax, yMin, zMax), _v(xMin, yMin, zMax)],
      color: woodTop, stroke: woodSideStroke,
    ));
    // Bottom face (yMax)
    faces.add(_Face3D(
      points: [_v(xMin, yMax, zMin), _v(xMax, yMax, zMin), _v(xMax, yMax, zMax), _v(xMin, yMax, zMax)],
      color: woodTop.withValues(alpha: 0.85), stroke: woodSideStroke,
    ));

    // ── Inner faces (cavity walls — shown when transparent or exploded) ──
    if (config.showTransparent || config.showExploded) {
      // Front inner
      faces.add(_Face3D(
        points: [_v(ixMin, iyMin, izMax), _v(ixMax, iyMin, izMax), _v(ixMax, iyMax, izMax), _v(ixMin, iyMax, izMax)],
        color: cavityColor, stroke: cavityStroke,
      ));
      // Back inner
      faces.add(_Face3D(
        points: [_v(ixMin, iyMin, izMin), _v(ixMax, iyMin, izMin), _v(ixMax, iyMax, izMin), _v(ixMin, iyMax, izMin)],
        color: cavityColor, stroke: cavityStroke,
      ));
      // Left inner
      faces.add(_Face3D(
        points: [_v(ixMin, iyMin, izMin), _v(ixMin, iyMin, izMax), _v(ixMin, iyMax, izMax), _v(ixMin, iyMax, izMin)],
        color: cavityColor, stroke: cavityStroke,
      ));
      // Right inner
      faces.add(_Face3D(
        points: [_v(ixMax, iyMin, izMin), _v(ixMax, iyMin, izMax), _v(ixMax, iyMax, izMax), _v(ixMax, iyMax, izMin)],
        color: cavityColor, stroke: cavityStroke,
      ));
      // Top inner
      faces.add(_Face3D(
        points: [_v(ixMin, iyMin, izMin), _v(ixMax, iyMin, izMin), _v(ixMax, iyMin, izMax), _v(ixMin, iyMin, izMax)],
        color: cavityColor, stroke: cavityStroke,
      ));
      // Bottom inner
      faces.add(_Face3D(
        points: [_v(ixMin, iyMax, izMin), _v(ixMax, iyMax, izMin), _v(ixMax, iyMax, izMax), _v(ixMin, iyMax, izMax)],
        color: cavityColor, stroke: cavityStroke,
      ));

      // ── Wood edge cross-sections (visible cut edges) ──
      // These L-shaped patches fill the gap between inner and outer
      // on the visible edges (top-front horizontal edge, etc.)
      const edgeColor = Color(0xFF8B5E2C);
      const edgeStroke = Color(0xFF5A3A10);
      // Top-front edge strip
      faces.add(_Face3D(
        points: [_v(xMin, yMin, izMax), _v(xMax, yMin, izMax), _v(xMax, iyMin, zMax), _v(xMin, iyMin, zMax)],
        color: edgeColor, stroke: edgeStroke,
      ));
      // Top-back edge strip
      faces.add(_Face3D(
        points: [_v(xMin, yMin, izMin), _v(xMax, yMin, izMin), _v(xMax, iyMin, zMin), _v(xMin, iyMin, zMin)],
        color: edgeColor, stroke: edgeStroke,
      ));
      // Bottom-front edge strip
      faces.add(_Face3D(
        points: [_v(xMin, yMax, izMax), _v(xMax, yMax, izMax), _v(xMax, iyMax, zMax), _v(xMin, iyMax, zMax)],
        color: edgeColor, stroke: edgeStroke,
      ));
    }

    return faces;
  }

  void _drawComponentRings(Canvas canvas, Offset center, double scale) {
    final subCenters = _componentCenters();
    for (final subCenter in subCenters) {
      _draw3DSub(canvas, center, scale, subCenter);
    }

    if (config.isPorted) {
      final portCenter = _portCenter();
      if (config.portType == PortType.round) {
        _draw3DAeroport(canvas, center, scale, portCenter);
      } else {
        final rectPoints = _slotPortPoints()
            .map((p) => _project(p, center, scale))
            .toList();
        final path = Path()..addPolygon(rectPoints, true);
        canvas.drawPath(
          path,
          Paint()..color = const Color(0xFFC26B2D).withValues(alpha: 0.8),
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF7C4A20)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );
      }
    }

    if (config.showTerminal) {
      final terminalCenter = _terminalCenter();
      _drawRing(canvas, center, scale, terminalCenter, 1.75,
          const Color(0xFFEAB308), false);
    }

    _drawBraces(canvas, center, scale);
  }

  // Draw a realistic 3D subwoofer: basket ring, surround, cone frustum, dust cap
  void _draw3DSub(Canvas canvas, Offset center, double scale, _Vec3 subC) {
    final r = config.outerDiameter / 2; // basket radius
    final rc = config.cutoutDiameter / 2; // cutout / surround radius
    final dustR = rc * 0.28; // dust cap radius
    const segments = 30;

    // Infer normal direction from mount side
    final normal = _mountNormal();
    final depth = 2.0; // cone depth in inches

    // Basket ring (filled dark grey)
    _drawRingOnFace(canvas, center, scale, subC, r, normal,
        const Color(0xFF1F1F1F), const Color(0xFF444444), filled: true);
    // Surround ring (rubber, reddish)
    _drawRingOnFace(canvas, center, scale, subC, rc, normal,
        const Color(0xFF2A0A0A), const Color(0xFFE11D48), filled: true);

    // Cone: frustum from surround edge inward to dust cap, offset along normal
    final conePoints = <_Vec3>[];
    final capPoints = <_Vec3>[];
    for (var i = 0; i <= segments; i++) {
      final theta = (i / segments) * math.pi * 2;
      // Surround edge (on face)
      conePoints.add(_radialPoint(subC, rc, theta, normal, 0));
      // Dust cap edge (offset along normal by cone depth)
      capPoints.add(_radialPoint(subC, dustR, theta, normal, depth));
    }

    // Draw cone side panels as quads
    for (var i = 0; i < segments; i++) {
      final quad = [conePoints[i], conePoints[i + 1], capPoints[i + 1], capPoints[i]];
      final projected = quad.map((p) => _project(p, center, scale)).toList();
      final path = Path()..addPolygon(projected, true);
      canvas.drawPath(path, Paint()..color = const Color(0xFF1A1A1A));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF333333)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5);
    }

    // Dust cap (filled circle at tip)
    final capCenter3D = _Vec3(
      subC.x + normal.x * depth,
      subC.y + normal.y * depth,
      subC.z + normal.z * depth,
    );
    _drawRingOnFace(canvas, center, scale, capCenter3D, dustR, normal,
        const Color(0xFF555555), const Color(0xFF888888), filled: true);
  }

  // Draw 3D aeroport: cylinder tube extruded along mount normal
  void _draw3DAeroport(Canvas canvas, Offset center, double scale, _Vec3 portC) {
    final R = config.roundPortDiameter / 2;
    const segments = 24;
    final normal = _portNormal();
    final portLen = config.portDepthInsideBox > 0
        ? config.portDepthInsideBox
        : math.min(externalDepth * 0.6, 8.0);

    final frontRing = <_Vec3>[];
    final backRing = <_Vec3>[];
    for (var i = 0; i <= segments; i++) {
      final theta = (i / segments) * math.pi * 2;
      frontRing.add(_radialPoint(portC, R, theta, normal, 0));
      backRing.add(_radialPoint(portC, R, theta, normal, portLen));
    }

    // Cylinder side panels
    for (var i = 0; i < segments; i++) {
      final quad = [frontRing[i], frontRing[i + 1], backRing[i + 1], backRing[i]];
      final projected = quad.map((p) => _project(p, center, scale)).toList();
      final path = Path()..addPolygon(projected, true);
      canvas.drawPath(path, Paint()..color = const Color(0xFFA0522D).withValues(alpha: 0.85));
      canvas.drawPath(path, Paint()
        ..color = const Color(0xFF7C4A20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8);
    }

    // Front opening
    _drawRingOnFace(canvas, center, scale, portC, R, normal,
        Colors.transparent, const Color(0xFFF97316), filled: false);
  }

  // Mount-face normal vector for sub
  _Vec3 _mountNormal() {
    switch (config.mountSide) {
      case MountSide.front:  return _v(0, 0, 1);
      case MountSide.back:   return _v(0, 0, -1);
      case MountSide.left:   return _v(-1, 0, 0);
      case MountSide.right:  return _v(1, 0, 0);
      case MountSide.top:    return _v(0, -1, 0);
      case MountSide.bottom: return _v(0, 1, 0);
    }
  }

  // Port face normal
  _Vec3 _portNormal() {
    switch (config.portPlacement) {
      case PortPlacement.rear:        return _v(0, 0, -1);
      case PortPlacement.top:         return _v(0, -1, 0);
      case PortPlacement.leftFront:
      case PortPlacement.leftRear:    return _v(-1, 0, 0);
      case PortPlacement.rightFront:
      case PortPlacement.rightRear:   return _v(1, 0, 0);
      default:                        return _v(0, 0, 1);
    }
  }

  // Build a 3D point on a circle around center, on a face described by normal
  _Vec3 _radialPoint(_Vec3 c, double r, double theta, _Vec3 n, double offset) {
    // Build tangent axes perpendicular to normal
    _Vec3 up;
    if (n.x.abs() < 0.9) {
      up = _Vec3(-n.y * 0, 1, 0); // world up
    } else {
      up = _Vec3(0, 0, 1);
    }
    // tangent = n × up
    final tx = n.y * up.z - n.z * up.y;
    final ty = n.z * up.x - n.x * up.z;
    final tz = n.x * up.y - n.y * up.x;
    final tLen = math.sqrt(tx * tx + ty * ty + tz * tz);
    final t = _Vec3(tx / tLen, ty / tLen, tz / tLen);
    // bitangent = n × t
    final bx = n.y * t.z - n.z * t.y;
    final by = n.z * t.x - n.x * t.z;
    final bz = n.x * t.y - n.y * t.x;
    final cosT = math.cos(theta);
    final sinT = math.sin(theta);
    return _Vec3(
      c.x + (t.x * cosT + bx * sinT) * r + n.x * offset,
      c.y + (t.y * cosT + by * sinT) * r + n.y * offset,
      c.z + (t.z * cosT + bz * sinT) * r + n.z * offset,
    );
  }

  // Draw a ring (filled or stroke) aligned to a face normal
  void _drawRingOnFace(Canvas canvas, Offset center, double scale,
      _Vec3 ringCenter, double radius, _Vec3 normal, Color fillColor, Color strokeColor,
      {bool filled = false}) {
    const segments = 30;
    final points = List.generate(segments, (i) {
      final theta = (i / segments) * math.pi * 2;
      return _radialPoint(ringCenter, radius, theta, normal, 0);
    }).map((p) => _project(p, center, scale)).toList();
    final path = Path()..addPolygon(points, true);
    if (filled && fillColor != Colors.transparent) {
      canvas.drawPath(path, Paint()..color = fillColor);
    }
    canvas.drawPath(path, Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
  }

  List<_Vec3> _componentCenters() {
    final positions = <_Vec3>[];
    final spacing = config.outerDiameter + 0.5;
    final offset = (config.numberOfSubs - 1) / 2;
    for (var i = 0; i < config.numberOfSubs; i++) {
      final xOff = config.arrangement == SubArrangement.rowVertical
          ? 0.0
          : (i - offset) * spacing;
      final yOff = config.arrangement == SubArrangement.rowVertical
          ? (i - offset) * spacing
          : 0.0;
      final xBase = config.subX - (config.width / 2);
      final yBase = (config.height / 2) - config.subZ;
      if (config.mountSide == MountSide.front) {
        positions.add(_v(xBase + xOff, yBase + yOff, externalDepth / 2 + 0.02));
      } else if (config.mountSide == MountSide.back) {
        positions.add(
            _v(xBase + xOff, yBase + yOff, -externalDepth / 2 - 0.02));
      } else if (config.mountSide == MountSide.left) {
        positions.add(
            _v(-config.width / 2 - 0.02, yBase + yOff, xBase + xOff));
      } else if (config.mountSide == MountSide.right) {
        positions.add(
            _v(config.width / 2 + 0.02, yBase + yOff, xBase + xOff));
      } else if (config.mountSide == MountSide.top) {
        positions.add(
            _v(xBase + xOff, -config.height / 2 - 0.02, yBase + yOff));
      } else {
        positions
            .add(_v(xBase + xOff, config.height / 2 + 0.02, yBase + yOff));
      }
    }
    return positions;
  }

  _Vec3 _portCenter() {
    final x = config.portX - (config.width / 2);
    final y = (config.height / 2) - config.portZ;
    switch (config.portPlacement) {
      case PortPlacement.frontBaffle:
        return _v(x, y, externalDepth / 2 + 0.01);
      case PortPlacement.rear:
        return _v(x, y, -externalDepth / 2 - 0.01);
      case PortPlacement.top:
        return _v(x, -config.height / 2 - 0.01, y);
      case PortPlacement.leftFront:
      case PortPlacement.leftRear:
        return _v(
          -config.width / 2 - 0.01,
          y,
          config.portPlacement == PortPlacement.leftFront
              ? externalDepth * 0.2
              : -externalDepth * 0.2,
        );
      case PortPlacement.rightFront:
      case PortPlacement.rightRear:
        return _v(
          config.width / 2 + 0.01,
          y,
          config.portPlacement == PortPlacement.rightFront
              ? externalDepth * 0.2
              : -externalDepth * 0.2,
        );
      case PortPlacement.center:
      case PortPlacement.dualSides:
        return _v(0, y, externalDepth / 2 + 0.01);
    }
  }

  _Vec3 _terminalCenter() {
    final x = config.terminalX - (config.width / 2);
    final y = (config.height / 2) - config.terminalZ;
    return _v(x, y, externalDepth / 2 + 0.02);
  }

  List<_Vec3> _slotPortPoints() {
    final c = _portCenter();
    final halfW = config.slotPortWidth / 2;
    final halfH = (config.height - (config.woodThickness * 2)) / 2;
    switch (config.portPlacement) {
      case PortPlacement.rear:
      case PortPlacement.frontBaffle:
      case PortPlacement.center:
      case PortPlacement.dualSides:
        return [
          _v(c.x - halfW, -halfH, c.z),
          _v(c.x + halfW, -halfH, c.z),
          _v(c.x + halfW, halfH, c.z),
          _v(c.x - halfW, halfH, c.z),
        ];
      case PortPlacement.top:
        return [
          _v(c.x - halfW, c.y, -halfH),
          _v(c.x + halfW, c.y, -halfH),
          _v(c.x + halfW, c.y, halfH),
          _v(c.x - halfW, c.y, halfH),
        ];
      case PortPlacement.leftFront:
      case PortPlacement.leftRear:
      case PortPlacement.rightFront:
      case PortPlacement.rightRear:
        return [
          _v(c.x, c.y - halfH, -halfW),
          _v(c.x, c.y + halfH, -halfW),
          _v(c.x, c.y + halfH, halfW),
          _v(c.x, c.y - halfH, halfW),
        ];
    }
  }

  void _drawBraces(Canvas canvas, Offset center, double scale) {
    if (config.braceType == BraceType.none) return;
    final bracePaint = Paint()
      ..color = const Color(0xFF7C4A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.braceType == BraceType.dowel ? 4 : 2;
    final count = config.braceCount.clamp(1, 6);
    final offsets = List.generate(
      count,
      (i) => count == 1 ? 0.5 : 0.2 + (i * (0.6 / (count - 1))),
    );
    for (final v in offsets) {
      final line = _braceLine(v);
      canvas.drawLine(
        _project(line.$1, center, scale),
        _project(line.$2, center, scale),
        bracePaint,
      );
      if (config.braceType == BraceType.window) {
        final mid = _project(
          _v(
            (line.$1.x + line.$2.x) / 2,
            (line.$1.y + line.$2.y) / 2,
            (line.$1.z + line.$2.z) / 2,
          ),
          center,
          scale,
        );
        canvas.drawCircle(mid, 8, Paint()..color = const Color(0xFFD9A066));
      }
    }
  }

  (_Vec3, _Vec3) _braceLine(double value) {
    final x = -config.width / 2 + (config.width * value);
    final y = -config.height / 2 + (config.height * value);
    switch (config.braceDirection) {
      case BraceDirection.sideToSide:
        return (_v(-config.width / 2, y, 0), _v(config.width / 2, y, 0));
      case BraceDirection.frontToBack:
        return (
          _v(x, 0, -externalDepth / 2),
          _v(x, 0, externalDepth / 2)
        );
      case BraceDirection.topToBottom:
        return (
          _v(x, -config.height / 2, 0),
          _v(x, config.height / 2, 0)
        );
    }
  }

  void _drawRing(Canvas canvas, Offset center, double scale, _Vec3 ringCenter,
      double radius, Color color, bool filled) {
    final points = List.generate(36, (i) {
      final theta = (i / 36) * math.pi * 2;
      if (config.mountSide == MountSide.front ||
          config.mountSide == MountSide.back) {
        return _v(ringCenter.x + math.cos(theta) * radius,
            ringCenter.y + math.sin(theta) * radius, ringCenter.z);
      }
      if (config.mountSide == MountSide.left ||
          config.mountSide == MountSide.right) {
        return _v(ringCenter.x,
            ringCenter.y + math.sin(theta) * radius,
            ringCenter.z + math.cos(theta) * radius);
      }
      return _v(ringCenter.x + math.cos(theta) * radius, ringCenter.y,
          ringCenter.z + math.sin(theta) * radius);
    }).map((p) => _project(p, center, scale)).toList();

    final path = Path()..addPolygon(points, true);
    if (filled) {
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.95));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  Offset _project(_Vec3 point, Offset center, double scale) {
    final rotY = _Vec3(
      (point.x * math.cos(yaw)) - (point.z * math.sin(yaw)),
      point.y,
      (point.x * math.sin(yaw)) + (point.z * math.cos(yaw)),
    );
    final rot = _Vec3(
      rotY.x,
      (rotY.y * math.cos(pitch)) - (rotY.z * math.sin(pitch)),
      (rotY.y * math.sin(pitch)) + (rotY.z * math.cos(pitch)),
    );
    final persp = 1.0 / (1 + (rot.z / 220));
    return Offset(
      center.dx + (rot.x * scale * persp),
      center.dy + (rot.y * scale * persp),
    );
  }

  _Vec3 _v(double x, double y, double z) => _Vec3(x, y, z);
}

// ─── Data Classes ─────────────────────────────────────────────────────────────

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}

class _Face3D {
  const _Face3D(
      {required this.points, required this.color, required this.stroke});
  final List<_Vec3> points;
  final Color color;
  final Color stroke;
}

class _ProjectedFace {
  const _ProjectedFace(
      {required this.points,
      required this.depth,
      required this.color,
      required this.stroke});
  final List<Offset> points;
  final double depth;
  final Color color;
  final Color stroke;
}
