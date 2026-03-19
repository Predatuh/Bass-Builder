class VehicleTemplate {
  const VehicleTemplate({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.maxDepth,
  });

  factory VehicleTemplate.fromMap(String name, Map<String, dynamic> map) {
    return VehicleTemplate(
      id: name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), ''),
      name: name,
      width: (map['width'] as num?)?.toDouble() ?? 32,
      height: (map['height'] as num?)?.toDouble() ?? 20,
      maxDepth: (map['max_depth'] as num?)?.toDouble() ?? 40,
    );
  }

  final String id;
  final String name;
  final double width;
  final double height;
  final double maxDepth;
}