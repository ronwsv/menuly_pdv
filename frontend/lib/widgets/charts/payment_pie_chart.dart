import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

/// Grafico de pizza - Distribuicao por forma de pagamento
class PaymentPieChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final NumberFormat currencyFormat;

  const PaymentPieChart({
    super.key,
    required this.data,
    required this.currencyFormat,
  });

  @override
  State<PaymentPieChart> createState() => _PaymentPieChartState();
}

class _PaymentPieChartState extends State<PaymentPieChart> {
  int _touchedIndex = -1;

  static const _colors = [
    Color(0xFF22c55e), // verde
    Color(0xFF3b82f6), // azul
    Color(0xFFf59e0b), // amarelo
    Color(0xFFef4444), // vermelho
    Color(0xFF8b5cf6), // roxo
    Color(0xFF06b6d4), // ciano
    Color(0xFFec4899), // rosa
    Color(0xFF64748b), // cinza
  ];

  static const _paymentLabels = {
    'dinheiro': 'Dinheiro',
    'pix': 'PIX',
    'credito': 'Credito',
    'debito': 'Debito',
    'crediario': 'Crediario',
    'cheque': 'Cheque',
    'boleto': 'Boleto',
  };

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return Center(
        child: Text(
          'Sem dados para o periodo',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      );
    }

    final total = widget.data.fold<double>(0, (s, e) => s + ((e['total'] as num?) ?? 0).toDouble());

    return Row(
      children: [
        // Pie chart
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (event, response) {
                  setState(() {
                    if (!event.isInterestedForInteractions || response == null || response.touchedSection == null) {
                      _touchedIndex = -1;
                    } else {
                      _touchedIndex = response.touchedSection!.touchedSectionIndex;
                    }
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 35,
              sections: _buildSections(total),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Legend
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(widget.data.length, (i) {
              final item = widget.data[i];
              final forma = item['forma_pagamento'] as String? ?? '';
              final valor = ((item['total'] as num?) ?? 0).toDouble();
              final pct = total > 0 ? (valor / total * 100) : 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _colors[i % _colors.length],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _paymentLabels[forma] ?? forma,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildSections(double total) {
    return List.generate(widget.data.length, (i) {
      final isTouched = i == _touchedIndex;
      final item = widget.data[i];
      final valor = ((item['total'] as num?) ?? 0).toDouble();
      final pct = total > 0 ? (valor / total * 100) : 0;
      final radius = isTouched ? 55.0 : 45.0;

      return PieChartSectionData(
        color: _colors[i % _colors.length],
        value: valor,
        title: isTouched ? widget.currencyFormat.format(valor) : '${pct.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: isTouched ? 11 : 10,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titlePositionPercentageOffset: 0.55,
      );
    });
  }
}
