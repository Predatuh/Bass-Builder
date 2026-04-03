import 'dart:convert';

import 'enums.dart';

class EnclosureConfig {
  const EnclosureConfig({
    required this.designName,
    required this.enclosureType,
    required this.portType,
    required this.portPlacement,
    required this.subwooferId,
    required this.subModel,
    required this.vehicleTemplateId,
    required this.numberOfSubs,
    required this.mountSide,
    required this.arrangement,
    required this.width,
    required this.height,
    required this.targetNetVolume,
    required this.tuning,
    required this.woodThickness,
    required this.frontLayers,
    required this.backLayers,
    required this.topBottomLayers,
    required this.sideLayers,
    required this.cutoutDiameter,
    required this.outerDiameter,
    required this.displacementPerSub,
    required this.mountingDepth,
    required this.slotPortWidth,
    required this.slotPortHeight,
    required this.roundPortDiameter,
    required this.numberOfPorts,
    required this.braceDisplacement,
    required this.useTsModel,
    required this.fs,
    required this.qts,
    required this.vas,
    required this.xmax,
    required this.sensitivity,
    required this.power,
    required this.subX,
    required this.subZ,
    required this.portX,
    required this.portZ,
    required this.terminalX,
    required this.terminalZ,
    required this.braceType,
    required this.braceDirection,
    required this.braceCount,
    required this.showTransparent,
    required this.showExploded,
    required this.showTerminal,
    // New fields
    this.numInverted = 0,
    this.polyfillDensity = 0.0,
    this.bandpassGoal = BandpassGoal.dailyDriver,
    this.slotSharedWall = true,
    this.portPresetId,
    this.windowBraceVariant = WindowBraceVariant.single,
    this.braceDisplacementOverride = false,
    this.braceDisplacementManual = 0.0,
    this.cabinGainEnabled = false,
    this.cabinGainStartFreq = 80.0,
    this.cabinGainSlope = 3.0,
    this.qes = 0.52,
    this.qms = 5.5,
    this.re = 3.2,
    this.le = 2.5,
    this.bl = 18.0,
    this.tuning2 = 0.0,
    this.tuning3 = 0.0,
  });

  factory EnclosureConfig.initial() {
    return const EnclosureConfig(
      designName: 'Daily Demo',
      enclosureType: EnclosureType.ported,
      portType: PortType.slot,
      portPlacement: PortPlacement.frontBaffle,
      subwooferId: 'sundown-x15-v3',
      subModel: 'Sundown X-15 v.3',
      vehicleTemplateId: 'custom',
      numberOfSubs: 2,
      mountSide: MountSide.front,
      arrangement: SubArrangement.rowHorizontal,
      width: 32,
      height: 20,
      targetNetVolume: 6.2,
      tuning: 36,
      woodThickness: 0.75,
      frontLayers: 2,
      backLayers: 1,
      topBottomLayers: 1,
      sideLayers: 1,
      cutoutDiameter: 14.2,
      outerDiameter: 15.5,
      displacementPerSub: 0.28,
      mountingDepth: 10.5,
      slotPortWidth: 4,
      slotPortHeight: 18.5,
      roundPortDiameter: 8,
      numberOfPorts: 1,
      braceDisplacement: 0.12,
      useTsModel: true,
      fs: 35,
      qts: 0.4,
      vas: 4.5,
      xmax: 40,
      sensitivity: 85,
      power: 1500,
      subX: 11.2,
      subZ: 10.0,
      portX: 25.6,
      portZ: 10.0,
      terminalX: 28.8,
      terminalZ: 3.0,
      braceType: BraceType.none,
      braceDirection: BraceDirection.frontToBack,
      braceCount: 2,
      showTransparent: false,
      showExploded: false,
      showTerminal: true,
    );
  }

  // New extended T/S and design fields
  final int numInverted;
  final double polyfillDensity;
  final BandpassGoal bandpassGoal;
  final bool slotSharedWall;
  final String? portPresetId;
  final WindowBraceVariant windowBraceVariant;
  final bool braceDisplacementOverride;
  final double braceDisplacementManual;
  final bool cabinGainEnabled;
  final double cabinGainStartFreq;
  final double cabinGainSlope;
  final double qes;
  final double qms;
  final double re;
  final double le;
  final double bl;
  final double tuning2;
  final double tuning3;

