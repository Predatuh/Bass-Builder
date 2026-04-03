import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/subwoofer_presets.dart';
import '../models/enums.dart';
import '../models/subwoofer_preset.dart';
import '../services/port_preset_service.dart';
import '../state/bass_builder_controller.dart';

class ConfigForm extends StatelessWidget {
  const ConfigForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
    final result = controller.result;
    final selectedPreset = controller.selectedPreset;
    final currentManufacturer = selectedPreset.manufacturer;
    final manufacturerPresets = controller.presetsForManufacturer(currentManufacturer);
    final selectedVehicle = controller.selectedVehicleTemplate;
    final portPresets = context.watch<PortPresetService>().presets;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Configuration', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Design name
            _LabeledField(
              label: 'Design Name',
              child: TextFormField(
                initialValue: config.designName,
                onChanged: (v) => controller.updateConfig(config.copyWith(designName: v)),
              ),
            ),

            _LabeledField(
              label: 'Enclosure Type',
              child: DropdownButtonFormField<EnclosureType>(
                value: config.enclosureType,
                items: EnclosureType.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateConfig(config.copyWith(enclosureType: v));
                },
              ),
            ),

            _LabeledField(
              label: 'Vehicle Template',
              child: DropdownButtonFormField<String>(
                value: selectedVehicle?.id ?? config.vehicleTemplateId,
                items: controller.vehicleTemplates
                    .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.applyVehicleTemplate(v);
                },
              ),
            ),

            if (selectedVehicle != null && selectedVehicle.name != 'Custom')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Max: ${selectedVehicle.width.toStringAsFixed(1)}" W x ${selectedVehicle.height.toStringAsFixed(1)}" H x ${selectedVehicle.maxDepth.toStringAsFixed(1)}" D',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),

            _LabeledField(
              label: 'Manufacturer',
              child: DropdownButtonFormField<String>(
                value: currentManufacturer,
                items: controller.manufacturers
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (m) {
                  if (m != null) {
                    final presets = controller.presetsForManufacturer(m);
                    controller.applyPreset(presets.isEmpty ? customSubwooferPreset : presets.first);
                  }
                },
              ),
            ),

            _LabeledField(
              label: 'Subwoofer Preset',
              child: DropdownButtonFormField<SubwooferPreset>(
                value: selectedPreset,
                items: manufacturerPresets
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(
                            '${p.name} (${p.size.toStringAsFixed(p.size.truncateToDouble() == p.size ? 0 : 1)}")',
                          ),
                        ))
                    .toList(),
                onChanged: (p) {
                  if (p != null) controller.applyPreset(p);
                },
              ),
            ),

            // ── Subwoofer Details (editable) ──────────────────────────────────
            _CollapsibleSection(
              title: 'Subwoofer Details',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    _NumberInput(
                      label: 'Cutout Dia.',
                      value: config.cutoutDiameter,
                      min: 4, max: 20, step: 0.125, suffix: 'in',
                      onChanged: (v) => controller.updateConfig(config.copyWith(cutoutDiameter: v)),
                    ),
                    _NumberInput(
                      label: 'Outer Dia.',
                      value: config.outerDiameter,
                      min: 5, max: 22, step: 0.25, suffix: 'in',
                      onChanged: (v) => controller.updateConfig(config.copyWith(outerDiameter: v)),
                    ),
                    _NumberInput(
                      label: 'Displacement',
                      value: config.displacementPerSub,
                      min: 0.01, max: 1.0, step: 0.01, suffix: 'cf',
                      onChanged: (v) => controller.updateConfig(config.copyWith(displacementPerSub: v)),
                    ),
                    _NumberInput(
                      label: 'Mount Depth',
                      value: config.mountingDepth,
                      min: 2, max: 18, step: 0.25, suffix: 'in',
                      onChanged: (v) => controller.updateConfig(config.copyWith(mountingDepth: v)),
                    ),
                    _NumberInput(
                      label: 'Sensitivity',
                      value: config.sensitivity,
                      min: 78, max: 100, step: 0.5, suffix: 'dB',
                      onChanged: (v) => controller.updateConfig(config.copyWith(sensitivity: v)),
                    ),
                    _NumberInput(
                      label: 'Power',
                      value: config.power,
                      min: 100, max: 10000, step: 100, suffix: 'W', decimals: 0,
                      onChanged: (v) => controller.updateConfig(config.copyWith(power: v)),
                    ),
                  ],
                ),
              ],
            ),

            // ── Core Dimensions ───────────────────────────────────────────────
            const SizedBox(height: 4),
            Text('Dimensions', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                _NumberInput(
                  label: 'Subs',
                  value: config.numberOfSubs.toDouble(),
                  min: 1, max: 6, step: 1, decimals: 0,
                  onChanged: (v) => controller.updateConfig(config.copyWith(numberOfSubs: v.round())),
                ),
                _NumberInput(
                  label: 'Width',
                  value: config.width,
                  min: 20, max: 72, step: 0.5, suffix: 'in',
                  onChanged: (v) => controller.updateConfig(config.copyWith(width: v)),
                ),
                _NumberInput(
                  label: 'Height',
                  value: config.height,
                  min: 10, max: 36, step: 0.5, suffix: 'in',
                  onChanged: (v) => controller.updateConfig(config.copyWith(height: v)),
                ),
                _NumberInput(
                  label: 'Net Volume',
                  value: config.targetNetVolume,
                  min: 0.5, max: 20, step: 0.1, suffix: 'cf',
                  onChanged: (v) => controller.updateConfig(config.copyWith(targetNetVolume: v)),
                ),
                _NumberInput(
                  label: 'Tuning',
                  value: config.tuning,
                  min: 20, max: 60, step: 1, suffix: 'Hz', decimals: 1,
                  onChanged: (v) => controller.updateConfig(config.copyWith(tuning: v)),
                ),
                _NumberInput(
                  label: 'Wood',
                  value: config.woodThickness,
                  min: 0.5, max: 1.5, step: 0.25, suffix: 'in',
                  onChanged: (v) => controller.updateConfig(config.copyWith(woodThickness: v)),
                ),
              ],
            ),

            if (config.numberOfSubs > 1) ...[
              const SizedBox(height: 12),
              _NumberInput(
                label: 'Inverted Subs',
                value: config.numInverted.toDouble(),
                min: 0, max: config.numberOfSubs.toDouble(), step: 1, decimals: 0,
                onChanged: (v) => controller.updateConfig(config.copyWith(numInverted: v.round())),
              ),
            ],

            // Live depth hint
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 4),
              child: _LiveDepthHint(externalDepth: result.externalDepth),
            ),

            // ── Port + Mounting ───────────────────────────────────────────────
            const SizedBox(height: 12),
            Text('Port + Mounting', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            _LabeledField(
              label: 'Port Type',
              child: DropdownButtonFormField<PortType>(
                value: config.portType,
                items: PortType.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateConfig(config.copyWith(portType: v));
                },
              ),
            ),

            // Slot port fields
            if (config.portType == PortType.slot) ...[
              Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  _NumberInput(
                    label: 'Slot Width',
                    value: config.slotPortWidth,
                    min: 1, max: 12, step: 0.25, suffix: 'in',
                    onChanged: (v) => controller.updateConfig(config.copyWith(slotPortWidth: v)),
                  ),
                  _NumberInput(
                    label: 'Slot Height',
                    value: config.slotPortHeight,
                    min: 4, max: 24, step: 0.25, suffix: 'in',
                    onChanged: (v) => controller.updateConfig(config.copyWith(slotPortHeight: v)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Slot Port Shares Wall'),
                subtitle: const Text('Port uses a box wall as one side'),
                value: config.slotSharedWall,
                onChanged: (v) => controller.updateConfig(config.copyWith(slotSharedWall: v)),
              ),
            ],

            // Round port fields
            if (config.portType == PortType.round) ...[
              Wrap(
                spacing: 12,
                runSpacing: 14,
                children: [
                  _NumberInput(
                    label: 'Port Dia.',
                    value: config.roundPortDiameter,
                    min: 3, max: 12, step: 0.5, suffix: 'in',
                    onChanged: (v) => controller.updateConfig(config.copyWith(roundPortDiameter: v)),
                  ),
                  _NumberInput(
                    label: 'Ports',
                    value: config.numberOfPorts.toDouble(),
                    min: 1, max: 4, step: 1, decimals: 0,
                    onChanged: (v) => controller.updateConfig(config.copyWith(numberOfPorts: v.round())),
                  ),
                  _NumberInput(
                    label: 'Depth Inside Box',
                    value: config.portDepthInsideBox,
                    min: 0, max: 24, step: 0.5, suffix: 'in',
                    onChanged: (v) => controller.updateConfig(config.copyWith(portDepthInsideBox: v)),
                  ),
                ],
              ),
              if (portPresets.isNotEmpty) ...[
                const SizedBox(height: 12),
                _LabeledField(
                  label: 'Port Tube Preset',
                  child: DropdownButtonFormField<String>(
                    value: config.portPresetId,
                    hint: const Text('Choose a tube preset...'),
                    items: portPresets
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
                        .toList(),
                    onChanged: (v) {
                      final preset = portPresets.firstWhere(
                        (p) => p.id == v,
                        orElse: () => portPresets.first,
                      );
                      controller.updateConfig(config.copyWith(
                        portPresetId: v,
                        roundPortDiameter: preset.innerDiameter,
                      ));
                    },
                  ),
                ),
              ],
            ],

            const SizedBox(height: 8),
            _NumberInput(
              label: 'Polyfill Density',
              value: config.polyfillDensity,
              min: 0, max: 1.5, step: 0.1, suffix: 'lb/cf',
              onChanged: (v) => controller.updateConfig(config.copyWith(polyfillDensity: v)),
            ),

            if (config.enclosureType == EnclosureType.fourthOrderBandpass ||
                config.enclosureType == EnclosureType.sixthOrderBandpass) ...[
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Bandpass Design Goal',
                child: DropdownButtonFormField<BandpassGoal>(
                  value: config.bandpassGoal,
                  items: BandpassGoal.values
                      .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) controller.updateConfig(config.copyWith(bandpassGoal: v));
                  },
                ),
              ),
            ],

            // ── Mount + Placement ─────────────────────────────────────────────
            const SizedBox(height: 4),
            _LabeledField(
              label: 'Mount Side',
              child: DropdownButtonFormField<MountSide>(
                value: config.mountSide,
                items: MountSide.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateConfig(config.copyWith(mountSide: v));
                },
              ),
            ),
            _LabeledField(
              label: 'Arrangement',
              child: DropdownButtonFormField<SubArrangement>(
                value: config.arrangement,
                items: SubArrangement.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updateConfig(config.copyWith(arrangement: v));
                },
              ),
            ),
            _LabeledField(
              label: 'Port Placement',
              child: DropdownButtonFormField<PortPlacement>(
                value: config.portPlacement,
                items: PortPlacement.values
                    .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) controller.updatePlacement(portPlacement: v);
                },
              ),
            ),

            // ── 3D View Options ───────────────────────────────────────────────
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transparent Box'),
              value: config.showTransparent,
              onChanged: (v) => controller.updateDisplaySettings(showTransparent: v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exploded View'),
              value: config.showExploded,
              onChanged: (v) => controller.updateDisplaySettings(showExploded: v),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Terminal Cup'),
              value: config.showTerminal,
              onChanged: (v) => controller.updateDisplaySettings(showTerminal: v),
            ),

            // ── Bracing (collapsible) ─────────────────────────────────────────
            const SizedBox(height: 4),
            _CollapsibleSection(
              title: 'Bracing',
              children: [
                _LabeledField(
                  label: 'Brace Type',
                  child: DropdownButtonFormField<BraceType>(
                    value: config.braceType,
                    items: BraceType.values
                        .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.updatePlacement(braceType: v);
                    },
                  ),
                ),
                _LabeledField(
                  label: 'Brace Direction',
                  child: DropdownButtonFormField<BraceDirection>(
                    value: config.braceDirection,
                    items: BraceDirection.values
                        .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) controller.updatePlacement(braceDirection: v);
                    },
                  ),
                ),
                _NumberInput(
                  label: 'Brace Count',
                  value: config.braceCount.toDouble(),
                  min: 1, max: 6, step: 1, decimals: 0,
                  onChanged: (v) => controller.updatePlacement(braceCount: v.round()),
                ),
                if (config.braceType == BraceType.window) ...[
                  const SizedBox(height: 12),
                  _LabeledField(
                    label: 'Window Brace Style',
                    child: DropdownButtonFormField<WindowBraceVariant>(
                      value: config.windowBraceVariant,
                      items: WindowBraceVariant.values
                          .map((v) => DropdownMenuItem(value: v, child: Text(v.label)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          controller.updateConfig(config.copyWith(windowBraceVariant: v));
                        }
                      },
                    ),
                  ),
                ],
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Override Brace Displacement'),
                  subtitle: const Text('Manually enter brace volume'),
                  value: config.braceDisplacementOverride,
                  onChanged: (v) =>
                      controller.updateConfig(config.copyWith(braceDisplacementOverride: v)),
                ),
                if (config.braceDisplacementOverride) ...[
                  _NumberInput(
                    label: 'Brace Displacement',
                    value: config.braceDisplacementManual,
                    min: 0, max: 5, step: 0.01, suffix: 'cf',
                    onChanged: (v) =>
                        controller.updateConfig(config.copyWith(braceDisplacementManual: v)),
                  ),
                ],
              ],
            ),

            // ── Per-Face Layers (collapsible) ─────────────────────────────────
            _CollapsibleSection(
              title: 'Per-Face Layers',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    _NumberInput(
                      label: 'Front Layers',
                      value: config.frontLayers.toDouble(),
                      min: 1, max: 5, step: 1, decimals: 0,
                      onChanged: (v) =>
                          controller.updateConfig(config.copyWith(frontLayers: v.round())),
                    ),
                    _NumberInput(
                      label: 'Back Layers',
                      value: config.backLayers.toDouble(),
                      min: 1, max: 5, step: 1, decimals: 0,
                      onChanged: (v) =>
                          controller.updateConfig(config.copyWith(backLayers: v.round())),
                    ),
                    _NumberInput(
                      label: 'Top/Bot',
                      value: config.topBottomLayers.toDouble(),
                      min: 1, max: 5, step: 1, decimals: 0,
                      onChanged: (v) =>
                          controller.updateConfig(config.copyWith(topBottomLayers: v.round())),
                    ),
                    _NumberInput(
                      label: 'Side Layers',
                      value: config.sideLayers.toDouble(),
                      min: 1, max: 5, step: 1, decimals: 0,
                      onChanged: (v) =>
                          controller.updateConfig(config.copyWith(sideLayers: v.round())),
                    ),
                  ],
                ),
              ],
            ),

            // ── T/S Parameters (collapsible) ──────────────────────────────────
            _CollapsibleSection(
              title: 'T/S Parameters',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use T/S acoustic model'),
                  value: config.useTsModel,
                  onChanged: (v) => controller.updateConfig(config.copyWith(useTsModel: v)),
                ),
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    _NumberInput(
                      label: 'Fs', value: config.fs, min: 20, max: 80, step: 1,
                      suffix: 'Hz', decimals: 1,
                      onChanged: (v) => controller.updateConfig(config.copyWith(fs: v)),
                    ),
                    _NumberInput(
                      label: 'Qts', value: config.qts, min: 0.2, max: 0.8, step: 0.01,
                      onChanged: (v) => controller.updateConfig(config.copyWith(qts: v)),
                    ),
                    _NumberInput(
                      label: 'Vas', value: config.vas, min: 0.5, max: 12, step: 0.1,
                      suffix: 'cf',
                      onChanged: (v) => controller.updateConfig(config.copyWith(vas: v)),
                    ),
                    _NumberInput(
                      label: 'Xmax', value: config.xmax, min: 5, max: 60, step: 1,
                      suffix: 'mm', decimals: 1,
                      onChanged: (v) => controller.updateConfig(config.copyWith(xmax: v)),
                    ),
                  ],
                ),
                if (config.useTsModel) ...[
                  const SizedBox(height: 8),
                  Text('Extended T/S', style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: [
                      _NumberInput(
                        label: 'Qes', value: config.qes, min: 0.1, max: 1.5, step: 0.01,
                        onChanged: (v) => controller.updateConfig(config.copyWith(qes: v)),
                      ),
                      _NumberInput(
                        label: 'Qms', value: config.qms, min: 1.0, max: 20.0, step: 0.1,
                        onChanged: (v) => controller.updateConfig(config.copyWith(qms: v)),
                      ),
                      _NumberInput(
                        label: 'Re (Ohm)', value: config.re, min: 1.0, max: 8.0, step: 0.1,
                        onChanged: (v) => controller.updateConfig(config.copyWith(re: v)),
                      ),
                      _NumberInput(
                        label: 'Le (mH)', value: config.le, min: 0.1, max: 10.0, step: 0.1,
                        onChanged: (v) => controller.updateConfig(config.copyWith(le: v)),
                      ),
                      _NumberInput(
                        label: 'BL (Tm)', value: config.bl, min: 5.0, max: 40.0, step: 0.5,
                        onChanged: (v) => controller.updateConfig(config.copyWith(bl: v)),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // ── Cabin Gain (collapsible) ──────────────────────────────────────
            _CollapsibleSection(
              title: 'Cabin Gain',
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable Cabin Gain Model'),
                  subtitle: const Text('Models low-frequency boost from vehicle cabin'),
                  value: config.cabinGainEnabled,
                  onChanged: (v) => controller.updateConfig(config.copyWith(cabinGainEnabled: v)),
                ),
                if (config.cabinGainEnabled) ...[
                  Wrap(
                    spacing: 12,
                    runSpacing: 14,
                    children: [
                      _NumberInput(
                        label: 'Cabin Rolloff',
                        value: config.cabinGainStartFreq,
                        min: 40, max: 150, step: 5, suffix: 'Hz', decimals: 0,
                        onChanged: (v) =>
                            controller.updateConfig(config.copyWith(cabinGainStartFreq: v)),
                      ),
                      _NumberInput(
                        label: 'Gain Slope',
                        value: config.cabinGainSlope,
                        min: 1.0, max: 6.0, step: 0.5, suffix: 'dB/oct',
                        onChanged: (v) =>
                            controller.updateConfig(config.copyWith(cabinGainSlope: v)),
                      ),
                    ],
                  ),
                ],
              ],
            ),

            // ── Tuning Comparison (collapsible) ───────────────────────────────
            _CollapsibleSection(
              title: 'Tuning Comparison',
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: [
                    _NumberInput(
                      label: 'Tuning 2',
                      value: config.tuning2 == 0 ? config.tuning : config.tuning2,
                      min: 20, max: 60, step: 1, suffix: 'Hz', decimals: 1,
                      onChanged: (v) => controller.updateConfig(config.copyWith(tuning2: v)),
                    ),
                    _NumberInput(
                      label: 'Tuning 3',
                      value: config.tuning3 == 0 ? config.tuning : config.tuning3,
                      min: 20, max: 60, step: 1, suffix: 'Hz', decimals: 1,
                      onChanged: (v) => controller.updateConfig(config.copyWith(tuning3: v)),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Live Depth Hint ──────────────────────────────────────────────────────────
class _LiveDepthHint extends StatelessWidget {
  const _LiveDepthHint({required this.externalDepth});
  final double externalDepth;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.straighten_outlined, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            'Calculated depth: ${externalDepth.toStringAsFixed(2)}" (external)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

// ─── Collapsible Section ──────────────────────────────────────────────────────
class _CollapsibleSection extends StatelessWidget {
  const _CollapsibleSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        title: Text(title, style: Theme.of(context).textTheme.titleMedium),
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 8, bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ─── Labeled Field ────────────────────────────────────────────────────────────
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

// ─── Number Input (typeable + step buttons, replaces sliders) ─────────────────
class _NumberInput extends StatefulWidget {
  const _NumberInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.onChanged,
    this.suffix,
    this.decimals = 2,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;
  final String? suffix;
  final int decimals;

  @override
  State<_NumberInput> createState() => _NumberInputState();
}

class _NumberInputState extends State<_NumberInput> {
  late final TextEditingController _ctrl;
  bool _hasFocus = false;

  String _fmt(double v) => v.toStringAsFixed(widget.decimals);

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _fmt(widget.value));
  }

  @override
  void didUpdateWidget(covariant _NumberInput old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !_hasFocus) {
      _ctrl.text = _fmt(widget.value);
    }
  }

  void _commit() {
    final parsed = double.tryParse(_ctrl.text) ?? widget.value;
    final clamped = parsed.clamp(widget.min, widget.max);
    widget.onChanged(clamped);
    _ctrl.text = _fmt(clamped);
  }

  void _stepBy(double delta) {
    final newVal = (widget.value + delta).clamp(widget.min, widget.max);
    widget.onChanged(newVal);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              _StepBtn(
                icon: Icons.remove,
                color: cs.primary,
                onTap: () => _stepBy(-widget.step),
              ),
              Expanded(
                child: Focus(
                  onFocusChange: (focused) {
                    setState(() => _hasFocus = focused);
                    if (!focused) _commit();
                  },
                  child: TextFormField(
                    controller: _ctrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    decoration: InputDecoration(
                      suffix: widget.suffix != null
                          ? Text(widget.suffix!,
                              style: const TextStyle(fontSize: 11))
                          : null,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
                    ),
                    onFieldSubmitted: (_) => _commit(),
                  ),
                ),
              ),
              _StepBtn(
                icon: Icons.add,
                color: cs.primary,
                onTap: () => _stepBy(widget.step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
