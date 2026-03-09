import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Mini sparkline chart para uso em stat cards e dashboard
class MiniLineChart extends StatelessWidget {
  final List<double> values;
  final Color? color;
  final double height;

  const MiniLineChart({
    super.key,
    required this.values,
    this.color,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);

    final lineColor = color ?? AppTheme.primary;
    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));
    double maxY = values.reduce((a, b) => a > b ? a : b);
    if (maxY == 0) maxY = 1;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minY: 0,
          maxY: maxY * 1.1,
          lineTouchData: const LineTouchData(enabled: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: lineColor.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
