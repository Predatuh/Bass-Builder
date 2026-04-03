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
          length: 5,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _LiveTweakSheet(controller: controller),
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
  late double _width;
  late double _height;
  late double _volume;
  late double _tuning;

  @override
  void initState() {
    super.initState();
    final c = widget.controller.config;
    _width = c.width;
    _height = c.height;
    _volume = c.targetNetVolume;
    _tuning = c.tuning;
  }

  void _apply() {
    widget.controller.updateConfig(
      widget.controller.config.copyWith(
        width: _width,
        height: _height,
        targetNetVolume: _volume,
        tuning: _tuning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final result = widget.controller.result;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Live Tweak',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              // Depth readout
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Depth: ${result.externalDepth.toStringAsFixed(2)}"',
                  style: TextStyle(
                      color: cs.primary, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _TweakSlider(
            label: 'Width',
            value: _width,
            min: 20,
            max: 72,
            suffix: 'in',
            cs: cs,
            onChanged: (v) {
              setState(() => _width = v);
              _apply();
            },
          ),
          _TweakSlider(
            label: 'Height',
            value: _height,
            min: 10,
            max: 36,
            suffix: 'in',
            cs: cs,
            onChanged: (v) {
              setState(() => _height = v);
              _apply();
            },
          ),
          _TweakSlider(
            label: 'Net Volume',
            value: _volume,
            min: 0.5,
            max: 20,
            suffix: 'cf',
            cs: cs,
            onChanged: (v) {
              setState(() => _volume = v);
              _apply();
            },
          ),
          _TweakSlider(
            label: 'Tuning',
            value: _tuning,
            min: 20,
            max: 60,
            suffix: 'Hz',
            cs: cs,
            onChanged: (v) {
              setState(() => _tuning = v);
              _apply();
            },
          ),
        ],
      ),
    );
  }
}

class _TweakSlider extends StatelessWidget {
  const _TweakSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.cs,
    required this.onChanged,
  });
  final String label;
  final double value;
  final double min;
  final double max;
  final String suffix;
  final ColorScheme cs;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(
              '${value.toStringAsFixed(1)} $suffix',
              style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// ─── Workbench Tabs ───────────────────────────────────────────────────────────

class _WorkbenchTabs extends StatelessWidget {
  const _WorkbenchTabs();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 580,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              TabBar(
                isScrollable: true,
                tabs: [
                  Tab(text: 'Preview'),
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
                    PreviewSceneCard(),
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
