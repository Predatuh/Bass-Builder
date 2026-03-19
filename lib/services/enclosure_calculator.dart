import 'dart:math' as math;

import '../models/enclosure_config.dart';
import '../models/enums.dart';
import '../models/enclosure_result.dart';

class EnclosureCalculator {
  static EnclosureResult calculate(EnclosureConfig config) {
    final internalWidth = math.max(1.0, config.width - (config.woodThickness * config.sideLayers * 2));
    final internalHeight = math.max(1.0, config.height - (config.woodThickness * config.topBottomLayers * 2));
    final chamberVolumes = _calculateChamberVolumes(config);
    final effectiveNetVolume = config.isBandpass ? chamberVolumes.$1 + chamberVolumes.$2 : config.targetNetVolume;
    final totalSubDisplacement = config.displacementPerSub * config.numberOfSubs;
    final dividerDisplacement = config.isBandpass ? (internalWidth * internalHeight * config.woodThickness) / 1728 : 0.0;
    final portArea = _portArea(config, internalHeight);
    final portLength = _portLength(config, effectiveNetVolume, portArea);
    final portDisplacement = _portDisplacement(portArea, portLength);
    final baffleGain = (math.pi * math.pow(config.cutoutDiameter / 2, 2) * config.woodThickness * config.frontLayers * config.numberOfSubs) / 1728;
    final grossVolume = effectiveNetVolume + totalSubDisplacement + portDisplacement + config.braceDisplacement + dividerDisplacement - baffleGain;

    final internalDepth = (grossVolume * 1728) / (internalWidth * internalHeight);
    final externalDepth = internalDepth + (config.woodThickness * config.frontLayers) + (config.woodThickness * config.backLayers);
    final portClearance = config.isPorted ? math.max(0.0, internalDepth - portLength).toDouble() : internalDepth;
    final totalDisplacement = totalSubDisplacement + portDisplacement + config.braceDisplacement + dividerDisplacement;
    final boxWeight = _boxWeight(config, externalDepth, internalDepth);
    final materialBreakdown = _materialBreakdown(config, externalDepth, internalDepth);
    final totalCost = materialBreakdown.values.fold<double>(0, (sum, value) => sum + value);
    final slotNeedsBend = config.isPorted && config.portType == PortType.slot && portLength > math.max(0.0, internalDepth - config.slotPortWidth);
    final slotLeg1Length = config.portType == PortType.slot ? math.min(portLength, math.max(0.0, internalDepth - config.slotPortWidth)) : 0.0;
    final slotLeg2Length = config.portType == PortType.slot ? math.max(0.0, portLength - slotLeg1Length) : 0.0;
    final responseCurve = _responseCurve(config, effectiveNetVolume);
    final groupDelayCurve = _groupDelayCurve(config);
    final excursionCurve = _excursionCurve(config);
    final f3 = _findThresholdFrequency(responseCurve, -3);
    final f6 = _findThresholdFrequency(responseCurve, -6);
    final qtc = config.enclosureType == EnclosureType.sealed ? config.qts * math.sqrt(1 + config.vas / effectiveNetVolume) : null;
    final fc = config.enclosureType == EnclosureType.sealed ? config.fs * math.sqrt(1 + config.vas / effectiveNetVolume) : null;

    return EnclosureResult(
      internalWidth: internalWidth,
      internalHeight: internalHeight,
      externalDepth: externalDepth,
      internalDepth: internalDepth,
      grossVolume: grossVolume,
      totalSubDisplacement: totalSubDisplacement,
      portDisplacement: portDisplacement,
      totalDisplacement: totalDisplacement,
      portClearance: portClearance,
      boxWeight: boxWeight,
      totalCost: totalCost,
      portLength: portLength,
      portArea: portArea,
      slotNeedsBend: slotNeedsBend,
      slotLeg1Length: slotLeg1Length,
      slotLeg2Length: slotLeg2Length,
      sealedChamberVolume: chamberVolumes.$1,
      portedChamberVolume: chamberVolumes.$2,
      f3: f3,
      f6: f6,
      qtc: qtc,
      fc: fc,
      materialBreakdown: materialBreakdown,
      metrics: [
        MetricTileData(label: 'External Depth', value: '${externalDepth.toStringAsFixed(2)} in'),
        MetricTileData(label: 'Net Volume', value: '${effectiveNetVolume.toStringAsFixed(2)} cf'),
        MetricTileData(label: config.isPorted ? 'Tuning' : 'Type', value: config.isPorted ? '${config.tuning.toStringAsFixed(1)} Hz' : config.enclosureType.label),
        MetricTileData(label: 'Box Weight', value: '${boxWeight.toStringAsFixed(1)} lbs'),
        MetricTileData(label: 'Est. Cost', value: '\$${totalCost.toStringAsFixed(0)}'),
        MetricTileData(
          label: config.isPorted ? 'Port Clearance' : 'Internal Depth',
          value: config.isPorted ? '${portClearance.toStringAsFixed(2)} in' : '${internalDepth.toStringAsFixed(2)} in',
          emphasis: config.isPorted && portClearance < (config.portType == PortType.round ? config.roundPortDiameter / 2 : config.slotPortWidth)
              ? 'Check choke risk'
              : null,
        ),
        if (config.isBandpass) MetricTileData(label: 'Rear Chamber', value: '${chamberVolumes.$1.toStringAsFixed(2)} cf'),
        if (config.isBandpass) MetricTileData(label: 'Front Chamber', value: '${chamberVolumes.$2.toStringAsFixed(2)} cf'),
      ],
      analysisMetrics: [
        AnalysisMetric(label: 'F3 (-3 dB)', value: f3 == null ? '< 20 Hz' : '${f3.toStringAsFixed(1)} Hz'),
        AnalysisMetric(label: 'F6 (-6 dB)', value: f6 == null ? '< 20 Hz' : '${f6.toStringAsFixed(1)} Hz'),
        AnalysisMetric(label: 'Port Length', value: '${portLength.toStringAsFixed(2)} in'),
        AnalysisMetric(label: 'Port Area', value: '${portArea.toStringAsFixed(1)} in²'),
        if (qtc != null) AnalysisMetric(label: 'Qtc', value: qtc.toStringAsFixed(2)),
        if (fc != null) AnalysisMetric(label: 'Fc', value: '${fc.toStringAsFixed(1)} Hz'),
      ],
      cutPanels: _cutPanels(config, externalDepth, internalHeight),
      responseCurve: responseCurve,
      groupDelayCurve: groupDelayCurve,
      excursionCurve: excursionCurve,
      shareQuery: Uri(queryParameters: {
        'w': config.width.toStringAsFixed(2),
        'h': config.height.toStringAsFixed(2),
        'v': effectiveNetVolume.toStringAsFixed(2),
        't': config.tuning.toStringAsFixed(1),
        'subs': '${config.numberOfSubs}',
        'sub': config.subModel,
      }).query,
    );
  }

