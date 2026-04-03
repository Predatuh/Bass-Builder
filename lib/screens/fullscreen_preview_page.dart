import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';
import '../widgets/preview_scene_card.dart';

class FullscreenPreviewPage extends StatefulWidget {
  const FullscreenPreviewPage({super.key});

  @override
  State<FullscreenPreviewPage> createState() => _FullscreenPreviewPageState();
}

class _FullscreenPreviewPageState extends State<FullscreenPreviewPage> {
  double _yaw = -0.55;
  double _pitch = 0.45;
  double _zoom = 1.0;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D1B2A),
        foregroundColor: Colors.white,
        title: Text(
          '${config.width.toStringAsFixed(1)}" x ${config.height.toStringAsFixed(1)}" x ${result.externalDepth.toStringAsFixed(1)}"',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Zoom in',
            onPressed: () => setState(() => _zoom = (_zoom * 1.2).clamp(0.2, 5.0)),
          ),
          IconButton(
            icon: const Icon(Icons.remove),
            tooltip: 'Zoom out',
            onPressed: () => setState(() => _zoom = (_zoom / 1.2).clamp(0.2, 5.0)),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset view',
            onPressed: () => setState(() { _yaw = -0.55; _pitch = 0.45; _zoom = 1.0; }),
          ),
        ],
      ),
      body: GestureDetector(
        onScaleUpdate: (details) {
          setState(() {
            _yaw += details.focalPointDelta.dx * 0.01;
            _pitch -= details.focalPointDelta.dy * 0.01;
            _zoom = (_zoom * details.scale).clamp(0.2, 5.0);
          });
        },
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
    );
  }
}
