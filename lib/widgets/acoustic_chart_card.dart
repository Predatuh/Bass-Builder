import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class AcousticChartCard extends StatelessWidget {
  const AcousticChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<BassBuilderController>().result;
    final responseSpots = result.responseCurve.map((p) => FlSpot(p.frequency, p.spl)).toList();
    final response2Spots = result.responseCurve2.map((p) => FlSpot(p.frequency, p.spl)).toList();
    final response3Spots = result.responseCurve3.map((p) => FlSpot(p.frequency, p.spl)).toList();
    final cabinGainSpots = result.cabinGainCurve.map((p) => FlSpot(p.frequency, p.spl)).toList();
    final delaySpots = result.groupDelayCurve.map((p) => FlSpot(p.frequency, p.spl)).toList();
    final excursionSpots = result.excursionCurve.map((p) => FlSpot(p.frequency, p.spl)).toList();

    final config = context.read<BassBuilderController>().config;
    final xmaxLine = config.xmax.toDouble();

    return ListView(
      children: [
        Text('Acoustic Analysis', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: result.analysisMetrics
              .map(
                (metric) => Container(
                  width: 160,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBF7F1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE7D9C4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(metric.label, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(metric.value),
                    ],
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        if (response2Spots.isNotEmpty || cabinGainSpots.isNotEmpty || response3Spots.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 16,
              children: [
                _LegendDot(color: const Color(0xFF134E4A), label: 'Tuning 1'),
                if (response2Spots.isNotEmpty) _LegendDot(color: const Color(0xFF7C3AED), label: 'Tuning 2'),
                if (response3Spots.isNotEmpty) _LegendDot(color: const Color(0xFFDB2777), label: 'Tuning 3'),
                if (cabinGainSpots.isNotEmpty) _LegendDot(color: const Color(0xFFCA8A04), label: 'Cabin Gain', dashed: true),
              ],
            ),
          ),
        SizedBox(
          height: 220,
          child: _MultiCurveChart(
            title: 'Frequency Response',
            primarySpots: responseSpots,
            extraCurves: [
              if (response2Spots.isNotEmpty) (response2Spots, const Color(0xFF7C3AED)),
              if (response3Spots.isNotEmpty) (response3Spots, const Color(0xFFDB2777)),
              if (cabinGainSpots.isNotEmpty) (cabinGainSpots, const Color(0xFFCA8A04)),
            ],
            xInterval: 20,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _ChartPanel(
            title: 'Group Delay',
            spots: delaySpots,
            color: const Color(0xFFC26B2D),
            fillColor: const Color(0xFFC26B2D).withValues(alpha: 0.12),
            xInterval: 20,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: _ExcursionChart(
            title: 'Cone Excursion',
            spots: excursionSpots,
            xmaxLine: xmaxLine,
            xInterval: 20,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label, this.dashed = false});
  final Color color;
  final String label;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 3,
          decoration: BoxDecoration(
            color: dashed ? Colors.transparent : color,
            border: dashed ? Border.all(color: color) : null,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

class _MultiCurveChart extends StatelessWidget {
  const _MultiCurveChart({
    required this.title,
    required this.primarySpots,
    required this.extraCurves,
    required this.xInterval,
  });

  final String title;
  final List<FlSpot> primarySpots;
  final List<(List<FlSpot>, Color)> extraCurves;
  final double xInterval;

  @override
  Widget build(BuildContext context) {
    final allSpots = [primarySpots, ...extraCurves.map((c) => c.$1)].expand((s) => s).toList();
    final minY = allSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = allSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: primarySpots.first.x,
              maxX: primarySpots.last.x,
              minY: minY - 2,
              maxY: maxY + 2,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: ((maxY - minY) / 4).clamp(1, 12).toDouble(),
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: primarySpots,
                  isCurved: true,
                  color: const Color(0xFF134E4A),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF134E4A).withValues(alpha: 0.18),
                  ),
                ),
                ...extraCurves.map(
                  (c) => LineChartBarData(
                    spots: c.$1,
                    isCurved: true,
                    color: c.$2,
                    barWidth: 2,
                    dotData: const FlDotData(show: false),
                    dashArray: c.$2 == const Color(0xFFCA8A04) ? [6, 4] : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExcursionChart extends StatelessWidget {
  const _ExcursionChart({
    required this.title,
    required this.spots,
    required this.xmaxLine,
    required this.xInterval,
  });

  final String title;
  final List<FlSpot> spots;
  final double xmaxLine;
  final double xInterval;

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b);
    final chartMax = (maxY + 2).clamp(xmaxLine + 2, double.infinity);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: spots.first.x,
              maxX: spots.last.x,
              minY: minY - 2,
              maxY: chartMax,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: ((chartMax - minY) / 4).clamp(1, 20).toDouble(),
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: xmaxLine,
                    color: const Color(0xFFDC2626),
                    strokeWidth: 2,
                    dashArray: [8, 4],
                    label: HorizontalLineLabel(
                      show: true,
                      labelResolver: (_) => 'Xmax ${xmaxLine.toStringAsFixed(0)} mm',
                      style: const TextStyle(color: Color(0xFFDC2626), fontSize: 11),
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFFE11D48),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFFE11D48).withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartPanel extends StatelessWidget {
  const _ChartPanel({
    required this.title,
    required this.spots,
    required this.color,
    required this.fillColor,
    required this.xInterval,
  });

  final String title;
  final List<FlSpot> spots;
  final Color color;
  final Color fillColor;
  final double xInterval;

  @override
  Widget build(BuildContext context) {
    final minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    final maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: LineChart(
            LineChartData(
              minX: spots.first.x,
              maxX: spots.last.x,
              minY: minY - 2,
              maxY: maxY + 2,
              gridData: const FlGridData(show: true),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: xInterval,
                    getTitlesWidget: (value, meta) => Text(value.toInt().toString()),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: ((maxY - minY) / 4).clamp(1, 12).toDouble(),
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(0)),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: color,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(show: true, color: fillColor),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