  static (double, double) _calculateChamberVolumes(EnclosureConfig config) {
    if (config.enclosureType == EnclosureType.fourthOrderBandpass) {
      final targetQtc = 0.707;
      final sealedPerSub = config.qts > 0 && config.qts < targetQtc
          ? math.max(config.vas / ((math.pow(targetQtc / config.qts, 2) - 1).clamp(0.2, double.infinity)), _minSealedBySize(config.cutoutDiameter))
          : math.max(config.vas * 0.7, _minSealedBySize(config.cutoutDiameter));
      final ratio = config.qts < 0.35 ? 2.5 : config.qts < 0.45 ? 2.0 : config.qts < 0.55 ? 1.75 : 1.5;
      final sealed = sealedPerSub * config.numberOfSubs;
      return (sealed, sealed * ratio);
    }

    if (config.enclosureType == EnclosureType.sixthOrderBandpass) {
      final minPerSub = _minBandpassBySize(config.cutoutDiameter);
      final rear = math.max(config.vas * 0.9, minPerSub) * config.numberOfSubs;
      final front = rear * 1.25;
      return (rear, front);
    }

    return (0.0, 0.0);
  }

  static double _minSealedBySize(double cutoutDiameter) {
    if (cutoutDiameter <= 6) {
      return 0.25;
    }
    if (cutoutDiameter <= 8) {
      return 0.4;
    }
    if (cutoutDiameter <= 10) {
      return 0.6;
    }
    if (cutoutDiameter <= 12) {
      return 1.0;
    }
    if (cutoutDiameter <= 15) {
      return 1.75;
    }
    return 2.5;
  }