  final String designName;
  final EnclosureType enclosureType;
  final PortType portType;
  final PortPlacement portPlacement;
  final String subwooferId;
  final String subModel;
  final String vehicleTemplateId;
  final int numberOfSubs;
  final MountSide mountSide;
  final SubArrangement arrangement;
  final double width;
  final double height;
  final double targetNetVolume;
  final double tuning;
  final double woodThickness;
  final int frontLayers;
  final int backLayers;
  final int topBottomLayers;
  final int sideLayers;
  final double cutoutDiameter;
  final double outerDiameter;
  final double displacementPerSub;
  final double mountingDepth;
  final double slotPortWidth;
  final double slotPortHeight;
  final double roundPortDiameter;
  final int numberOfPorts;
  final double braceDisplacement;
  final bool useTsModel;
  final double fs;
  final double qts;
  final double vas;
  final double xmax;
  final double sensitivity;
  final double power;
  final double subX;
  final double subZ;
  final double portX;
  final double portZ;
  final double terminalX;
  final double terminalZ;
  final BraceType braceType;
  final BraceDirection braceDirection;
  final int braceCount;
  final bool showTransparent;
  final bool showExploded;
  final bool showTerminal;

  bool get isPorted => enclosureType == EnclosureType.ported;
  bool get isBandpass => enclosureType == EnclosureType.fourthOrderBandpass || enclosureType == EnclosureType.sixthOrderBandpass;

