import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
          child: Scaffold(
            body: SafeArea(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFF4E7D3), Color(0xFFE9F1EA)],
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final configColumn = ListView(
                      padding: const EdgeInsets.all(20),
                      children: const [
                        _HeaderBlock(),
                        SizedBox(height: 16),
                        SaveLoadCard(),
                        SizedBox(height: 16),
                        ConfigForm(),
                      ],
                    );

                    final contentColumn = ListView(
                      padding: const EdgeInsets.fromLTRB(0, 20, 20, 20),
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
                      padding: const EdgeInsets.all(20),
                      children: const [
                        _HeaderBlock(),
                        SizedBox(height: 16),
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
            ),
          ),
        );
      },
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bass Builder', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Flutter port with full Python preset import, expanded enclosure math, rotatable 3D preview, blueprint rendering, and direct export actions.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkbenchTabs extends StatelessWidget {
  const _WorkbenchTabs();

  @override
  Widget build(BuildContext context) {
    return Card(
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
            SizedBox(height: 20),
            SizedBox(
              height: 520,
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
    );
  }
}