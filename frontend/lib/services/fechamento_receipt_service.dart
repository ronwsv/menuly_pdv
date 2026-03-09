import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FechamentoReceiptService {
  /// [paperWidthMm] accepts 58 or 80 (default).
  static Future<Uint8List> generate({
    required String caixaNome,
    required String dataInicio,
    required String dataFim,
    required List<Map<String, dynamic>> vendas,
    required List<Map<String, dynamic>> movimentos,
    required double totalEntradas,
    required double totalSaidas,
    required double saldoEsperado,
    required NumberFormat currencyFormat,
    int paperWidthMm = 80,
  }) async {
    final pdf = pw.Document();

    final is58 = paperWidthMm == 58;
    final paperWidth = paperWidthMm * PdfPageFormat.mm;
    final margin = (is58 ? 3.0 : 4.0) * PdfPageFormat.mm;

    final bold = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is58 ? 8 : 9);
    final normal = pw.TextStyle(fontSize: is58 ? 7 : 8);
    final small = pw.TextStyle(fontSize: is58 ? 6 : 7);
    final titleStyle =
        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is58 ? 9 : 11);
    final bigBold =
        pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: is58 ? 8 : 10);

    final content = <pw.Widget>[];

    // ── Header ──
    content.add(pw.Center(child: pw.Text('MENULY PDV', style: titleStyle)));
    content.add(_divider());
    content.add(
        pw.Center(child: pw.Text('FECHAMENTO DE CAIXA', style: bigBold)));
    content.add(pw.SizedBox(height: 4));
    content.add(_infoRow('Caixa:', caixaNome, normal));
    content.add(_infoRow('Periodo:', '$dataInicio a $dataFim', normal));
    content.add(_infoRow(
        'Emitido em:',
        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
        normal));

    content.add(_divider());

    // ── Vendas por Forma de Pagamento ──
    if (vendas.isNotEmpty) {
      content.add(pw.Text('VENDAS POR FORMA DE PAGAMENTO', style: bold));
      content.add(pw.SizedBox(height: 4));

      final colQtd = is58 ? 20.0 : 25.0;
      final colTotal = is58 ? 42.0 : 55.0;

      content.add(pw.Row(children: [
        pw.Expanded(child: pw.Text('FORMA', style: bold)),
        pw.SizedBox(
            width: colQtd,
            child: pw.Text('QTD', style: bold,
                textAlign: pw.TextAlign.right)),
        pw.SizedBox(
            width: colTotal,
            child: pw.Text('TOTAL', style: bold,
                textAlign: pw.TextAlign.right)),
      ]));
      content.add(pw.SizedBox(height: 2));

      for (final v in vendas) {
        final forma = _formatFormaPag(v['forma_pagamento']?.toString());
        final qtd = v['quantidade']?.toString() ?? '0';
        final total = _parseDouble(v['total']);

        content.add(pw.Row(children: [
          pw.Expanded(child: pw.Text(forma, style: normal)),
          pw.SizedBox(
              width: colQtd,
              child: pw.Text(qtd, style: normal,
                  textAlign: pw.TextAlign.right)),
          pw.SizedBox(
              width: colTotal,
              child: pw.Text(currencyFormat.format(total), style: normal,
                  textAlign: pw.TextAlign.right)),
        ]));
      }

      content.add(_divider());
    }

    // ── Movimentos por Categoria ──
    if (movimentos.isNotEmpty) {
      content.add(pw.Text('MOVIMENTOS POR CATEGORIA', style: bold));
      content.add(pw.SizedBox(height: 4));

      final colTipo = is58 ? 28.0 : 40.0;
      final colQtdMov = is58 ? 20.0 : 25.0;
      final colTotalMov = is58 ? 42.0 : 55.0;

      content.add(pw.Row(children: [
        pw.SizedBox(width: colTipo, child: pw.Text('TIPO', style: bold)),
        pw.Expanded(child: pw.Text('CATEG.', style: bold)),
        pw.SizedBox(
            width: colQtdMov,
            child: pw.Text('QTD', style: bold,
                textAlign: pw.TextAlign.right)),
        pw.SizedBox(
            width: colTotalMov,
            child: pw.Text('TOTAL', style: bold,
                textAlign: pw.TextAlign.right)),
      ]));
      content.add(pw.SizedBox(height: 2));

      for (final m in movimentos) {
        final tipo = m['tipo'] == 'entrada' ? 'ENT' : 'SAI';
        final categ = _formatCategoria(m['categoria']?.toString());
        final qtd = m['quantidade']?.toString() ?? '0';
        final total = _parseDouble(m['total']);

        content.add(pw.Row(children: [
          pw.SizedBox(width: colTipo, child: pw.Text(tipo, style: normal)),
          pw.Expanded(child: pw.Text(categ, style: normal)),
          pw.SizedBox(
              width: colQtdMov,
              child: pw.Text(qtd, style: normal,
                  textAlign: pw.TextAlign.right)),
          pw.SizedBox(
              width: colTotalMov,
              child: pw.Text(currencyFormat.format(total), style: normal,
                  textAlign: pw.TextAlign.right)),
        ]));
      }

      content.add(_divider());
    }

    // ── Totais ──
    content.add(
        _infoRow('Total Entradas:', currencyFormat.format(totalEntradas), bold));
    content.add(
        _infoRow('Total Saidas:', currencyFormat.format(totalSaidas), bold));
    content.add(pw.SizedBox(height: 4));
    content.add(_infoRow(
        'SALDO ESPERADO:', currencyFormat.format(saldoEsperado), bigBold));

    content.add(_divider());

    // ── Assinatura ──
    content.add(pw.SizedBox(height: 20));
    content.add(pw.Center(
        child: pw.Container(
            width: 150,
            decoration: const pw.BoxDecoration(
                border: pw.Border(
                    top: pw.BorderSide(width: 0.5))))));
    content.add(pw.SizedBox(height: 4));
    content.add(pw.Center(
        child: pw.Text('Assinatura do Operador', style: small)));
    content.add(pw.SizedBox(height: 8));

    // Build PDF
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(
          paperWidth,
          double.infinity,
          marginAll: margin,
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: content,
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _divider() {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Divider(
        height: 0.5,
        thickness: 0.5,
        color: PdfColors.grey600,
      ),
    );
  }

  static pw.Widget _infoRow(String label, String value, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }

  static String _formatFormaPag(String? fp) {
    if (fp == null) return 'OUTROS';
    switch (fp.toLowerCase()) {
      case 'dinheiro':
        return 'DINHEIRO';
      case 'cartao_credito':
        return 'CARTAO CRED.';
      case 'cartao_debito':
        return 'CARTAO DEB.';
      case 'pix':
        return 'PIX';
      default:
        return fp.toUpperCase().replaceAll('_', ' ');
    }
  }

  static String _formatCategoria(String? cat) {
    if (cat == null) return 'Manual';
    switch (cat.toLowerCase()) {
      case 'venda':
        return 'Vendas';
      case 'transferencia':
        return 'Transf.';
      case 'manual':
        return 'Manual';
      case 'importacao_csv':
        return 'Import. CSV';
      default:
        return cat.replaceAll('_', ' ');
    }
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
