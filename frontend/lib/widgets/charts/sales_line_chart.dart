import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

/// Grafico de linha - Faturamento diario
class SalesLineChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final NumberFormat currencyFormat;

  const SalesLineChart({
    super.key,
    required this.data,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Sem dados para o periodo',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    final spots = <FlSpot>[];
    double maxY = 0;
    for (var i = 0; i < data.length; i++) {
      final total = (data[i]['total_vendas'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), total));
      if (total > maxY) maxY = total;
    }

    // Add 10% padding to maxY
    maxY = maxY * 1.1;
    if (maxY == 0) maxY = 100;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.border,
            strokeWidth: 0.5,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    _formatCompact(value),
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: _labelInterval,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                final dateStr = data[i]['data'] as String? ?? '';
                if (dateStr.isEmpty) return const SizedBox.shrink();
                try {
                  final date = DateTime.parse(dateStr);
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('dd/MM').format(date),
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    ),
                  );
                } catch (_) {
                  return const SizedBox.shrink();
                }
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardSurface,
            tooltipBorder: BorderSide(color: AppTheme.border),
            getTooltipItems: (spots) => spots.map((spot) {
              final i = spot.spotIndex;
              final dateStr = data[i]['data'] as String? ?? '';
              String label = '';
              try {
                label = DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr));
              } catch (_) {}
              return LineTooltipItem(
                '$label\n${currencyFormat.format(spot.y)}',
                TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              );
            }).toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            color: AppTheme.primary,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: data.length <= 15,
              getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                radius: 3,
                color: AppTheme.primary,
                strokeWidth: 1.5,
                strokeColor: AppTheme.cardSurface,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: AppTheme.primary.withOpacity(0.08),
            ),
          ),
        ],
      ),
    );
  }

  double get _labelInterval {
    if (data.length <= 7) return 1;
    if (data.length <= 15) return 2;
    if (data.length <= 31) return 5;
    return 7;
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return 'R\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$${value.toStringAsFixed(0)}';
  }
}