  EnclosureConfig copyWith({
    String? designName,
    EnclosureType? enclosureType,
    PortType? portType,
    PortPlacement? portPlacement,
    String? subwooferId,
    String? subModel,
    String? vehicleTemplateId,
    int? numberOfSubs,
    MountSide? mountSide,
    SubArrangement? arrangement,
    double? width,
    double? height,
    double? targetNetVolume,
    double? tuning,
    double? woodThickness,
    int? frontLayers,
    int? backLayers,
    int? topBottomLayers,
    int? sideLayers,
    double? cutoutDiameter,
    double? outerDiameter,
    double? displacementPerSub,
    double? mountingDepth,
    double? slotPortWidth,
    double? slotPortHeight,
    double? roundPortDiameter,
    int? numberOfPorts,
    double? braceDisplacement,
    bool? useTsModel,
    double? fs,
    double? qts,
    double? vas,
    double? xmax,
    double? sensitivity,
    double? power,
    double? subX,
    double? subZ,
    double? portX,
    double? portZ,
    double? terminalX,
    double? terminalZ,
    BraceType? braceType,
    BraceDirection? braceDirection,
    int? braceCount,
    bool? showTransparent,
    bool? showExploded,
    bool? showTerminal,
    int? numInverted,
    double? polyfillDensity,
    BandpassGoal? bandpassGoal,
    bool? slotSharedWall,
    Object? portPresetId = _sentinel,
    WindowBraceVariant? windowBraceVariant,
    bool? braceDisplacementOverride,
    double? braceDisplacementManual,
    bool? cabinGainEnabled,
    double? cabinGainStartFreq,
    double? cabinGainSlope,
    double? qes,
    double? qms,
    double? re,
    double? le,
    double? bl,
    double? tuning2,
    double? tuning3,
  }) {
    return EnclosureConfig(
      designName: designName ?? this.designName,
      enclosureType: enclosureType ?? this.enclosureType,
      portType: portType ?? this.portType,
      portPlacement: portPlacement ?? this.portPlacement,
      subwooferId: subwooferId ?? this.subwooferId,
      subModel: subModel ?? this.subModel,
      vehicleTemplateId: vehicleTemplateId ?? this.vehicleTemplateId,
      numberOfSubs: numberOfSubs ?? this.numberOfSubs,
      mountSide: mountSide ?? this.mountSide,
      arrangement: arrangement ?? this.arrangement,
      width: width ?? this.width,
      height: height ?? this.height,
      targetNetVolume: targetNetVolume ?? this.targetNetVolume,
      tuning: tuning ?? this.tuning,
      woodThickness: woodThickness ?? this.woodThickness,
      frontLayers: frontLayers ?? this.frontLayers,
      backLayers: backLayers ?? this.backLayers,
      topBottomLayers: topBottomLayers ?? this.topBottomLayers,
      sideLayers: sideLayers ?? this.sideLayers,
      cutoutDiameter: cutoutDiameter ?? this.cutoutDiameter,
      outerDiameter: outerDiameter ?? this.outerDiameter,
      displacementPerSub: displacementPerSub ?? this.displacementPerSub,
      mountingDepth: mountingDepth ?? this.mountingDepth,
      slotPortWidth: slotPortWidth ?? this.slotPortWidth,
      slotPortHeight: slotPortHeight ?? this.slotPortHeight,
      roundPortDiameter: roundPortDiameter ?? this.roundPortDiameter,
      numberOfPorts: numberOfPorts ?? this.numberOfPorts,
      braceDisplacement: braceDisplacement ?? this.braceDisplacement,
      useTsModel: useTsModel ?? this.useTsModel,
      fs: fs ?? this.fs,
      qts: qts ?? this.qts,
      vas: vas ?? this.vas,
      xmax: xmax ?? this.xmax,
      sensitivity: sensitivity ?? this.sensitivity,
      power: power ?? this.power,
      subX: subX ?? this.subX,
      subZ: subZ ?? this.subZ,
      portX: portX ?? this.portX,
      portZ: portZ ?? this.portZ,
      terminalX: terminalX ?? this.terminalX,
      terminalZ: terminalZ ?? this.terminalZ,
      braceType: braceType ?? this.braceType,
      braceDirection: braceDirection ?? this.braceDirection,
      braceCount: braceCount ?? this.braceCount,
      showTransparent: showTransparent ?? this.showTransparent,
      showExploded: showExploded ?? this.showExploded,
      showTerminal: showTerminal ?? this.showTerminal,
      numInverted: numInverted ?? this.numInverted,
      polyfillDensity: polyfillDensity ?? this.polyfillDensity,
      bandpassGoal: bandpassGoal ?? this.bandpassGoal,
      slotSharedWall: slotSharedWall ?? this.slotSharedWall,
      portPresetId: portPresetId == _sentinel ? this.portPresetId : portPresetId as String?,
      windowBraceVariant: windowBraceVariant ?? this.windowBraceVariant,
      braceDisplacementOverride: braceDisplacementOverride ?? this.braceDisplacementOverride,
      braceDisplacementManual: braceDisplacementManual ?? this.braceDisplacementManual,
      cabinGainEnabled: cabinGainEnabled ?? this.cabinGainEnabled,
      cabinGainStartFreq: cabinGainStartFreq ?? this.cabinGainStartFreq,
      cabinGainSlope: cabinGainSlope ?? this.cabinGainSlope,
      qes: qes ?? this.qes,
      qms: qms ?? this.qms,
      re: re ?? this.re,
      le: le ?? this.le,
      bl: bl ?? this.bl,
      tuning2: tuning2 ?? this.tuning2,
      tuning3: tuning3 ?? this.tuning3,
    );
  }

  static const Object _sentinel = Object();

