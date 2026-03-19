import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/bass_builder_controller.dart';

class AcousticChartCard extends StatelessWidget {
  const AcousticChartCard({super.key});

  @override
  Widget build(BuildContext context) {
    final result = context.watch<BassBuilderController>().result;
    final responseSpots = result.responseCurve.map((point) => FlSpot(point.frequency, point.spl)).toList();
    final delaySpots = result.groupDelayCurve.map((point) => FlSpot(point.frequency, point.spl)).toList();
    final excursionSpots = result.excursionCurve.map((point) => FlSpot(point.frequency, point.spl)).toList();

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
        SizedBox(
          height: 220,
          child: _ChartPanel(
            title: 'Frequency Response',
            spots: responseSpots,
            color: const Color(0xFF134E4A),
            fillColor: const Color(0xFF134E4A).withValues(alpha: 0.18),
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
          child: _ChartPanel(
            title: 'Cone Excursion',
            spots: excursionSpots,
            color: const Color(0xFFE11D48),
            fillColor: const Color(0xFFE11D48).withValues(alpha: 0.12),
            xInterval: 20,
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