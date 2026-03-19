import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/subwoofer_presets.dart';
import '../models/enclosure_config.dart';
import '../models/enums.dart';
import '../models/enclosure_result.dart';
import '../models/subwoofer_preset.dart';
import '../models/vehicle_template.dart';
import '../services/enclosure_calculator.dart';
import '../services/export_service.dart';
import '../services/subwoofer_repository.dart';
import '../services/vehicle_template_repository.dart';

class BassBuilderController extends ChangeNotifier {
  EnclosureConfig _config = EnclosureConfig.initial();
  EnclosureResult _result = EnclosureCalculator.calculate(EnclosureConfig.initial());
  List<SubwooferPreset> _presets = [customSubwooferPreset];
  List<VehicleTemplate> _vehicleTemplates = const [];
  Map<String, EnclosureConfig> _savedDesigns = {};
  bool _initialized = false;

  EnclosureConfig get config => _config;
  EnclosureResult get result => _result;
  List<SubwooferPreset> get presets => _presets;
  List<VehicleTemplate> get vehicleTemplates => _vehicleTemplates;
  Map<String, EnclosureConfig> get savedDesigns => _savedDesigns;
  bool get initialized => _initialized;
  SubwooferPreset get selectedPreset {
    for (final preset in _presets) {
      if (preset.id == _config.subwooferId) {
        return preset;
      }
    }
    for (final preset in _presets) {
      if (preset.name == _config.subModel) {
        return preset;
      }
    }
    return _presets.firstWhere(
      (preset) => preset.id == customSubwooferPreset.id,
      orElse: () => customSubwooferPreset,
    );
  }

  List<String> get manufacturers {
    final values = _presets.map((preset) => preset.manufacturer).toSet().toList()..sort();
    values.remove('Custom');
    return ['Custom', ...values];
  }

  List<SubwooferPreset> presetsForManufacturer(String manufacturer) {
    return _presets.where((preset) => preset.manufacturer == manufacturer).toList()
      ..sort((left, right) {
        final byName = left.name.compareTo(right.name);
        if (byName != 0) {
          return byName;
        }
        return left.size.compareTo(right.size);
      });
  }

  Future<void> initialize() async {
    _presets = await SubwooferRepository.loadPresets();
    _vehicleTemplates = await VehicleTemplateRepository.loadTemplates();
    final resolvedPreset = selectedPreset;
    _config = _config.copyWith(
      subwooferId: resolvedPreset.id,
      subModel: resolvedPreset.name,
    );
    await _loadSavedDesigns();
    _result = EnclosureCalculator.calculate(_config);
    _initialized = true;
    notifyListeners();
  }

  void updateConfig(EnclosureConfig config) {
    _config = config;
    _result = EnclosureCalculator.calculate(_config);
    notifyListeners();
  }

  void applyPreset(SubwooferPreset preset) {
    updateConfig(
      _config.copyWith(
        subwooferId: preset.id,
        subModel: preset.name,
        cutoutDiameter: preset.cutout,
        outerDiameter: preset.outerDiameter,
        displacementPerSub: preset.displacement,
        mountingDepth: preset.depth,
        fs: preset.fs,
        qts: preset.qts,
        vas: preset.vas,
        xmax: preset.xmax,
        sensitivity: preset.sensitivity,
        power: preset.power,
      ),
    );
  }

  void updateDisplaySettings({bool? showTransparent, bool? showExploded, bool? showTerminal}) {
    updateConfig(
      _config.copyWith(
        showTransparent: showTransparent,
        showExploded: showExploded,
        showTerminal: showTerminal,
      ),
    );
  }

  void applyVehicleTemplate(String templateId) {
    final template = _vehicleTemplates.firstWhere(
      (item) => item.id == templateId,
      orElse: () => const VehicleTemplate(id: 'custom', name: 'Custom', width: 32, height: 20, maxDepth: 40),
    );

    updateConfig(
      _config.copyWith(
        vehicleTemplateId: template.id,
        width: template.width,
        height: template.height,
        subX: template.width * 0.35,
        subZ: template.height * 0.5,
        portX: template.width * 0.7,
        portZ: template.height * 0.5,
        terminalX: template.width * 0.9,
        terminalZ: template.height * 0.15,
      ),
    );
  }

  VehicleTemplate? get selectedVehicleTemplate {
    for (final template in _vehicleTemplates) {
      if (template.id == _config.vehicleTemplateId) {
        return template;
      }
    }
    return null;
  }

  void updatePlacement({
    double? subX,
    double? subZ,
    double? portX,
    double? portZ,
    double? terminalX,
    double? terminalZ,
    PortPlacement? portPlacement,
    BraceType? braceType,
    BraceDirection? braceDirection,
    int? braceCount,
  }) {
    updateConfig(
      _config.copyWith(
        subX: subX,
        subZ: subZ,
        portX: portX,
        portZ: portZ,
        terminalX: terminalX,
        terminalZ: terminalZ,
        portPlacement: portPlacement,
        braceType: braceType,
        braceDirection: braceDirection,
        braceCount: braceCount,
      ),
    );
  }

  Future<void> saveCurrentDesign() async {
    final name = _config.designName.trim().isEmpty ? 'Saved Design' : _config.designName.trim();
    _savedDesigns = {
      ..._savedDesigns,
      name: _config.copyWith(designName: name),
    };
    await _persistSavedDesigns();
    notifyListeners();
  }

  Future<void> loadDesign(String name) async {
    final saved = _savedDesigns[name];
    if (saved == null) {
      return;
    }
    updateConfig(saved);
  }

  Future<void> deleteDesign(String name) async {
    _savedDesigns = Map.of(_savedDesigns)..remove(name);
    await _persistSavedDesigns();
    notifyListeners();
  }

  Future<void> _loadSavedDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('saved_designs');
    if (raw == null || raw.isEmpty) {
      _savedDesigns = {};
      return;
    }
    final map = jsonDecode(raw) as Map<String, dynamic>;
    _savedDesigns = map.map(
      (key, value) => MapEntry(key, EnclosureConfig.fromMap(value as Map<String, dynamic>)),
    );
  }

  Future<void> _persistSavedDesigns() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _savedDesigns.map((key, value) => MapEntry(key, value.toMap())),
    );
    await prefs.setString('saved_designs', encoded);
  }

  Future<String> exportDesignJson() {
    return ExportService.exportDesignJson(_config);
  }

  Future<String> exportCutSheetPdf() {
    return ExportService.exportCutSheetPdf(_config, _result);
  }

  Future<String> exportBlueprintPng() {
    return ExportService.exportBlueprintPng(_config, _result);
  }

  Future<String> exportFrontPanelSvg() {
    return ExportService.exportFrontPanelSvg(_config, _result);
  }
}