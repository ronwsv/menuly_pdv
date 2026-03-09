import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReceiptService {
  static final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  /// [paperWidthMm] accepts 58 or 80 (default).
  static Future<Uint8List> generateReceipt({
    required Map<String, dynamic> vendaData,
    required String operador,
    Map<String, dynamic>? emitente,
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

    // Parse data
    final itens = (vendaData['itens'] as List?) ?? [];
    final numero = vendaData['numero']?.toString() ?? '';
    final criadoEm = vendaData['criado_em']?.toString() ?? '';
    final subtotal = _parseDouble(vendaData['subtotal']);
    final descontoValor = _parseDouble(vendaData['desconto_valor']);
    final total = _parseDouble(vendaData['total']);
    final formaPagamento = vendaData['forma_pagamento']?.toString() ?? '';
    final valorRecebido = _parseDouble(vendaData['valor_recebido']);
    final troco = _parseDouble(vendaData['troco']);

    // Format date
    String dataFormatada = criadoEm;
    try {
      final dt = DateTime.parse(criadoEm);
      dataFormatada = DateFormat('dd/MM/yyyy HH:mm:ss').format(dt);
    } catch (_) {}

    // Payment labels
    String pagLabel(String forma) => switch (forma) {
          'dinheiro' => 'DINHEIRO',
          'cartao' => 'CARTAO',
          'cartao_credito' => 'CARTAO CREDITO',
          'cartao_debito' => 'CARTAO DEBITO',
          'pix' => 'PIX',
          'crediario' => 'CREDIARIO',
          _ => forma.toUpperCase(),
        };
    final pagamentos = vendaData['pagamentos'] as List?;

    // Build content widgets
    final content = <pw.Widget>[];

    // ── Header: Company info ──
    if (emitente != null) {
      final nomeFantasia =
          emitente['nome_fantasia']?.toString() ?? emitente['razao_social']?.toString() ?? '';
      final cnpj = emitente['cnpj']?.toString() ?? '';
      final endereco = emitente['endereco']?.toString() ?? '';
      final numero_ = emitente['numero']?.toString() ?? '';
      final bairro = emitente['bairro']?.toString() ?? '';
      final cidade = emitente['cidade']?.toString() ?? '';
      final estado = emitente['estado']?.toString() ?? '';
      final telefone = emitente['telefone']?.toString() ?? '';

      if (nomeFantasia.isNotEmpty) {
        content.add(pw.Center(child: pw.Text(nomeFantasia, style: titleStyle)));
      }

      final enderecoFull = [
        if (endereco.isNotEmpty) '$endereco${numero_.isNotEmpty ? ', $numero_' : ''}',
        if (bairro.isNotEmpty) bairro,
        if (cidade.isNotEmpty) '$cidade${estado.isNotEmpty ? ' - $estado' : ''}',
      ].join('  ');
      if (enderecoFull.isNotEmpty) {
        content.add(pw.Center(
            child: pw.Text(enderecoFull, style: small, textAlign: pw.TextAlign.center)));
      }

      if (cnpj.isNotEmpty) {
        content.add(pw.Center(child: pw.Text('CNPJ: $cnpj', style: small)));
      }
      if (telefone.isNotEmpty) {
        content.add(pw.Center(child: pw.Text('Tel: $telefone', style: small)));
      }
    } else {
      content.add(pw.Center(child: pw.Text('MENULY PDV', style: titleStyle)));
    }

    content.add(_divider());

    // ── Sale info ──
    content.add(pw.Center(
        child: pw.Text('CUPOM DE VENDA', style: bigBold)));
    content.add(pw.SizedBox(height: 2));
    content.add(_infoRow('Venda #:', numero, normal));
    content.add(_infoRow('Data:', dataFormatada, normal));
    content.add(_infoRow('Operador:', operador, normal));

    content.add(_divider());

    // ── Items header ──
    final colQtd = is58 ? 16.0 : 20.0;
    final colUnit = is58 ? 35.0 : 45.0;
    final colTotal = is58 ? 40.0 : 50.0;

    content.add(pw.Row(
      children: [
        pw.SizedBox(width: colQtd, child: pw.Text('QTD', style: bold)),
        pw.Expanded(child: pw.Text('DESCRICAO', style: bold)),
        pw.SizedBox(
            width: colUnit,
            child: pw.Text('UNIT', style: bold, textAlign: pw.TextAlign.right)),
        pw.SizedBox(
            width: colTotal,
            child:
                pw.Text('TOTAL', style: bold, textAlign: pw.TextAlign.right)),
      ],
    ));
    content.add(pw.SizedBox(height: 2));

    // ── Items ──
    for (final item in itens) {
      final desc = item['produto_descricao']?.toString() ?? 'Produto';
      final qtd = _parseDouble(item['quantidade']);
      final precoUnit = _parseDouble(item['preco_unitario']);
      final itemTotal = _parseDouble(item['total']);

      content.add(pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
              width: colQtd,
              child: pw.Text(
                  qtd == qtd.truncateToDouble()
                      ? qtd.toInt().toString()
                      : qtd.toStringAsFixed(1),
                  style: normal)),
          pw.Expanded(
              child: pw.Text(desc, style: normal, maxLines: 2)),
          pw.SizedBox(
              width: colUnit,
              child: pw.Text(_formatCurrency(precoUnit),
                  style: normal, textAlign: pw.TextAlign.right)),
          pw.SizedBox(
              width: colTotal,
              child: pw.Text(_formatCurrency(itemTotal),
                  style: normal, textAlign: pw.TextAlign.right)),
        ],
      ));
    }

    content.add(_divider());

    // ── Totals ──
    content.add(_infoRow('Subtotal:', _currencyFormat.format(subtotal), normal));
    if (descontoValor > 0) {
      content.add(
          _infoRow('Desconto:', '- ${_currencyFormat.format(descontoValor)}', normal));
    }
    content.add(_infoRow('TOTAL:', _currencyFormat.format(total), bigBold));

    content.add(_divider());

    // ── Payment ──
    if (pagamentos != null && pagamentos.isNotEmpty) {
      // Multiplos pagamentos
      if (pagamentos.length == 1) {
        final forma = pagamentos[0]['forma_pagamento']?.toString() ?? '';
        content.add(_infoRow('Forma Pgto:', pagLabel(forma), normal));
      } else {
        content.add(pw.Text('PAGAMENTOS:', style: bold));
        content.add(pw.SizedBox(height: 2));
        for (final pag in pagamentos) {
          final forma = pag['forma_pagamento']?.toString() ?? '';
          final valor = _parseDouble(pag['valor']);
          content.add(_infoRow(
              '  ${pagLabel(forma)}', _currencyFormat.format(valor), normal));
        }
      }
    } else {
      content.add(
          _infoRow('Forma Pgto:', pagLabel(formaPagamento), normal));
    }
    final temDinheiro = pagamentos != null
        ? pagamentos.any((p) => p['forma_pagamento'] == 'dinheiro')
        : formaPagamento == 'dinheiro';
    if (temDinheiro && valorRecebido > 0) {
      content.add(_infoRow(
          'Valor Recebido:', _currencyFormat.format(valorRecebido), normal));
      content.add(_infoRow('Troco:', _currencyFormat.format(troco), bold));
    }

    content.add(_divider());

    // ── Footer ──
    content.add(pw.SizedBox(height: 4));
    content.add(pw.Center(
        child: pw.Text('Obrigado pela preferencia!', style: normal)));
    content.add(pw.SizedBox(height: 2));
    content.add(pw.Center(
        child: pw.Text('Menuly PDV', style: small)));
    content.add(pw.SizedBox(height: 8));

    // Build PDF page
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

  static String _formatCurrency(double value) {
    return value.toStringAsFixed(2);
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
