enum EnclosureType {
  ported('Ported'),
  sealed('Sealed'),
  fourthOrderBandpass('4th Order Bandpass'),
  sixthOrderBandpass('6th Order Bandpass');

  const EnclosureType(this.label);
  final String label;
}

enum PortType {
  slot('Slot Port'),
  round('Round Aero Port');

  const PortType(this.label);
  final String label;
}

enum PortPlacement {
  frontBaffle('Front Baffle'),
  leftFront('Left Side - Front'),
  leftRear('Left Side - Rear'),
  rightFront('Right Side - Front'),
  rightRear('Right Side - Rear'),
  top('Top'),
  rear('Rear');

  const PortPlacement(this.label);
  final String label;
}

enum MountSide {
  front('Front'),
  back('Back'),
  left('Left'),
  right('Right'),
  top('Top'),
  bottom('Bottom');

  const MountSide(this.label);
  final String label;
}

enum SubArrangement {
  auto('Auto'),
  rowHorizontal('Row Horizontal'),
  rowVertical('Row Vertical'),
  grid2x2('2x2 Grid'),
  diamond('Diamond');

  const SubArrangement(this.label);
  final String label;
}

enum BraceType {
  none('None'),
  dowel('Wooden Dowel Rod'),
  window('Window Brace'),
  lumber('Lumber Cross Brace'),
  ladder('Ladder Brace'),
  corner('45° Corner Braces');

  const BraceType(this.label);
  final String label;
}

enum BraceDirection {
  sideToSide('Side to Side (X-axis)'),
  frontToBack('Front to Back (Y-axis)'),
  topToBottom('Top to Bottom (Z-axis)');

  const BraceDirection(this.label);
  final String label;
}