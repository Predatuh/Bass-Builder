import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/vehicle_template.dart';

class VehicleTemplateRepository {
  static Future<List<VehicleTemplate>> loadTemplates() async {
    final raw = await rootBundle.loadString('assets/data/vehicle_templates.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final templates = decoded.entries
        .map(
          (entry) => VehicleTemplate.fromMap(
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
        return left.name.compareTo(right.name);
      });
    return templates;
  }
}