  static double _minBandpassBySize(double cutoutDiameter) {
    if (cutoutDiameter <= 6) {
      return 0.35;
    }
    if (cutoutDiameter <= 8) {
      return 0.5;
    }
    if (cutoutDiameter <= 10) {
      return 0.8;
    }
    if (cutoutDiameter <= 12) {
      return 1.25;
    }
    if (cutoutDiameter <= 15) {
      return 2.0;
    }
    return 3.0;
  }

  static double _portArea(EnclosureConfig config, double internalHeight) {
    if (!config.isPorted) {
      return 0.0;
    }
    if (config.portType == PortType.slot) {
      return config.slotPortWidth * internalHeight;
    }
    final radius = config.roundPortDiameter / 2;
    return math.pi * radius * radius * config.numberOfPorts;
  }

  static double _portLength(EnclosureConfig config, double effectiveNetVolume, double portArea) {
    if (!config.isPorted) {
      return 0.0;
    }

    if (config.portType == PortType.slot) {
      const cSound = 13504.0;
      const endCorrection = 1.005;
      final acousticLength = (math.pow(cSound, 2) * portArea) /
          (4 * math.pi * math.pi * math.pow(config.tuning, 2) * effectiveNetVolume * 1728);
      return math.max(6.0, acousticLength - (endCorrection * math.sqrt(portArea)));
    }

    return math.max(6.0, ((23562.5 * portArea) / (math.pow(config.tuning, 2) * (effectiveNetVolume * 1728))) - (0.823 * math.sqrt(portArea)));
  }

  static double _portDisplacement(double portArea, double portLength) {
    return (portArea * portLength) / 1728;
  }

  static double _boxWeight(EnclosureConfig config, double externalDepth, double internalDepth) {
    const mdfDensity = 48.0;
    final frontVolume = (config.width * config.height * config.woodThickness * config.frontLayers) / 1728;
    final backVolume = (config.width * config.height * config.woodThickness * config.backLayers) / 1728;
    final topDepth = math.max(1.0, externalDepth - (config.woodThickness * config.frontLayers) - (config.woodThickness * config.backLayers));
    final topVolume = (config.width * topDepth * config.woodThickness * config.topBottomLayers) / 1728;
    final sideVolume = ((config.height - (config.woodThickness * 2 * config.topBottomLayers)) * topDepth * config.woodThickness * config.sideLayers * 2) / 1728;
    return (frontVolume + backVolume + topVolume + topVolume + sideVolume + config.braceDisplacement) * mdfDensity;
  }

  static Map<String, double> _materialBreakdown(EnclosureConfig config, double externalDepth, double internalDepth) {
    final topDepth = math.max(1.0, externalDepth - (config.woodThickness * config.frontLayers) - (config.woodThickness * config.backLayers));
    final frontArea = (config.width * config.height * config.frontLayers) / 144;
    final backArea = (config.width * config.height * config.backLayers) / 144;
    final topArea = (config.width * topDepth * config.topBottomLayers) / 144;
    final sideArea = ((config.height - (config.woodThickness * 2 * config.topBottomLayers)) * topDepth * config.sideLayers * 2) / 144;
    final totalArea = frontArea + backArea + topArea + topArea + sideArea;
    final sheetsNeeded = (totalArea * 1.2 / 32).ceil();
    final carpetYards = (((2 * config.width * config.height) + (2 * config.width * externalDepth) + (2 * config.height * externalDepth)) / 144 / 9).ceil();

    return {
      'MDF Sheets ($sheetsNeeded x)': sheetsNeeded * 45,
      'Wood Glue': 8,
      'Screws': 12,
      'Terminal Cup': 8,
      'Gasket Tape': 6,
      'Carpet ($carpetYards yd)': carpetYards * 15,
    };
  }

