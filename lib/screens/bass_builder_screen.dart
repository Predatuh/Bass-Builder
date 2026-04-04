import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/settings_page.dart';
import '../state/app_settings_controller.dart';
import '../state/bass_builder_controller.dart';
import '../widgets/acoustic_chart_card.dart';
import '../widgets/blueprint_card.dart';
import '../widgets/config_form.dart';
import '../widgets/cut_list_card.dart';
import '../widgets/export_card.dart';
import '../widgets/metrics_panel.dart';
import '../widgets/preview_scene_card.dart';
import '../widgets/save_load_card.dart';
class BassBuilderScreen extends StatelessWidget {
  const BassBuilderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BassBuilderController>(
      builder: (context, controller, _) {
        if (!controller.initialized) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return DefaultTabController(
          length: 4,
          child: _ScaffoldBody(controller: controller),
        );
      },
    );
  }
}

class _ScaffoldBody extends StatelessWidget {
  const _ScaffoldBody({required this.controller});
  final BassBuilderController controller;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<AppSettingsController>();
    final isDark = settings.isDark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bass Builder'),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            onPressed: () => settings.toggle(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
      ),
      floatingActionButton: _LiveTweakFab(controller: controller),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 1180;
            final configColumn = ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              children: const [
                SaveLoadCard(),
                SizedBox(height: 16),
                ConfigForm(),
              ],
            );

            final contentColumn = ListView(
              padding: const EdgeInsets.fromLTRB(0, 20, 20, 80),
              children: const [
                MetricsPanel(),
                SizedBox(height: 16),
                PreviewSceneCard(),
                SizedBox(height: 16),
                _WorkbenchTabs(),
              ],
            );

            if (wide) {
              return Row(
                children: [
                  SizedBox(width: 420, child: configColumn),
                  Expanded(child: contentColumn),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
              children: const [
                SaveLoadCard(),
                SizedBox(height: 16),
                ConfigForm(),
                SizedBox(height: 16),
                MetricsPanel(),
                SizedBox(height: 16),
                PreviewSceneCard(),
                SizedBox(height: 16),
                _WorkbenchTabs(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Live Tweak FAB ───────────────────────────────────────────────────────────

class _LiveTweakFab extends StatelessWidget {
  const _LiveTweakFab({required this.controller});
  final BassBuilderController controller;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: 'liveTweak',
      icon: const Icon(Icons.tune),
      label: const Text('Live Tweak'),
      onPressed: () => _showLiveTweakSheet(context),
    );
  }

  void _showLiveTweakSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: controller,
        child: _LiveTweakSheet(controller: controller),
      ),
    );
  }
}

class _LiveTweakSheet extends StatefulWidget {
  const _LiveTweakSheet({required this.controller});
  final BassBuilderController controller;

  @override
  State<_LiveTweakSheet> createState() => _LiveTweakSheetState();
}

class _LiveTweakSheetState extends State<_LiveTweakSheet> {
  late final TextEditingController _widthCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _volumeCtrl;
  late final TextEditingController _tuningCtrl;

  // Mini-preview state
  double _yaw = -0.55;
  double _pitch = 0.45;
  double _zoom = 0.45;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.config;
    _widthCtrl  = TextEditingController(text: c.width.toStringAsFixed(2));
    _heightCtrl = TextEditingController(text: c.height.toStringAsFixed(2));
    _volumeCtrl = TextEditingController(text: c.targetNetVolume.toStringAsFixed(2));
    _tuningCtrl = TextEditingController(text: c.tuning.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    _volumeCtrl.dispose();
    _tuningCtrl.dispose();
    super.dispose();
  }

  void _apply() {
    final c = widget.controller.config;
    widget.controller.updateConfig(c.copyWith(
      width:           double.tryParse(_widthCtrl.text)  ?? c.width,
      height:          double.tryParse(_heightCtrl.text) ?? c.height,
      targetNetVolume: double.tryParse(_volumeCtrl.text) ?? c.targetNetVolume,
      tuning:          double.tryParse(_tuningCtrl.text) ?? c.tuning,
    ));
  }

  Widget _numField(String label, TextEditingController ctrl, String suffix,
      {double step = 0.5}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          IconButton(
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              final v = (double.tryParse(ctrl.text) ?? 0) - step;
              ctrl.text = v.toStringAsFixed(step < 1 ? 2 : 1);
              _apply();
            },
          ),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: cs.primary, fontWeight: FontWeight.w700, fontSize: 14),
              decoration: InputDecoration(
                suffixText: suffix,
                suffixStyle: TextStyle(color: cs.onSurface.withValues(alpha: 0.5), fontSize: 12),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onFieldSubmitted: (_) => _apply(),
              onEditingComplete: _apply,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () {
              final v = (double.tryParse(ctrl.text) ?? 0) + step;
              ctrl.text = v.toStringAsFixed(step < 1 ? 2 : 1);
              _apply();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (ctx, scrollCtrl) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Mini 3D preview with zoom slider
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                GestureDetector(
                  onScaleUpdate: (d) => setState(() {
                    _yaw += d.focalPointDelta.dx * 0.01;
                    _pitch -= d.focalPointDelta.dy * 0.01;
                    if (d.pointerCount >= 2) {
                      _zoom = (_zoom * ((d.scale - 1) * 0.3 + 1)).clamp(0.15, 3.0);
                    }
                  }),
                  child: CustomPaint(
                    painter: ScenePainter(
                      config: config,
                      result: result,
                      externalDepth: result.externalDepth,
                      yaw: _yaw,
                      pitch: _pitch,
                      zoom: _zoom,
                      labelColor: cs.onSurface,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                Positioned(
                  right: 4,
                  top: 4,
                  bottom: 4,
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _zoom.clamp(0.15, 3.0),
                        min: 0.15,
                        max: 3.0,
                        onChanged: (v) => setState(() => _zoom = v),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Fields
          Expanded(
            child: SingleChildScrollView(
              controller: scrollCtrl,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Live Tweak',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Calc depth: ${result.externalDepth.toStringAsFixed(2)}"',
                          style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numField('Width', _widthCtrl, 'in', step: 0.5),
                  _numField('Height', _heightCtrl, 'in', step: 0.5),
                  _numField('Net Volume', _volumeCtrl, 'cf', step: 0.1),
                  _numField('Tuning', _tuningCtrl, 'Hz', step: 1),
                  if (config.isPorted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Port Length', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                              Text('${result.portLength.toStringAsFixed(2)}"',
                                  style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 15)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Port Area', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                              Text('${result.portArea.toStringAsFixed(1)} in²',
                                  style: TextStyle(color: cs.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Port Velocity', style: TextStyle(fontWeight: FontWeight.w600, color: cs.onSurface)),
                              Text('${result.portVelocityFps.toStringAsFixed(1)} fps',
                                  style: TextStyle(
                                    color: result.portVelocityFps > 38 ? cs.error : result.portVelocityFps > 22 ? Colors.orange : cs.primary,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Workbench Tabs ───────────────────────────────────────────────────────────

class _WorkbenchTabs extends StatelessWidget {
  const _WorkbenchTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 750,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Blueprints'),
                  Tab(text: 'Acoustics'),
                  Tab(text: 'Cut List'),
                  Tab(text: 'Export'),
                ],
              ),
              SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    BlueprintCard(),
                    AcousticChartCard(),
                    CutListCard(),
                    ExportCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
