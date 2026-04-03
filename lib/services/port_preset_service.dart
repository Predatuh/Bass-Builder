import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/port_preset.dart';

class PortPresetService extends ChangeNotifier {
  List<PortPreset> _presets = const [];

  List<PortPreset> get presets => _presets;

  PortPreset? findById(String id) {
    try {
      return _presets.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/port_presets.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    _presets = decoded.entries
        .map((e) => PortPreset.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)))
        .toList();
    notifyListeners();
  }
}
