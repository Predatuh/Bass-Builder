import 'dart:convert';

import 'package:flutter/services.dart';

import '../data/subwoofer_presets.dart';
import '../models/subwoofer_preset.dart';

class SubwooferRepository {
  static Future<List<SubwooferPreset>> loadPresets() async {
    final raw = await rootBundle.loadString('assets/data/subwoofers.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final presets = decoded.entries
        .map(
          (entry) => SubwooferPreset.fromMap(
            entry.key,
            Map<String, dynamic>.from(entry.value as Map),
          ),
        )
        .toList()
      ..sort((left, right) {
        if (left.name == 'Custom') {
          return -1;
        }
        if (right.name == 'Custom') {
          return 1;
        }
        final manufacturerOrder = left.manufacturer.compareTo(right.manufacturer);
        if (manufacturerOrder != 0) {
          return manufacturerOrder;
        }
        final nameOrder = left.name.compareTo(right.name);
        if (nameOrder != 0) {
          return nameOrder;
        }
        return left.size.compareTo(right.size);
      });

    final hasCustom = presets.any((preset) => preset.id == customSubwooferPreset.id);
    if (!hasCustom) {
      presets.insert(0, customSubwooferPreset);
    }
    return presets;
  }
}