import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enclosure_config.dart';
import '../models/enums.dart';
import '../state/bass_builder_controller.dart';

class PreviewSceneCard extends StatefulWidget {
  const PreviewSceneCard({super.key});

  @override
  State<PreviewSceneCard> createState() => _PreviewSceneCardState();
}

class _PreviewSceneCardState extends State<PreviewSceneCard> {
  double _yaw = -0.55;
  double _pitch = 0.45;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('3D Preview', style: Theme.of(context).textTheme.titleLarge)),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Transparent'),
                  selected: config.showTransparent,
                  onSelected: (value) => controller.updateDisplaySettings(showTransparent: value),
                ),
                FilterChip(
                  label: const Text('Exploded'),
                  selected: config.showExploded,
                  onSelected: (value) => controller.updateDisplaySettings(showExploded: value),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Drag to orbit the enclosure. The renderer now projects real 3D geometry with perspective, face sorting, and component placement instead of a flat isometric mock.'),
        const SizedBox(height: 20),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFBF7F1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE7D9C4)),
            ),
            child: GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _yaw += details.focalPointDelta.dx * 0.01;
                  _pitch -= details.focalPointDelta.dy * 0.01;
                  _zoom = (_zoom * details.scale).clamp(0.6, 2.5);
                });
              },
              child: CustomPaint(
                painter: _ScenePainter(
                  config: config,
                  externalDepth: result.externalDepth,
                  yaw: _yaw,
                  pitch: _pitch,
                  zoom: _zoom,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ScenePainter extends CustomPainter {
  const _ScenePainter({
    required this.config,
    required this.externalDepth,
    required this.yaw,
    required this.pitch,
    required this.zoom,
  });

  final EnclosureConfig config;
  final double externalDepth;
  final double yaw;
  final double pitch;
  final double zoom;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 24);
    final scale = math.min(size.width / (config.width + externalDepth), size.height / (config.height + externalDepth)) * 7 * zoom;
    final explode = config.showExploded ? 0.5 : 0.0;
    final faces = _buildFaces(explode);

    final projectedFaces = faces
        .map((face) {
          final points = face.points.map((point) => _project(point, center, scale)).toList();
          final depth = face.points.fold<double>(0, (sum, point) => sum + point.z) / face.points.length;
          return _ProjectedFace(points: points, depth: depth, color: face.color, stroke: face.stroke);
        })
        .toList()
      ..sort((left, right) => left.depth.compareTo(right.depth));

    for (final face in projectedFaces) {
      final path = Path()..addPolygon(face.points, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = face.color.withValues(alpha: config.showTransparent ? 0.22 : 0.92)
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

    final labelPainter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: '${config.width.toStringAsFixed(1)}" × ${config.height.toStringAsFixed(1)}" × ${externalDepth.toStringAsFixed(1)}"',
        style: const TextStyle(color: Color(0xFF111827), fontWeight: FontWeight.w700, fontSize: 16),
      ),
    )..layout();
    labelPainter.paint(canvas, const Offset(20, 16));
  }

  @override
  bool shouldRepaint(covariant _ScenePainter oldDelegate) {
    return oldDelegate.config != config || oldDelegate.externalDepth != externalDepth || oldDelegate.yaw != yaw || oldDelegate.pitch != pitch || oldDelegate.zoom != zoom;
  }

  List<_Face3D> _buildFaces(double explode) {
    final halfW = config.width / 2;
    final halfH = config.height / 2;
    final halfD = externalDepth / 2;
    final xMin = -halfW - explode;
    final xMax = halfW + explode;
    final yMin = -halfH - explode;
    final yMax = halfH + explode;
    final zMin = -halfD - explode;
    final zMax = halfD + explode;

    return [
      _Face3D(points: [_v(xMin, yMin, zMax), _v(xMax, yMin, zMax), _v(xMax, yMax, zMax), _v(xMin, yMax, zMax)], color: const Color(0xFF0F766E), stroke: const Color(0xFF134E4A)),
      _Face3D(points: [_v(xMin, yMin, zMin), _v(xMax, yMin, zMin), _v(xMax, yMax, zMin), _v(xMin, yMax, zMin)], color: const Color(0xFFB1D5CF), stroke: const Color(0xFF134E4A)),
      _Face3D(points: [_v(xMin, yMin, zMin), _v(xMin, yMin, zMax), _v(xMin, yMax, zMax), _v(xMin, yMax, zMin)], color: const Color(0xFFD9A066), stroke: const Color(0xFF7C4A20)),
      _Face3D(points: [_v(xMax, yMin, zMin), _v(xMax, yMin, zMax), _v(xMax, yMax, zMax), _v(xMax, yMax, zMin)], color: const Color(0xFFD9A066), stroke: const Color(0xFF7C4A20)),
      _Face3D(points: [_v(xMin, yMin, zMin), _v(xMax, yMin, zMin), _v(xMax, yMin, zMax), _v(xMin, yMin, zMax)], color: const Color(0xFFF1C48A), stroke: const Color(0xFF7C4A20)),
      _Face3D(points: [_v(xMin, yMax, zMin), _v(xMax, yMax, zMin), _v(xMax, yMax, zMax), _v(xMin, yMax, zMax)], color: const Color(0xFFF1C48A), stroke: const Color(0xFF7C4A20)),
    ];
  }

  void _drawComponentRings(Canvas canvas, Offset center, double scale) {
    final subCenters = _componentCenters();
    for (final subCenter in subCenters) {
      _drawRing(canvas, center, scale, subCenter, config.outerDiameter / 2, const Color(0xFF111827), true);
      _drawRing(canvas, center, scale, subCenter, config.cutoutDiameter / 2, const Color(0xFFE11D48), false);
    }

    if (config.isPorted) {
      final portCenter = _portCenter();
      if (config.portType == PortType.round) {
        _drawRing(canvas, center, scale, portCenter, config.roundPortDiameter / 2, const Color(0xFFC26B2D), true);
      } else {
        final rectPoints = _slotPortPoints().map((point) => _project(point, center, scale)).toList();
        final path = Path()..addPolygon(rectPoints, true);
        canvas.drawPath(path, Paint()..color = const Color(0xFFC26B2D).withValues(alpha: 0.8));
        canvas.drawPath(path, Paint()..color = const Color(0xFF7C4A20)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      }
    }

    if (config.showTerminal) {
      final terminalCenter = _terminalCenter();
      _drawRing(canvas, center, scale, terminalCenter, 1.75, const Color(0xFFEAB308), false);
    }

    _drawBraces(canvas, center, scale);
  }

  List<_Vec3> _componentCenters() {
    final positions = <_Vec3>[];
    final spacing = config.outerDiameter + 0.5;
    final offset = (config.numberOfSubs - 1) / 2;
    for (var index = 0; index < config.numberOfSubs; index++) {
      final xOffset = config.arrangement == SubArrangement.rowVertical ? 0.0 : (index - offset) * spacing;
      final yOffset = config.arrangement == SubArrangement.rowVertical ? (index - offset) * spacing : 0.0;
      final xBase = config.subX - (config.width / 2);
      final yBase = (config.height / 2) - config.subZ;
      if (config.mountSide == MountSide.front) {
        positions.add(_v(xBase + xOffset, yBase + yOffset, externalDepth / 2 + 0.02));
      } else if (config.mountSide == MountSide.back) {
        positions.add(_v(xBase + xOffset, yBase + yOffset, -externalDepth / 2 - 0.02));
      } else if (config.mountSide == MountSide.left) {
        positions.add(_v(-config.width / 2 - 0.02, yBase + yOffset, xBase + xOffset));
      } else if (config.mountSide == MountSide.right) {
        positions.add(_v(config.width / 2 + 0.02, yBase + yOffset, xBase + xOffset));
      } else if (config.mountSide == MountSide.top) {
        positions.add(_v(xBase + xOffset, -config.height / 2 - 0.02, yBase + yOffset));
      } else {
        positions.add(_v(xBase + xOffset, config.height / 2 + 0.02, yBase + yOffset));
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
        return _v(-config.width / 2 - 0.01, y, config.portPlacement == PortPlacement.leftFront ? externalDepth * 0.2 : -externalDepth * 0.2);
      case PortPlacement.rightFront:
      case PortPlacement.rightRear:
        return _v(config.width / 2 + 0.01, y, config.portPlacement == PortPlacement.rightFront ? externalDepth * 0.2 : -externalDepth * 0.2);
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
    final center = _portCenter();
    final halfW = config.slotPortWidth / 2;
    final halfH = (config.height - (config.woodThickness * 2)) / 2;
    switch (config.portPlacement) {
      case PortPlacement.rear:
      case PortPlacement.frontBaffle:
        return [
          _v(center.x - halfW, -halfH, center.z),
          _v(center.x + halfW, -halfH, center.z),
          _v(center.x + halfW, halfH, center.z),
          _v(center.x - halfW, halfH, center.z),
        ];
      case PortPlacement.top:
        return [
          _v(center.x - halfW, center.y, -halfH),
          _v(center.x + halfW, center.y, -halfH),
          _v(center.x + halfW, center.y, halfH),
          _v(center.x - halfW, center.y, halfH),
        ];
      case PortPlacement.leftFront:
      case PortPlacement.leftRear:
      case PortPlacement.rightFront:
      case PortPlacement.rightRear:
        return [
          _v(center.x, center.y - halfH, -halfW),
          _v(center.x, center.y + halfH, -halfW),
          _v(center.x, center.y + halfH, halfW),
          _v(center.x, center.y - halfH, halfW),
        ];
      case PortPlacement.center:
      case PortPlacement.dualSides:
        return [
          _v(center.x - halfW, -halfH, center.z),
          _v(center.x + halfW, -halfH, center.z),
          _v(center.x + halfW, halfH, center.z),
          _v(center.x - halfW, halfH, center.z),
        ];
    }
  }

  void _drawBraces(Canvas canvas, Offset center, double scale) {
    if (config.braceType == BraceType.none) {
      return;
    }

    final bracePaint = Paint()
      ..color = const Color(0xFF7C4A20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = config.braceType == BraceType.dowel ? 4 : 2;
    final count = config.braceCount.clamp(1, 6);
    final offsets = List.generate(count, (index) => count == 1 ? 0.5 : 0.2 + (index * (0.6 / (count - 1))));
    for (final value in offsets) {
      final line = _braceLine(value);
      canvas.drawLine(_project(line.$1, center, scale), _project(line.$2, center, scale), bracePaint);
      if (config.braceType == BraceType.window) {
        final mid = _project(_v((line.$1.x + line.$2.x) / 2, (line.$1.y + line.$2.y) / 2, (line.$1.z + line.$2.z) / 2), center, scale);
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
        return (_v(x, 0, -externalDepth / 2), _v(x, 0, externalDepth / 2));
      case BraceDirection.topToBottom:
        return (_v(x, -config.height / 2, 0), _v(x, config.height / 2, 0));
    }
  }

  void _drawRing(Canvas canvas, Offset center, double scale, _Vec3 ringCenter, double radius, Color color, bool filled) {
    final points = List.generate(36, (index) {
      final theta = (index / 36) * math.pi * 2;
      if (config.mountSide == MountSide.front || config.mountSide == MountSide.back) {
        return _v(ringCenter.x + math.cos(theta) * radius, ringCenter.y + math.sin(theta) * radius, ringCenter.z);
      }
      if (config.mountSide == MountSide.left || config.mountSide == MountSide.right) {
        return _v(ringCenter.x, ringCenter.y + math.sin(theta) * radius, ringCenter.z + math.cos(theta) * radius);
      }
      return _v(ringCenter.x + math.cos(theta) * radius, ringCenter.y, ringCenter.z + math.sin(theta) * radius);
    }).map((point) => _project(point, center, scale)).toList();

    final path = Path()..addPolygon(points, true);
    if (filled) {
      canvas.drawPath(path, Paint()..color = color.withValues(alpha: 0.95));
    }
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  Offset _project(_Vec3 point, Offset center, double scale) {
    final rotatedY = _v(
      (point.x * math.cos(yaw)) - (point.z * math.sin(yaw)),
      point.y,
      (point.x * math.sin(yaw)) + (point.z * math.cos(yaw)),
    );
    final rotated = _v(
      rotatedY.x,
      (rotatedY.y * math.cos(pitch)) - (rotatedY.z * math.sin(pitch)),
      (rotatedY.y * math.sin(pitch)) + (rotatedY.z * math.cos(pitch)),
    );
    final perspective = 1.0 / (1 + (rotated.z / 220));
    return Offset(center.dx + (rotated.x * scale * perspective), center.dy + (rotated.y * scale * perspective));
  }

  _Vec3 _v(double x, double y, double z) => _Vec3(x, y, z);
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);

  final double x;
  final double y;
  final double z;
}

class _Face3D {
  const _Face3D({required this.points, required this.color, required this.stroke});

  final List<_Vec3> points;
  final Color color;
  final Color stroke;
}

class _ProjectedFace {
  const _ProjectedFace({required this.points, required this.depth, required this.color, required this.stroke});

  final List<Offset> points;
  final double depth;
  final Color color;
  final Color stroke;
}