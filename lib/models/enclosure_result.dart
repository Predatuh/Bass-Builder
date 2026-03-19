class MetricTileData {
  const MetricTileData({
    required this.label,
    required this.value,
    this.emphasis,
  });

  final String label;
  final String value;
  final String? emphasis;
}

class CutPanel {
  const CutPanel({
    required this.name,
    required this.quantity,
    required this.width,
    required this.height,
  });

  final String name;
  final int quantity;
  final double width;
  final double height;
}

class ResponsePoint {
  const ResponsePoint({
    required this.frequency,
    required this.spl,
  });

  final double frequency;
  final double spl;
}

class AnalysisMetric {
  const AnalysisMetric({required this.label, required this.value});

  final String label;
  final String value;
}

class EnclosureResult {
  const EnclosureResult({
    required this.internalWidth,
    required this.internalHeight,
    required this.externalDepth,
    required this.internalDepth,
    required this.grossVolume,
    required this.totalSubDisplacement,
    required this.portDisplacement,
    required this.totalDisplacement,
    required this.portClearance,
    required this.boxWeight,
    required this.totalCost,
    required this.portLength,
    required this.portArea,
    required this.slotNeedsBend,
    required this.slotLeg1Length,
    required this.slotLeg2Length,
    required this.sealedChamberVolume,
    required this.portedChamberVolume,
    required this.f3,
    required this.f6,
    required this.qtc,
    required this.fc,
    required this.materialBreakdown,
    required this.metrics,
    required this.analysisMetrics,
    required this.cutPanels,
    required this.responseCurve,
    required this.groupDelayCurve,
    required this.excursionCurve,
    required this.shareQuery,
  });

  final double internalWidth;
  final double internalHeight;
  final double externalDepth;
  final double internalDepth;
  final double grossVolume;
  final double totalSubDisplacement;
  final double portDisplacement;
  final double totalDisplacement;
  final double portClearance;
  final double boxWeight;
  final double totalCost;
  final double portLength;
  final double portArea;
  final bool slotNeedsBend;
  final double slotLeg1Length;
  final double slotLeg2Length;
  final double sealedChamberVolume;
  final double portedChamberVolume;
  final double? f3;
  final double? f6;
  final double? qtc;
  final double? fc;
  final Map<String, double> materialBreakdown;
  final List<MetricTileData> metrics;
  final List<AnalysisMetric> analysisMetrics;
  final List<CutPanel> cutPanels;
  final List<ResponsePoint> responseCurve;
  final List<ResponsePoint> groupDelayCurve;
  final List<ResponsePoint> excursionCurve;
  final String shareQuery;
}