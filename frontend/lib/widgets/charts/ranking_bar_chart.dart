import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

/// Grafico de barras horizontais - Top produtos / categorias / vendedores
class RankingBarChart extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String labelKey;
  final String valueKey;
  final NumberFormat? currencyFormat;
  final Color? barColor;
  final int maxItems;

  const RankingBarChart({
    super.key,
    required this.data,
    required this.labelKey,
    required this.valueKey,
    this.currencyFormat,
    this.barColor,
    this.maxItems = 8,
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

    final items = data.take(maxItems).toList();
    final color = barColor ?? AppTheme.primary;
    double maxVal = 0;
    for (final item in items) {
      final v = ((item[valueKey] as num?) ?? 0).toDouble();
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 100;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxVal * 1.15,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => AppTheme.cardSurface,
            tooltipBorder: BorderSide(color: AppTheme.border),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final item = items[group.x.toInt()];
              final label = item[labelKey]?.toString() ?? '';
              final value = ((item[valueKey] as num?) ?? 0).toDouble();
              final formatted = currencyFormat != null
                  ? currencyFormat!.format(value)
                  : value.toStringAsFixed(0);
              return BarTooltipItem(
                '$label\n$formatted',
                TextStyle(color: AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: maxVal / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                final formatted = currencyFormat != null
                    ? _formatCompact(value)
                    : value.toStringAsFixed(0);
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    formatted,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                final label = items[i][labelKey]?.toString() ?? '';
                final display = label.length > 10 ? '${label.substring(0, 9)}...' : label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    display,
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 9),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppTheme.border,
            strokeWidth: 0.5,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(items.length, (i) {
          final value = ((items[i][valueKey] as num?) ?? 0).toDouble();
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: value,
                color: color.withOpacity(0.85),
                width: items.length <= 5 ? 28 : 18,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000) {
      return 'R\$${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$${value.toStringAsFixed(0)}';
  }
}