  Map<String, dynamic> toMap() {
    return {
      'designName': designName,
      'enclosureType': enclosureType.name,
      'portType': portType.name,
      'portPlacement': portPlacement.name,
      'subwooferId': subwooferId,
      'subModel': subModel,
      'vehicleTemplateId': vehicleTemplateId,
      'numberOfSubs': numberOfSubs,
      'mountSide': mountSide.name,
      'arrangement': arrangement.name,
      'width': width,
      'height': height,
      'targetNetVolume': targetNetVolume,
      'tuning': tuning,
      'woodThickness': woodThickness,
      'frontLayers': frontLayers,
      'backLayers': backLayers,
      'topBottomLayers': topBottomLayers,
      'sideLayers': sideLayers,
      'cutoutDiameter': cutoutDiameter,
      'outerDiameter': outerDiameter,
      'displacementPerSub': displacementPerSub,
      'mountingDepth': mountingDepth,
      'slotPortWidth': slotPortWidth,
      'slotPortHeight': slotPortHeight,
      'roundPortDiameter': roundPortDiameter,
      'numberOfPorts': numberOfPorts,
      'braceDisplacement': braceDisplacement,
      'useTsModel': useTsModel,
      'fs': fs,
      'qts': qts,
      'vas': vas,
      'xmax': xmax,
      'sensitivity': sensitivity,
      'power': power,
      'subX': subX,
      'subZ': subZ,
      'portX': portX,
      'portZ': portZ,
      'terminalX': terminalX,
      'terminalZ': terminalZ,
      'braceType': braceType.name,
      'braceDirection': braceDirection.name,
      'braceCount': braceCount,
      'showTransparent': showTransparent,
      'showExploded': showExploded,
      'showTerminal': showTerminal,
      'numInverted': numInverted,
      'polyfillDensity': polyfillDensity,
      'bandpassGoal': bandpassGoal.name,
      'slotSharedWall': slotSharedWall,
      'portPresetId': portPresetId,
      'windowBraceVariant': windowBraceVariant.name,
      'braceDisplacementOverride': braceDisplacementOverride,
      'braceDisplacementManual': braceDisplacementManual,
      'cabinGainEnabled': cabinGainEnabled,
      'cabinGainStartFreq': cabinGainStartFreq,
      'cabinGainSlope': cabinGainSlope,
      'qes': qes,
      'qms': qms,
      're': re,
      'le': le,
      'bl': bl,
      'tuning2': tuning2,
      'tuning3': tuning3,
    };
  }

  String toJson() => jsonEncode(toMap());

