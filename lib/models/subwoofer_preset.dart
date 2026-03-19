class SubwooferPreset {
  const SubwooferPreset({
    required this.id,
    required this.name,
    required this.manufacturer,
    required this.size,
    required this.cutout,
    required this.outerDiameter,
    required this.displacement,
    required this.depth,
    required this.fs,
    required this.qts,
    required this.vas,
    required this.xmax,
    required this.sensitivity,
    required this.power,
    this.qes,
    this.qms,
    this.re,
    this.le,
    this.bl,
  });

  factory SubwooferPreset.fromMap(String name, Map<String, dynamic> map) {
    return SubwooferPreset(
      id: _slugify(name),
      name: name,
      manufacturer: _manufacturerFromName(name),
      size: (map['size'] as num?)?.toDouble() ?? 15,
      cutout: (map['cutout'] as num?)?.toDouble() ?? 13.875,
      outerDiameter: (map['od'] as num?)?.toDouble() ?? 15.25,
      displacement: (map['displacement'] as num?)?.toDouble() ?? 0.2,
      depth: (map['depth'] as num?)?.toDouble() ?? 8.5,
      fs: (map['fs'] as num?)?.toDouble() ?? 32,
      qts: (map['qts'] as num?)?.toDouble() ?? 0.45,
      vas: (map['vas'] as num?)?.toDouble() ?? 4.5,
      xmax: (map['xmax'] as num?)?.toDouble() ?? 20,
      sensitivity: (map['sens'] as num?)?.toDouble() ?? 86,
      power: (map['power'] as num?)?.toDouble() ?? 1000,
      qes: (map['qes'] as num?)?.toDouble(),
      qms: (map['qms'] as num?)?.toDouble(),
      re: (map['re'] as num?)?.toDouble(),
      le: (map['le'] as num?)?.toDouble(),
      bl: (map['bl'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String name;
  final String manufacturer;
  final double size;
  final double cutout;
  final double outerDiameter;
  final double displacement;
  final double depth;
  final double fs;
  final double qts;
  final double vas;
  final double xmax;
  final double sensitivity;
  final double power;
  final double? qes;
  final double? qms;
  final double? re;
  final double? le;
  final double? bl;

  static String manufacturerFromName(String name) => _manufacturerFromName(name);

  static String _manufacturerFromName(String name) {
    if (name == 'Custom') {
      return 'Custom';
    }
    const manufacturers = {
      'Sundown': 'Sundown Audio',
      'Skar': 'Skar Audio',
      'SSA': 'Sound Solutions Audio',
      'DC': 'DC Audio',
      'JL': 'JL Audio',
      'Kicker': 'Kicker',
      'Alpine': 'Alpine',
      'Rockford': 'Rockford Fosgate',
      'Pioneer': 'Pioneer',
      'Orion': 'Orion',
      'Fi': 'Fi Audio',
      'American Bass': 'American Bass',
      'Deaf Bonce': 'Deaf Bonce',
      'B2': 'B2 Audio',
    };
    for (final entry in manufacturers.entries) {
      if (name.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return 'Other';
  }

  static String _slugify(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}