  static List<CutPanel> _cutPanels(EnclosureConfig config, double externalDepth, double internalHeight) {
    final topDepth = math.max(1.0, externalDepth - (config.woodThickness * config.frontLayers) - (config.woodThickness * config.backLayers));
    final panels = [
      CutPanel(name: 'Front Baffle', quantity: config.frontLayers, width: config.width, height: config.height),
      CutPanel(name: 'Back Panel', quantity: config.backLayers, width: config.width, height: config.height),
      CutPanel(name: 'Top', quantity: config.topBottomLayers, width: config.width, height: topDepth),
      CutPanel(name: 'Bottom', quantity: config.topBottomLayers, width: config.width, height: topDepth),
      CutPanel(name: 'Left Side', quantity: config.sideLayers, width: internalHeight, height: topDepth),
      CutPanel(name: 'Right Side', quantity: config.sideLayers, width: internalHeight, height: topDepth),
    ];
    if (config.isBandpass) {
      panels.add(CutPanel(name: 'Internal Divider', quantity: 1, width: config.width - (config.woodThickness * 2), height: internalHeight));
    }
    return panels;
  }

  static List<ResponsePoint> _responseCurve(EnclosureConfig config, double effectiveNetVolume) {
    final points = <ResponsePoint>[];
    for (var hz = 10.0; hz <= 150.0; hz += 2.0) {
      final spl = config.enclosureType == EnclosureType.sealed
          ? _sealedResponse(hz, config.fs, config.qts, config.vas, effectiveNetVolume)
          : _portedResponse(hz, config.fs, config.qts, config.vas, effectiveNetVolume, config.tuning);
      points.add(ResponsePoint(frequency: hz, spl: spl));
    }

    return points;
  }

  static List<ResponsePoint> _groupDelayCurve(EnclosureConfig config) {
    final points = <ResponsePoint>[];
    for (var hz = 10.0; hz <= 150.0; hz += 2.0) {
      final fn = hz / (config.isPorted ? config.tuning : config.fs);
      final gd = (1000 / (2 * math.pi * hz)) * (2 * fn / (1 + fn * fn)) * 10;
      points.add(ResponsePoint(frequency: hz, spl: gd));
    }
    return points;
  }

  static List<ResponsePoint> _excursionCurve(EnclosureConfig config) {
    final points = <ResponsePoint>[];
    for (var hz = 10.0; hz <= 150.0; hz += 2.0) {
      final excursionFactor = config.isPorted && hz < config.tuning ? math.pow(config.tuning / hz, 2).toDouble() : 1.0;
      final baseExcursion = config.xmax * math.sqrt(config.power / 1000) * 0.3;
      final excursion = math.min(config.xmax * 2, baseExcursion * excursionFactor);
      points.add(ResponsePoint(frequency: hz, spl: excursion));
    }
    return points;
  }

  static double _sealedResponse(double f, double fs, double qts, double vas, double vb) {
    final qtc = qts * math.sqrt(1 + vas / vb);
    final fc = fs * math.sqrt(1 + vas / vb);
    final fnc = f / fc;
    final response = (fnc * fnc) / math.sqrt(math.pow(1 - (fnc * fnc), 2) + math.pow(fnc / qtc, 2));
    return 20 * (math.log(response + 1e-9) / math.ln10);
  }

  static double _portedResponse(double f, double fs, double qts, double vas, double vb, double fb) {
    if (f < 1) {
      return -40;
    }
    final alpha = vas / vb;
    final h = fb / fs;
    final fn = f / fs;
    final a = math.pow(fn, 4).toDouble();
    final b = (fn * fn) * (((1 + alpha + (1 / (qts * qts))) * (h * h)) + 1);
    final c = math.pow(h, 4).toDouble() + math.pow(fn, 4).toDouble() * math.pow(1 + alpha, 2).toDouble();
    final d = (fn * fn) * (h * h) * (1 + alpha + (1 / (qts * qts)));
    final h2 = (a * a) / (math.pow(c - b, 2) + math.pow(d - (a * h * h / qts), 2) + 1e-9);
    final gain = math.min(1.5, math.sqrt(h2) * 2);
    return 20 * (math.log(gain + 1e-9) / math.ln10);
  }

  static double? _findThresholdFrequency(List<ResponsePoint> points, double threshold) {
    for (final point in points) {
      if (point.spl <= threshold) {
        return point.frequency;
      }
    }
    return null;
  }
}