  factory EnclosureConfig.fromMap(Map<String, dynamic> map) {
    return EnclosureConfig(
      designName: map['designName'] as String? ?? 'Saved Design',
      enclosureType: EnclosureType.values.firstWhere(
        (value) => value.name == map['enclosureType'],
        orElse: () => EnclosureType.ported,
      ),
      portType: PortType.values.firstWhere(
        (value) => value.name == map['portType'],
        orElse: () => PortType.slot,
      ),
      portPlacement: PortPlacement.values.firstWhere(
        (value) => value.name == map['portPlacement'],
        orElse: () => PortPlacement.frontBaffle,
      ),
      subwooferId: map['subwooferId'] as String? ?? 'custom',
      subModel: map['subModel'] as String? ?? 'Custom',
      vehicleTemplateId: map['vehicleTemplateId'] as String? ?? 'custom',
      numberOfSubs: (map['numberOfSubs'] as num?)?.toInt() ?? 1,
      mountSide: MountSide.values.firstWhere(
        (value) => value.name == map['mountSide'],
        orElse: () => MountSide.front,
      ),
      arrangement: SubArrangement.values.firstWhere(
        (value) => value.name == map['arrangement'],
        orElse: () => SubArrangement.auto,
      ),
      width: (map['width'] as num?)?.toDouble() ?? 32,
      height: (map['height'] as num?)?.toDouble() ?? 20,
      targetNetVolume: (map['targetNetVolume'] as num?)?.toDouble() ?? 6.2,
      tuning: (map['tuning'] as num?)?.toDouble() ?? 36,
      woodThickness: (map['woodThickness'] as num?)?.toDouble() ?? 0.75,
      frontLayers: (map['frontLayers'] as num?)?.toInt() ?? 1,
      backLayers: (map['backLayers'] as num?)?.toInt() ?? 1,
      topBottomLayers: (map['topBottomLayers'] as num?)?.toInt() ?? 1,
      sideLayers: (map['sideLayers'] as num?)?.toInt() ?? 1,
      cutoutDiameter: (map['cutoutDiameter'] as num?)?.toDouble() ?? 13.875,
      outerDiameter: (map['outerDiameter'] as num?)?.toDouble() ?? 15.25,
      displacementPerSub: (map['displacementPerSub'] as num?)?.toDouble() ?? 0.2,
      mountingDepth: (map['mountingDepth'] as num?)?.toDouble() ?? 8.5,
      slotPortWidth: (map['slotPortWidth'] as num?)?.toDouble() ?? 4,
      slotPortHeight: (map['slotPortHeight'] as num?)?.toDouble() ?? 12,
      roundPortDiameter: (map['roundPortDiameter'] as num?)?.toDouble() ?? 8,
      numberOfPorts: (map['numberOfPorts'] as num?)?.toInt() ?? 1,
      braceDisplacement: (map['braceDisplacement'] as num?)?.toDouble() ?? 0.12,
      useTsModel: map['useTsModel'] as bool? ?? true,
      fs: (map['fs'] as num?)?.toDouble() ?? 32,
      qts: (map['qts'] as num?)?.toDouble() ?? 0.45,
      vas: (map['vas'] as num?)?.toDouble() ?? 4.5,
      xmax: (map['xmax'] as num?)?.toDouble() ?? 20,
      sensitivity: (map['sensitivity'] as num?)?.toDouble() ?? 86,
      power: (map['power'] as num?)?.toDouble() ?? 1000,
      subX: (map['subX'] as num?)?.toDouble() ?? 11.2,
      subZ: (map['subZ'] as num?)?.toDouble() ?? 10.0,
      portX: (map['portX'] as num?)?.toDouble() ?? 25.6,
      portZ: (map['portZ'] as num?)?.toDouble() ?? 10.0,
      terminalX: (map['terminalX'] as num?)?.toDouble() ?? 28.8,
      terminalZ: (map['terminalZ'] as num?)?.toDouble() ?? 3.0,
      braceType: BraceType.values.firstWhere(
        (value) => value.name == map['braceType'],
        orElse: () => BraceType.none,
      ),
      braceDirection: BraceDirection.values.firstWhere(
        (value) => value.name == map['braceDirection'],
        orElse: () => BraceDirection.frontToBack,
      ),
      braceCount: (map['braceCount'] as num?)?.toInt() ?? 2,
      showTransparent: map['showTransparent'] as bool? ?? false,
      showExploded: map['showExploded'] as bool? ?? false,
      showTerminal: map['showTerminal'] as bool? ?? true,
      numInverted: (map['numInverted'] as num?)?.toInt() ?? 0,
      polyfillDensity: (map['polyfillDensity'] as num?)?.toDouble() ?? 0.0,
      bandpassGoal: BandpassGoal.values.firstWhere(
        (v) => v.name == map['bandpassGoal'],
        orElse: () => BandpassGoal.dailyDriver,
      ),
      slotSharedWall: map['slotSharedWall'] as bool? ?? true,
      portPresetId: map['portPresetId'] as String?,
      windowBraceVariant: WindowBraceVariant.values.firstWhere(
        (v) => v.name == map['windowBraceVariant'],
        orElse: () => WindowBraceVariant.single,
      ),
      braceDisplacementOverride: map['braceDisplacementOverride'] as bool? ?? false,
      braceDisplacementManual: (map['braceDisplacementManual'] as num?)?.toDouble() ?? 0.0,
      cabinGainEnabled: map['cabinGainEnabled'] as bool? ?? false,
      cabinGainStartFreq: (map['cabinGainStartFreq'] as num?)?.toDouble() ?? 80.0,
      cabinGainSlope: (map['cabinGainSlope'] as num?)?.toDouble() ?? 3.0,
      qes: (map['qes'] as num?)?.toDouble() ?? 0.52,
      qms: (map['qms'] as num?)?.toDouble() ?? 5.5,
      re: (map['re'] as num?)?.toDouble() ?? 3.2,
      le: (map['le'] as num?)?.toDouble() ?? 2.5,
      bl: (map['bl'] as num?)?.toDouble() ?? 18.0,
      tuning2: (map['tuning2'] as num?)?.toDouble() ?? 0.0,
      tuning3: (map['tuning3'] as num?)?.toDouble() ?? 0.0,
    );
  }

  factory EnclosureConfig.fromJson(String source) {
    return EnclosureConfig.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}