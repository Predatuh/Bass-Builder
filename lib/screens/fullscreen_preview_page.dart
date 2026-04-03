import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/enclosure_config.dart';
import '../state/bass_builder_controller.dart';
import '../widgets/preview_scene_card.dart';

enum _InteractionMode { rotate, place }
enum _PlaceTarget { none, sub, port, terminal }

class FullscreenPreviewPage extends StatefulWidget {
  const FullscreenPreviewPage({super.key});

  @override
  State<FullscreenPreviewPage> createState() => _FullscreenPreviewPageState();
}

class _FullscreenPreviewPageState extends State<FullscreenPreviewPage> {
  double _yaw = -0.55;
  double _pitch = 0.45;
  double _zoom = 1.0;
  _InteractionMode _mode = _InteractionMode.rotate;
  _PlaceTarget _activeTarget = _PlaceTarget.none;
  Size _canvasSize = Size.zero;

  Offset _project(_Vec3 point, Offset center, double scale) {
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

  double _computeScale(EnclosureConfig config, double externalDepth) {
    return math.min(
          _canvasSize.width / (config.width + externalDepth),
          _canvasSize.height / (config.height + externalDepth),
        ) *
        3.5 *
        _zoom;
  }

  Offset _centerOffset() =>
      Offset(_canvasSize.width / 2, _canvasSize.height / 2 + 24);

  _PlaceTarget _hitTest(Offset tap, BassBuilderController controller) {
    final config = controller.config;
    final result = controller.result;
    final externalDepth = result.externalDepth;
    final center = _centerOffset();
    final scale = _computeScale(config, externalDepth);

    final subX = config.subX - config.width / 2;
    final subY = config.height / 2 - config.subZ;
    final subScreen = _project(_Vec3(subX, subY, externalDepth / 2 + 0.02), center, scale);
    if ((tap - subScreen).distance < 24) return _PlaceTarget.sub;

    if (config.isPorted) {
      final px = config.portX - config.width / 2;
      final py = config.height / 2 - config.portZ;
      final portScreen = _project(_Vec3(px, py, externalDepth / 2 + 0.02), center, scale);
      if ((tap - portScreen).distance < 20) return _PlaceTarget.port;
    }

    if (config.showTerminal) {
      final tx = config.terminalX - config.width / 2;
      final ty = config.height / 2 - config.terminalZ;
      final termScreen = _project(_Vec3(tx, ty, externalDepth / 2 + 0.02), center, scale);
      if ((tap - termScreen).distance < 18) return _PlaceTarget.terminal;
    }

    return _PlaceTarget.none;
  }

  double _pxToInches(double px, BassBuilderController controller) {
    final config = controller.config;
    final result = controller.result;
    return px /
        (math.min(
              _canvasSize.width / (config.width + result.externalDepth),
              _canvasSize.height / (config.height + result.externalDepth),
            ) * 3.5 * _zoom);
  }

  void _handleDrag(DragUpdateDetails details, BassBuilderController controller) {
    if (_activeTarget == _PlaceTarget.none) return;
    final config = controller.config;
    final dx = _pxToInches(details.delta.dx, controller);
    final dy = _pxToInches(-details.delta.dy, controller);
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

  String _targetLabel() {
    switch (_activeTarget) {
      case _PlaceTarget.sub: return 'Sub';
      case _PlaceTarget.port: return 'Port';
      case _PlaceTarget.terminal: return 'Terminal';
      case _PlaceTarget.none: return 'Tap to select';
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Text(
          '${config.width.toStringAsFixed(1)}" W  x  ${config.height.toStringAsFixed(1)}" H  x  ${result.externalDepth.toStringAsFixed(1)}" D',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.add), tooltip: 'Zoom in',
              onPressed: () => setState(() => _zoom = (_zoom * 1.2).clamp(0.2, 5.0))),
          IconButton(icon: const Icon(Icons.remove), tooltip: 'Zoom out',
              onPressed: () => setState(() => _zoom = (_zoom / 1.2).clamp(0.2, 5.0))),
          IconButton(icon: const Icon(Icons.refresh), tooltip: 'Reset view',
              onPressed: () => setState(() { _yaw = -0.55; _pitch = 0.45; _zoom = 1.0; })),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          _canvasSize = constraints.biggest;
          return Stack(
            children: [
              GestureDetector(
                onScaleUpdate: _mode == _InteractionMode.rotate
                    ? (details) {
                        setState(() {
                          _yaw += details.focalPointDelta.dx * 0.01;
                          _pitch -= details.focalPointDelta.dy * 0.01;
                          _zoom = (_zoom * details.scale).clamp(0.2, 5.0);
                        });
                      }
                    : null,
                onTapDown: _mode == _InteractionMode.place
                    ? (details) => setState(() =>
                        _activeTarget = _hitTest(details.localPosition, controller))
                    : null,
                onPanUpdate: _mode == _InteractionMode.place
                    ? (details) {
                        setState(() {});
                        _handleDrag(details, controller);
                      }
                    : null,
                child: CustomPaint(
                  painter: ScenePainter(
                    config: config,
                    externalDepth: result.externalDepth,
                    yaw: _yaw,
                    pitch: _pitch,
                    zoom: _zoom,
                    labelColor: Colors.white,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              // Mode chips
              Positioned(
                top: 8,
                left: 8,
                child: Row(
                  children: [
                    _chip('Rotate', Icons.rotate_90_degrees_ccw,
                        _mode == _InteractionMode.rotate, cs, () {
                      setState(() { _mode = _InteractionMode.rotate; _activeTarget = _PlaceTarget.none; });
                    }),
                    const SizedBox(width: 6),
                    _chip('Place', Icons.open_with,
                        _mode == _InteractionMode.place, cs, () {
                      setState(() => _mode = _InteractionMode.place);
                    }),
                  ],
                ),
              ),
              // Place readout
              if (_mode == _InteractionMode.place)
                Positioned(
                  bottom: 16,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
                    ),
                    child: Text(_targetLabel(),
                        style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label, IconData icon, bool selected, ColorScheme cs, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? cs.primary.withValues(alpha: 0.9) : Colors.black54,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.primary.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? cs.onPrimary : cs.primary),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? cs.onPrimary : cs.primary,
            )),
          ],
        ),
      ),
    );
  }
}

class _Vec3 {
  const _Vec3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;
}
