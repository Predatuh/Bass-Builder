import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/subwoofer_presets.dart';
import '../models/enums.dart';
import '../models/subwoofer_preset.dart';
import '../state/bass_builder_controller.dart';
import '../services/port_preset_service.dart';

class ConfigForm extends StatelessWidget {
  const ConfigForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BassBuilderController>();
    final config = controller.config;
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
            _LabeledField(
              label: 'Design Name',
              child: TextFormField(
                initialValue: config.designName,
                onChanged: (value) => controller.updateConfig(config.copyWith(designName: value)),
              ),
            ),
            _LabeledField(
              label: 'Enclosure Type',
              child: DropdownButtonFormField<EnclosureType>(
                value: config.enclosureType,
                items: EnclosureType.values
                    .map((value) => DropdownMenuItem(value: value, child: Text(value.label)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updateConfig(config.copyWith(enclosureType: value));
                  }
                },
              ),
            ),
            _LabeledField(
              label: 'Vehicle Template',
              child: DropdownButtonFormField<String>(
                value: selectedVehicle?.id ?? config.vehicleTemplateId,
                items: controller.vehicleTemplates
                    .map((template) => DropdownMenuItem(value: template.id, child: Text(template.name)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.applyVehicleTemplate(value);
                  }
                },
              ),
            ),
            if (selectedVehicle != null && selectedVehicle.name != 'Custom')
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text(
                  'Max: ${selectedVehicle.width.toStringAsFixed(1)}" W x ${selectedVehicle.height.toStringAsFixed(1)}" H x ${selectedVehicle.maxDepth.toStringAsFixed(1)}" D',
                ),
              ),
            _LabeledField(
              label: 'Manufacturer',
              child: DropdownButtonFormField<String>(
                value: currentManufacturer,
                items: controller.manufacturers
                    .map(
                      (manufacturer) => DropdownMenuItem(
                        value: manufacturer,
                        child: Text(manufacturer),
                      ),
                    )
                    .toList(),
                onChanged: (manufacturer) {
                  if (manufacturer != null) {
                    final presets = controller.presetsForManufacturer(manufacturer);
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
                    .map(
                      (preset) => DropdownMenuItem(
                        value: preset,
                        child: Text('${preset.name} (${preset.size.toStringAsFixed(preset.size.truncateToDouble() == preset.size ? 0 : 1)}")'),
                      ),
                    )
                    .toList(),
                onChanged: (preset) {
                  if (preset != null) {
                    controller.applyPreset(preset);
                  }
                },
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Subs',
                  value: config.numberOfSubs.toDouble(),
                  min: 1,
                  max: 6,
                  divisions: 5,
                  onChanged: (value) => controller.updateConfig(config.copyWith(numberOfSubs: value.round())),
                ),
                _CompactNumberField(
                  label: 'Width',
                  value: config.width,
                  min: 20,
                  max: 72,
                  divisions: 52,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(width: value)),
                ),
                _CompactNumberField(
                  label: 'Height',
                  value: config.height,
                  min: 10,
                  max: 36,
                  divisions: 52,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(height: value)),
                ),
                _CompactNumberField(
                  label: 'Net Volume',
                  value: config.targetNetVolume,
                  min: 0.5,
                  max: 20,
                  divisions: 78,
                  suffix: 'cf',
                  onChanged: (value) => controller.updateConfig(config.copyWith(targetNetVolume: value)),
                ),
                _CompactNumberField(
                  label: 'Tuning',
                  value: config.tuning,
                  min: 20,
                  max: 60,
                  divisions: 80,
                  suffix: 'Hz',
                  onChanged: (value) => controller.updateConfig(config.copyWith(tuning: value)),
                ),
                _CompactNumberField(
                  label: 'Wood',
                  value: config.woodThickness,
                  min: 0.5,
                  max: 1.5,
                  divisions: 8,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(woodThickness: value)),
                ),
              ],
            ),
            if (config.numberOfSubs > 1) ...[  
              const SizedBox(height: 8),
              _CompactNumberField(
                label: 'Inverted Subs',
                value: config.numInverted.toDouble(),
                min: 0,
                max: config.numberOfSubs.toDouble(),
                divisions: config.numberOfSubs,
                onChanged: (value) => controller.updateConfig(config.copyWith(numInverted: value.round())),
              ),
            ],
            const SizedBox(height: 8),
            Text('Tuning Comparison', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Tuning 2',
                  value: config.tuning2 == 0 ? config.tuning : config.tuning2,
                  min: 20,
                  max: 60,
                  divisions: 80,
                  suffix: 'Hz',
                  onChanged: (value) => controller.updateConfig(config.copyWith(tuning2: value)),
                ),
                _CompactNumberField(
                  label: 'Tuning 3',
                  value: config.tuning3 == 0 ? config.tuning : config.tuning3,
                  min: 20,
                  max: 60,
                  divisions: 80,
                  suffix: 'Hz',
                  onChanged: (value) => controller.updateConfig(config.copyWith(tuning3: value)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Port + Mounting', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Port Type',
              child: DropdownButtonFormField<PortType>(
                value: config.portType,
                items: PortType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updateConfig(config.copyWith(portType: value));
                  }
                },
              ),
            ),
            _LabeledField(
              label: 'Mount Side',
              child: DropdownButtonFormField<MountSide>(
                value: config.mountSide,
                items: MountSide.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updateConfig(config.copyWith(mountSide: value));
                  }
                },
              ),
            ),
            _LabeledField(
              label: 'Arrangement',
              child: DropdownButtonFormField<SubArrangement>(
                value: config.arrangement,
                items: SubArrangement.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updateConfig(config.copyWith(arrangement: value));
                  }
                },
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Slot Width',
                  value: config.slotPortWidth,
                  min: 1,
                  max: 12,
                  divisions: 44,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(slotPortWidth: value)),
                ),
                _CompactNumberField(
                  label: 'Slot Height',
                  value: config.slotPortHeight,
                  min: 4,
                  max: 24,
                  divisions: 80,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(slotPortHeight: value)),
                ),
                _CompactNumberField(
                  label: 'Round Port Dia.',
                  value: config.roundPortDiameter,
                  min: 3,
                  max: 12,
                  divisions: 36,
                  suffix: 'in',
                  onChanged: (value) => controller.updateConfig(config.copyWith(roundPortDiameter: value)),
                ),
                _CompactNumberField(
                  label: 'Ports',
                  value: config.numberOfPorts.toDouble(),
                  min: 1,
                  max: 4,
                  divisions: 3,
                  onChanged: (value) => controller.updateConfig(config.copyWith(numberOfPorts: value.round())),
                ),
              ],
            ),
            if (config.portType == PortType.round && portPresets.isNotEmpty) ...[  
              const SizedBox(height: 12),
              _LabeledField(
                label: 'Port Tube Preset',
                child: DropdownButtonFormField<String>(
                  value: config.portPresetId,
                  hint: const Text('Choose a tube preset...'),
                  items: portPresets
                      .map((p) => DropdownMenuItem(value: p.id, child: Text(p.label)))
                      .toList(),
                  onChanged: (value) {
                    final preset = portPresets.firstWhere((p) => p.id == value, orElse: () => portPresets.first);
                    controller.updateConfig(config.copyWith(
                      portPresetId: value,
                      roundPortDiameter: preset.innerDiameter,
                    ));
                  },
                ),
              ),
            ],
            if (config.portType == PortType.slot) ...[  
              const SizedBox(height: 4),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Slot Port Shares Wall'),
                subtitle: const Text('Port uses a box wall as one side'),
                value: config.slotSharedWall,
                onChanged: (value) => controller.updateConfig(config.copyWith(slotSharedWall: value)),
              ),
            ],
            const SizedBox(height: 4),
            _CompactNumberField(
              label: 'Polyfill Density',
              value: config.polyfillDensity,
              min: 0.0,
              max: 1.5,
              divisions: 30,
              suffix: 'lb/cf',
              onChanged: (value) => controller.updateConfig(config.copyWith(polyfillDensity: value)),
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
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateConfig(config.copyWith(bandpassGoal: value));
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text('3D + Hardware', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Transparent Box'),
              value: config.showTransparent,
              onChanged: (value) => controller.updateDisplaySettings(showTransparent: value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Exploded View'),
              value: config.showExploded,
              onChanged: (value) => controller.updateDisplaySettings(showExploded: value),
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Terminal Cup'),
              value: config.showTerminal,
              onChanged: (value) => controller.updateDisplaySettings(showTerminal: value),
            ),
            const SizedBox(height: 8),
            Text('Component Placement', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Port Placement',
              child: DropdownButtonFormField<PortPlacement>(
                value: config.portPlacement,
                items: PortPlacement.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updatePlacement(portPlacement: value);
                  }
                },
              ),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Sub X',
                  value: config.subX,
                  min: 1,
                  max: config.width - 1,
                  divisions: ((config.width - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(subX: value),
                ),
                _CompactNumberField(
                  label: 'Sub Z',
                  value: config.subZ,
                  min: 1,
                  max: config.height - 1,
                  divisions: ((config.height - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(subZ: value),
                ),
                _CompactNumberField(
                  label: 'Port X',
                  value: config.portX,
                  min: 1,
                  max: config.width - 1,
                  divisions: ((config.width - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(portX: value),
                ),
                _CompactNumberField(
                  label: 'Port Z',
                  value: config.portZ,
                  min: 1,
                  max: config.height - 1,
                  divisions: ((config.height - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(portZ: value),
                ),
                _CompactNumberField(
                  label: 'Terminal X',
                  value: config.terminalX,
                  min: 1,
                  max: config.width - 1,
                  divisions: ((config.width - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(terminalX: value),
                ),
                _CompactNumberField(
                  label: 'Terminal Z',
                  value: config.terminalZ,
                  min: 1,
                  max: config.height - 1,
                  divisions: ((config.height - 2) * 2).round().clamp(1, 200),
                  suffix: 'in',
                  onChanged: (value) => controller.updatePlacement(terminalZ: value),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Bracing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _LabeledField(
              label: 'Brace Type',
              child: DropdownButtonFormField<BraceType>(
                value: config.braceType,
                items: BraceType.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updatePlacement(braceType: value);
                  }
                },
              ),
            ),
            _LabeledField(
              label: 'Brace Direction',
              child: DropdownButtonFormField<BraceDirection>(
                value: config.braceDirection,
                items: BraceDirection.values.map((value) => DropdownMenuItem(value: value, child: Text(value.label))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    controller.updatePlacement(braceDirection: value);
                  }
                },
              ),
            ),
            _CompactNumberField(
              label: 'Brace Count',
              value: config.braceCount.toDouble(),
              min: 1,
              max: 6,
              divisions: 5,
              onChanged: (value) => controller.updatePlacement(braceCount: value.round()),
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
                  onChanged: (value) {
                    if (value != null) {
                      controller.updateConfig(config.copyWith(windowBraceVariant: value));
                    }
                  },
                ),
              ),
            ],
            const SizedBox(height: 4),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Override Brace Displacement'),
              subtitle: const Text('Manually enter brace volume instead of auto-calculating'),
              value: config.braceDisplacementOverride,
              onChanged: (value) => controller.updateConfig(config.copyWith(braceDisplacementOverride: value)),
            ),
            if (config.braceDisplacementOverride) ...[  
              _CompactNumberField(
                label: 'Brace Displacement',
                value: config.braceDisplacementManual,
                min: 0,
                max: 5,
                divisions: 100,
                suffix: 'cf',
                onChanged: (value) => controller.updateConfig(config.copyWith(braceDisplacementManual: value)),
              ),
            ],
            const SizedBox(height: 12),
            Text('Per-Face Layers', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Front Layers',
                  value: config.frontLayers.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => controller.updateConfig(config.copyWith(frontLayers: value.round())),
                ),
                _CompactNumberField(
                  label: 'Back Layers',
                  value: config.backLayers.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => controller.updateConfig(config.copyWith(backLayers: value.round())),
                ),
                _CompactNumberField(
                  label: 'Top/Bot Layers',
                  value: config.topBottomLayers.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => controller.updateConfig(config.copyWith(topBottomLayers: value.round())),
                ),
                _CompactNumberField(
                  label: 'Side Layers',
                  value: config.sideLayers.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  onChanged: (value) => controller.updateConfig(config.copyWith(sideLayers: value.round())),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('T/S Parameters', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Use T/S acoustic model'),
              value: config.useTsModel,
              onChanged: (value) => controller.updateConfig(config.copyWith(useTsModel: value)),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _CompactNumberField(
                  label: 'Fs',
                  value: config.fs,
                  min: 20,
                  max: 80,
                  divisions: 120,
                  suffix: 'Hz',
                  onChanged: (value) => controller.updateConfig(config.copyWith(fs: value)),
                ),
                _CompactNumberField(
                  label: 'Qts',
                  value: config.qts,
                  min: 0.2,
                  max: 0.8,
                  divisions: 60,
                  onChanged: (value) => controller.updateConfig(config.copyWith(qts: value)),
                ),
                _CompactNumberField(
                  label: 'Vas',
                  value: config.vas,
                  min: 0.5,
                  max: 12,
                  divisions: 115,
                  suffix: 'cf',
                  onChanged: (value) => controller.updateConfig(config.copyWith(vas: value)),
                ),
                _CompactNumberField(
                  label: 'Xmax',
                  value: config.xmax,
                  min: 5,
                  max: 60,
                  divisions: 110,
                  suffix: 'mm',
                  onChanged: (value) => controller.updateConfig(config.copyWith(xmax: value)),
                ),
              ],
            ),
            if (config.useTsModel) ...[  
              const SizedBox(height: 8),
              Text('Extended T/S Parameters', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CompactNumberField(
                    label: 'Qes',
                    value: config.qes,
                    min: 0.1,
                    max: 1.5,
                    divisions: 140,
                    onChanged: (value) => controller.updateConfig(config.copyWith(qes: value)),
                  ),
                  _CompactNumberField(
                    label: 'Qms',
                    value: config.qms,
                    min: 1.0,
                    max: 20.0,
                    divisions: 190,
                    onChanged: (value) => controller.updateConfig(config.copyWith(qms: value)),
                  ),
                  _CompactNumberField(
                    label: 'Re (Ω)',
                    value: config.re,
                    min: 1.0,
                    max: 8.0,
                    divisions: 70,
                    onChanged: (value) => controller.updateConfig(config.copyWith(re: value)),
                  ),
                  _CompactNumberField(
                    label: 'Le (mH)',
                    value: config.le,
                    min: 0.1,
                    max: 10.0,
                    divisions: 99,
                    onChanged: (value) => controller.updateConfig(config.copyWith(le: value)),
                  ),
                  _CompactNumberField(
                    label: 'BL (Tm)',
                    value: config.bl,
                    min: 5.0,
                    max: 40.0,
                    divisions: 70,
                    onChanged: (value) => controller.updateConfig(config.copyWith(bl: value)),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Text('Cabin Gain', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Cabin Gain Model'),
              subtitle: const Text('Models low-frequency boost from vehicle cabin'),
              value: config.cabinGainEnabled,
              onChanged: (value) => controller.updateConfig(config.copyWith(cabinGainEnabled: value)),
            ),
            if (config.cabinGainEnabled) ...[  
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _CompactNumberField(
                    label: 'Cabin Rolloff',
                    value: config.cabinGainStartFreq,
                    min: 40,
                    max: 150,
                    divisions: 110,
                    suffix: 'Hz',
                    onChanged: (value) => controller.updateConfig(config.copyWith(cabinGainStartFreq: value)),
                  ),
                  _CompactNumberField(
                    label: 'Gain Slope',
                    value: config.cabinGainSlope,
                    min: 1.0,
                    max: 6.0,
                    divisions: 50,
                    suffix: 'dB/oct',
                    onChanged: (value) => controller.updateConfig(config.copyWith(cabinGainSlope: value)),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

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
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _CompactNumberField extends StatelessWidget {
  const _CompactNumberField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
    this.suffix,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String? suffix;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      child: Card(
        color: const Color(0xFFFBF7F1),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('${value.toStringAsFixed(2)}${suffix == null ? '' : ' $suffix'}'),
              Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}