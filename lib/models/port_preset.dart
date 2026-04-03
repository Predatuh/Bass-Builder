class PortPreset {
  const PortPreset({
    required this.id,
    required this.label,
    required this.brand,
    required this.innerDiameter,
    required this.cutoutDiameter,
    required this.outerDiameter,
    required this.displacementPerInch,
    required this.aCoeff,
    required this.bCoeff,
    required this.flareLen,
    required this.wallThickness,
  });

  final String id;
  final String label;
  final String brand;
  final double innerDiameter;
  final double cutoutDiameter;
  final double outerDiameter;
  final double displacementPerInch;
  final double aCoeff;
  final double bCoeff;
  final double flareLen;
  final double wallThickness;

  factory PortPreset.fromMap(String id, Map<String, dynamic> map) {
    return PortPreset(
      id: id,
      label: map['label'] as String,
      brand: map['brand'] as String,
      innerDiameter: (map['innerDiameter'] as num).toDouble(),
      cutoutDiameter: (map['cutoutDiameter'] as num).toDouble(),
      outerDiameter: (map['outerDiameter'] as num).toDouble(),
      displacementPerInch: (map['displacementPerInch'] as num).toDouble(),
      aCoeff: (map['aCoeff'] as num).toDouble(),
      bCoeff: (map['bCoeff'] as num).toDouble(),
      flareLen: (map['flareLen'] as num).toDouble(),
      wallThickness: (map['wallThickness'] as num).toDouble(),
    );
  }
}
