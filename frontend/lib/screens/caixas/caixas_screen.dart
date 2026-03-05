import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/caixa.dart';
import '../../models/caixa_movimento.dart';
import '../../providers/caixas_provider.dart';
import '../../services/fechamento_receipt_service.dart';

class CaixasScreen extends StatefulWidget {
  CaixasScreen({super.key});

  @override
  State<CaixasScreen> createState() => _CaixasScreenState();
}

class _CaixasScreenState extends State<CaixasScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');
  final _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<CaixasProvider>();
      provider.carregarCaixas().then((_) {
        if (provider.caixaSelecionada != null) {
          provider.carregarMovimentos(caixaId: provider.caixaSelecionada!.id);
        }
      });
    });
  }

  void _onCaixaChanged(Caixa? caixa) {
    if (caixa == null) return;
    final provider = context.read<CaixasProvider>();
    provider.selecionarCaixa(caixa);
    provider.carregarMovimentos(caixaId: caixa.id);
  }

  void _abrirLancamento() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _LancamentoDialog(caixaId: provider.caixaSelecionada!.id),
      ),
    );
  }

  void _abrirTransferencia() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null || provider.caixas.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Necessario pelo menos 2 caixas para transferir')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _TransferenciaDialog(
          caixaOrigemId: provider.caixaSelecionada!.id,
        ),
      ),
    );
  }

  void _abrirResumo() async {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    await provider.carregarResumo(provider.caixaSelecionada!.id);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _ResumoDialog(currencyFormat: _currencyFormat),
      ),
    );
  }

  void _abrirImportarCsv() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _ImportarCsvDialog(
          caixaId: provider.caixaSelecionada!.id,
        ),
      ),
    );
  }

  void _abrirFechamento() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _FechamentoDialog(
          caixaId: provider.caixaSelecionada!.id,
          currencyFormat: _currencyFormat,
        ),
      ),
    ).then((result) {
      if (result == true) {
        provider.carregarCaixas();
        provider.carregarMovimentos();
      }
    });
  }

  void _abrirHistorico() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    showDialog(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _HistoricoFechamentosDialog(
          caixaId: provider.caixaSelecionada!.id,
          currencyFormat: _currencyFormat,
        ),
      ),
    );
  }

  void _abrirCaixaDialog() {
    final provider = context.read<CaixasProvider>();
    if (provider.caixaSelecionada == null) return;

    showDialog<bool>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: _AbrirCaixaDialog(
          caixaId: provider.caixaSelecionada!.id,
          caixaNome: provider.caixaSelecionada!.nome,
        ),
      ),
    ).then((result) {
      if (result == true) {
        provider.carregarCaixas();
        provider.carregarMovimentos(caixaId: provider.caixaSelecionada!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            Expanded(child: _buildMovimentosTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Consumer<CaixasProvider>(
      builder: (context, provider, _) {
        final caixa = provider.caixaSelecionada;
        final enabled = caixa != null;
        final isAberto = caixa?.isAberto ?? false;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Linha 1: título + seletor + status + saldo
            Row(
              children: [
                Text(
                  'Caixa',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(width: 24),
                _buildCaixaSelector(provider),
                SizedBox(width: 12),
                if (caixa != null) ...[
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: (isAberto
                              ? AppTheme.greenSuccess
                              : AppTheme.error)
                          .withOpacity(0.15),
                      border: Border.all(
                          color: (isAberto
                                  ? AppTheme.greenSuccess
                                  : AppTheme.error)
                              .withOpacity(0.4)),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAberto
                              ? Icons.lock_open_outlined
                              : Icons.lock_outlined,
                          size: 14,
                          color: isAberto
                              ? AppTheme.greenSuccess
                              : AppTheme.error,
                        ),
                        SizedBox(width: 6),
                        Text(
                          isAberto ? 'Aberto' : 'Fechado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isAberto
                                ? AppTheme.greenSuccess
                                : AppTheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12),
                  // Saldo
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.greenSuccess.withOpacity(0.1),
                      border: Border.all(
                          color: AppTheme.greenSuccess.withOpacity(0.3)),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Saldo: ',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        Text(
                          _currencyFormat.format(caixa.saldoAtual),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.greenSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: 12),
            // Linha 2: botões de ação
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Abrir Caixa - só aparece quando fechado
                if (enabled && !isAberto)
                  ElevatedButton.icon(
                    onPressed: _abrirCaixaDialog,
                    icon: Icon(Icons.lock_open, size: 16),
                    label: Text('Abrir Caixa',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: (enabled && isAberto) ? _abrirImportarCsv : null,
                  icon: Icon(Icons.upload_file, size: 16),
                  label: Text('Importar CSV',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (enabled && isAberto) ? _abrirTransferencia : null,
                  icon: Icon(Icons.swap_horiz, size: 16),
                  label: Text('Transferir',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: (enabled && isAberto) ? _abrirLancamento : null,
                  icon: Icon(Icons.add, size: 16),
                  label: Text('Lancamento',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: enabled ? _abrirResumo : null,
                  icon: Icon(Icons.summarize_outlined, size: 16),
                  label:
                      Text('Resumo', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
                // Fechamento - só aparece quando aberto
                if (enabled && isAberto)
                  ElevatedButton.icon(
                    onPressed: _abrirFechamento,
                    icon: Icon(Icons.lock_outline, size: 16),
                    label: Text('Fechamento',
                        style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: enabled ? _abrirHistorico : null,
                  icon: Icon(Icons.history_outlined, size: 16),
                  label: Text('Historico',
                      style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildCaixaSelector(CaixasProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: provider.caixaSelecionada?.id,
          hint: Text(
            'Selecionar caixa',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          dropdownColor: AppTheme.cardSurface,
          style: TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          icon: Icon(Icons.arrow_drop_down,
              color: AppTheme.textSecondary),
          items: provider.caixas.map((c) {
            return DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.nome),
            );
          }).toList(),
          onChanged: (id) {
            if (id == null) return;
            final caixa = provider.caixas.firstWhere((c) => c.id == id);
            _onCaixaChanged(caixa);
          },
        ),
      ),
    );
  }

  Widget _buildMovimentosTable() {
    return Consumer<CaixasProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator());
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline,
                    size: 48, color: AppTheme.error),
                SizedBox(height: 12),
                Text(
                  'Erro ao carregar movimentos',
                  style:
                      TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  provider.error!,
                  style: TextStyle(
                      color: AppTheme.textSecondary, fontSize: 13),
                ),
                SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => provider.carregarMovimentos(),
                  child: Text('Tentar novamente'),
                ),
              ],
            ),
          );
        }

        if (provider.caixaSelecionada == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 12),
                Text(
                  'Selecione um caixa para ver os movimentos',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        if (provider.movimentos.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 48, color: AppTheme.textSecondary),
                SizedBox(height: 12),
                Text(
                  'Nenhum movimento encontrado',
                  style:
                      TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowColor:
                  WidgetStateProperty.all(AppTheme.scaffoldBackground),
              dataRowColor: WidgetStateProperty.all(AppTheme.cardSurface),
              border: TableBorder.all(color: AppTheme.border, width: 0.5),
              columns: [
                DataColumn(label: Text('Data')),
                DataColumn(label: Text('Tipo')),
                DataColumn(label: Text('Descricao')),
                DataColumn(label: Text('Valor'), numeric: true),
              ],
              rows: provider.movimentos
                  .map((m) => _buildMovimentoRow(m))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  DataRow _buildMovimentoRow(CaixaMovimento mov) {
    final isEntrada = mov.tipo.toLowerCase() == 'entrada';
    final tipoColor = isEntrada ? AppTheme.greenSuccess : AppTheme.error;

    String formattedDate = '';
    if (mov.criadoEm.isNotEmpty) {
      try {
        formattedDate = _dateFormat.format(DateTime.parse(mov.criadoEm));
      } catch (_) {
        formattedDate = mov.criadoEm;
      }
    }

    return DataRow(cells: [
      DataCell(Text(
        formattedDate,
        style: TextStyle(color: AppTheme.textPrimary, fontSize: 13),
      )),
      DataCell(
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: tipoColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: Text(
            mov.tipo,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: tipoColor,
            ),
          ),
        ),
      ),
      DataCell(Text(
        mov.descricao ?? '-',
        style: TextStyle(color: AppTheme.textPrimary),
      )),
      DataCell(Text(
        _currencyFormat.format(mov.valor),
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: tipoColor,
        ),
      )),
    ]);
  }
}

// ── Lancamento Dialog ────────────────────────────────────────────────────────

class _LancamentoDialog extends StatefulWidget {
  final int caixaId;
  const _LancamentoDialog({required this.caixaId});

  @override
  State<_LancamentoDialog> createState() => _LancamentoDialogState();
}

class _LancamentoDialogState extends State<_LancamentoDialog> {
  String _tipo = 'entrada';
  final _valorCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = double.tryParse(_valorCtrl.text.trim());
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe um valor valido')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<CaixasProvider>();
      final ok = await provider.lancamento(
        caixaId: widget.caixaId,
        tipo: _tipo,
        valor: valor,
        descricao: _descricaoCtrl.text.trim(),
      );
      if (ok && mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novo Lancamento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Tipo: ',
                    style:
                        TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                  ),
                  SizedBox(width: 12),
                  _TipoToggle(
                    value: _tipo,
                    onChanged: (v) => setState(() => _tipo = v),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: _valorCtrl,
                decoration: InputDecoration(
                  labelText: 'Valor',
                  prefixText: r'R$ ',
                ),
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
              ),
              SizedBox(height: 12),
              TextField(
                controller: _descricaoCtrl,
                decoration: InputDecoration(labelText: 'Descricao'),
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                maxLines: 2,
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _saving ? null : _confirmar,
                    child: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tipo toggle ──────────────────────────────────────────────────────────────

class _TipoToggle extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _TipoToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildOption('entrada', 'Entrada', AppTheme.greenSuccess),
        SizedBox(width: 8),
        _buildOption('saida', 'Saida', AppTheme.error),
      ],
    );
  }

  Widget _buildOption(String tipo, String label, Color color) {
    final isSelected = value == tipo;

    return GestureDetector(
      onTap: () => onChanged(tipo),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          border: Border.all(
            color: isSelected ? color : AppTheme.border,
          ),
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? color : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Transferencia Dialog ─────────────────────────────────────────────────────

class _TransferenciaDialog extends StatefulWidget {
  final int caixaOrigemId;
  const _TransferenciaDialog({required this.caixaOrigemId});

  @override
  State<_TransferenciaDialog> createState() => _TransferenciaDialogState();
}

class _TransferenciaDialogState extends State<_TransferenciaDialog> {
  late int _origemId;
  int? _destinoId;
  final _valorCtrl = TextEditingController();
  final _descricaoCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _origemId = widget.caixaOrigemId;
  }

  @override
  void dispose() {
    _valorCtrl.dispose();
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (_destinoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione o caixa de destino')),
      );
      return;
    }

    final valor = double.tryParse(_valorCtrl.text.trim());
    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe um valor valido')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<CaixasProvider>();
      final ok = await provider.transferencia(
        caixaOrigemId: _origemId,
        caixaDestinoId: _destinoId!,
        valor: valor,
        descricao: _descricaoCtrl.text.trim(),
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Transferencia realizada com sucesso')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaixasProvider>(
      builder: (context, provider, _) {
        final caixas = provider.caixas;
        final origem = caixas.where((c) => c.id == _origemId).firstOrNull;
        final currFmt =
            NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

        return Dialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          child: SizedBox(
            width: 440,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.swap_horiz,
                          color: AppTheme.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Transferencia entre Caixas',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  // Origem
                  Text('Caixa de Origem',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  SizedBox(height: 6),
                  _buildCaixaDropdown(
                    value: _origemId,
                    caixas: caixas,
                    excludeId: _destinoId,
                    onChanged: (id) {
                      if (id != null) setState(() => _origemId = id);
                    },
                  ),
                  if (origem != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Saldo: ${currFmt.format(origem.saldoAtual)}',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.greenSuccess),
                      ),
                    ),
                  SizedBox(height: 16),

                  // Destino
                  Text('Caixa de Destino',
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  SizedBox(height: 6),
                  _buildCaixaDropdown(
                    value: _destinoId,
                    caixas: caixas,
                    excludeId: _origemId,
                    onChanged: (id) => setState(() => _destinoId = id),
                  ),
                  SizedBox(height: 16),

                  // Valor
                  TextField(
                    controller: _valorCtrl,
                    decoration: InputDecoration(
                      labelText: 'Valor',
                      prefixText: r'R$ ',
                    ),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                  ),
                  SizedBox(height: 12),

                  // Descricao
                  TextField(
                    controller: _descricaoCtrl,
                    decoration: InputDecoration(
                        labelText: 'Descricao (opcional)'),
                    style: TextStyle(
                        color: AppTheme.textPrimary, fontSize: 14),
                  ),
                  SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text('Cancelar'),
                      ),
                      SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _saving ? null : _confirmar,
                        icon: _saving
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : Icon(Icons.swap_horiz, size: 18),
                        label: Text('Transferir'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCaixaDropdown({
    required int? value,
    required List<Caixa> caixas,
    required int? excludeId,
    required ValueChanged<int?> onChanged,
  }) {
    final filteredCaixas =
        caixas.where((c) => c.id != excludeId).toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppTheme.inputFill,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: filteredCaixas.any((c) => c.id == value) ? value : null,
          hint: Text('Selecionar caixa',
              style:
                  TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          dropdownColor: AppTheme.cardSurface,
          style:
              TextStyle(fontSize: 14, color: AppTheme.textPrimary),
          icon: Icon(Icons.arrow_drop_down,
              color: AppTheme.textSecondary),
          isExpanded: true,
          items: filteredCaixas.map((c) {
            return DropdownMenuItem<int>(
              value: c.id,
              child: Text(c.nome),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Resumo Dialog ────────────────────────────────────────────────────────────

class _ResumoDialog extends StatelessWidget {
  final NumberFormat currencyFormat;
  const _ResumoDialog({required this.currencyFormat});

  @override
  Widget build(BuildContext context) {
    return Consumer<CaixasProvider>(
      builder: (context, provider, _) {
        final resumo = provider.resumo;

        double entradas = 0;
        double saidas = 0;
        if (resumo != null) {
          entradas = _parseDouble(resumo['total_entradas']);
          saidas = _parseDouble(resumo['total_saidas']);
        }
        final saldo = entradas - saidas;

        return Dialog(
          backgroundColor: AppTheme.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            side: BorderSide(color: AppTheme.border),
          ),
          child: SizedBox(
            width: 380,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resumo do Caixa',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: 24),
                  _buildResumoRow(
                    'Total Entradas',
                    currencyFormat.format(entradas),
                    AppTheme.greenSuccess,
                    Icons.arrow_upward,
                  ),
                  SizedBox(height: 16),
                  _buildResumoRow(
                    'Total Saidas',
                    currencyFormat.format(saidas),
                    AppTheme.error,
                    Icons.arrow_downward,
                  ),
                  SizedBox(height: 16),
                  Divider(color: AppTheme.border),
                  SizedBox(height: 16),
                  _buildResumoRow(
                    'Saldo',
                    currencyFormat.format(saldo),
                    saldo >= 0 ? AppTheme.greenSuccess : AppTheme.error,
                    Icons.account_balance_wallet,
                  ),
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Fechar'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumoRow(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ── Fechamento Dialog ────────────────────────────────────────────────────────

class _FechamentoDialog extends StatefulWidget {
  final int caixaId;
  final NumberFormat currencyFormat;

  const _FechamentoDialog({
    required this.caixaId,
    required this.currencyFormat,
  });

  @override
  State<_FechamentoDialog> createState() => _FechamentoDialogState();
}

class _FechamentoDialogState extends State<_FechamentoDialog> {
  bool _loading = true;
  bool _confirmando = false;
  Map<String, dynamic>? _dados;

  // Date range - default today
  late DateTime _dataInicio;
  late DateTime _dataFim;

  // Conferência
  final _valorContadoCtrl = TextEditingController();
  final _observacoesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _dataInicio = DateTime(now.year, now.month, now.day);
    _dataFim = DateTime(now.year, now.month, now.day, 23, 59, 59);
    _carregar();
  }

  @override
  void dispose() {
    _valorContadoCtrl.dispose();
    _observacoesCtrl.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final provider = context.read<CaixasProvider>();
    final result = await provider.carregarFechamento(
      widget.caixaId,
      dataInicio: _dataInicio.toIso8601String(),
      dataFim: _dataFim.toIso8601String(),
    );
    if (mounted) {
      setState(() {
        _dados = result;
        _loading = false;
      });
    }
  }

  Future<void> _confirmarFechamento() async {
    setState(() => _confirmando = true);

    double? saldoInformado;
    final rawValor = _valorContadoCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    if (rawValor.isNotEmpty) {
      saldoInformado = double.tryParse(rawValor);
    }

    final provider = context.read<CaixasProvider>();
    final result = await provider.fecharCaixa(
      caixaId: widget.caixaId,
      dataInicio: _dataInicio.toIso8601String(),
      dataFim: _dataFim.toIso8601String(),
      saldoInformado: saldoInformado,
      observacoes: _observacoesCtrl.text,
    );

    if (mounted) {
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fechamento registrado com sucesso')),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro: ${provider.error ?? "Falha ao registrar fechamento"}')),
        );
        setState(() => _confirmando = false);
      }
    }
  }

  Future<void> _imprimirFechamento() async {
    if (_dados == null) return;

    final provider = context.read<CaixasProvider>();
    final caixaNome = provider.caixaSelecionada?.nome ?? 'Caixa';
    final dateFmt = DateFormat('dd/MM/yyyy');
    final fmt = widget.currencyFormat;

    final vendas = (_dados!['vendas_por_forma_pagamento'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final movs = (_dados!['movimentos_por_categoria'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    final totalEntradas = _parseDouble(_dados!['total_entradas']);
    final totalSaidas = _parseDouble(_dados!['total_saidas']);
    final saldoEsperado = _parseDouble(_dados!['saldo_esperado']);

    final pdfBytes = await FechamentoReceiptService.generate(
      caixaNome: caixaNome,
      dataInicio: dateFmt.format(_dataInicio),
      dataFim: dateFmt.format(_dataFim),
      vendas: vendas,
      movimentos: movs,
      totalEntradas: totalEntradas,
      totalSaidas: totalSaidas,
      saldoEsperado: saldoEsperado,
      currencyFormat: fmt,
    );

    if (mounted) {
      await Printing.layoutPdf(
        onLayout: (_) => pdfBytes,
        name: 'Fechamento $caixaNome ${dateFmt.format(_dataInicio)}',
      );
    }
  }

  Future<void> _selecionarData(bool isInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isInicio ? _dataInicio : _dataFim,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppTheme.primary,
              surface: AppTheme.cardSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isInicio) {
          _dataInicio = DateTime(picked.year, picked.month, picked.day);
        } else {
          _dataFim =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
      _carregar();
    }
  }

  String _formatFormaPagamento(String? fp) {
    if (fp == null) return 'Outros';
    switch (fp.toLowerCase()) {
      case 'dinheiro':
        return 'Dinheiro';
      case 'cartao_credito':
        return 'Cartao Credito';
      case 'cartao_debito':
        return 'Cartao Debito';
      case 'pix':
        return 'PIX';
      default:
        return fp.replaceAll('_', ' ');
    }
  }

  String _formatCategoria(String? cat) {
    if (cat == null) return 'Manual';
    switch (cat.toLowerCase()) {
      case 'venda':
        return 'Vendas';
      case 'transferencia':
        return 'Transferencia';
      case 'manual':
        return 'Manual';
      case 'importacao_csv':
        return 'Importacao CSV';
      default:
        return cat.replaceAll('_', ' ');
    }
  }

  double? get _saldoInformado {
    final raw = _valorContadoCtrl.text
        .replaceAll('R\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '')
        .replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.currencyFormat;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 600,
        height: 680,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(Icons.lock_outline,
                            color: AppTheme.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Fechamento de Caixa',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.print_outlined, size: 20,
                              color: AppTheme.textSecondary),
                          tooltip: 'Imprimir relatorio',
                          onPressed: _imprimirFechamento,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date range
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _confirmando
                                        ? null
                                        : () => _selecionarData(true),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Data Inicio',
                                        suffixIcon: Icon(
                                            Icons.calendar_today,
                                            size: 18),
                                        isDense: true,
                                      ),
                                      child: Text(
                                        dateFmt.format(_dataInicio),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: InkWell(
                                    onTap: _confirmando
                                        ? null
                                        : () => _selecionarData(false),
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'Data Fim',
                                        suffixIcon: Icon(
                                            Icons.calendar_today,
                                            size: 18),
                                        isDense: true,
                                      ),
                                      child: Text(
                                        dateFmt.format(_dataFim),
                                        style: TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),

                            if (_dados != null) ...[
                              // ── Vendas por forma de pagamento ──
                              _buildSectionTitle(
                                  'Vendas por Forma de Pagamento'),
                              SizedBox(height: 8),
                              _buildVendasTable(fmt),
                              SizedBox(height: 16),

                              // ── Movimentos por categoria ──
                              _buildSectionTitle(
                                  'Movimentos por Categoria'),
                              SizedBox(height: 8),
                              _buildMovimentosTable(fmt),
                              SizedBox(height: 16),

                              // ── Totais ──
                              Divider(color: AppTheme.border),
                              SizedBox(height: 12),
                              _buildTotalRow(
                                'Total Entradas',
                                _parseDouble(_dados!['total_entradas']),
                                AppTheme.greenSuccess,
                                fmt,
                              ),
                              SizedBox(height: 6),
                              _buildTotalRow(
                                'Total Saidas',
                                _parseDouble(_dados!['total_saidas']),
                                AppTheme.error,
                                fmt,
                              ),
                              SizedBox(height: 6),
                              Divider(color: AppTheme.border),
                              SizedBox(height: 6),
                              _buildTotalRow(
                                'Saldo Esperado',
                                _parseDouble(_dados!['saldo_esperado']),
                                _parseDouble(_dados!['saldo_esperado']) >=
                                        0
                                    ? AppTheme.greenSuccess
                                    : AppTheme.error,
                                fmt,
                                bold: true,
                                fontSize: 18,
                              ),
                              SizedBox(height: 20),

                              // ── Conferência ──
                              _buildSectionTitle('Conferencia'),
                              SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _valorContadoCtrl,
                                      enabled: !_confirmando,
                                      decoration: InputDecoration(
                                        labelText:
                                            'Valor Contado (opcional)',
                                        hintText: '0,00',
                                        prefixText: 'R\$ ',
                                        isDense: true,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                              decimal: true),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  if (_saldoInformado != null) ...[
                                    Expanded(
                                      child: _buildDiferenca(fmt),
                                    ),
                                  ] else
                                    Expanded(child: SizedBox()),
                                ],
                              ),
                              SizedBox(height: 12),
                              TextFormField(
                                controller: _observacoesCtrl,
                                enabled: !_confirmando,
                                decoration: InputDecoration(
                                  labelText: 'Observacoes (opcional)',
                                  isDense: true,
                                ),
                                maxLines: 2,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    // Fixed buttons
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: _confirmando
                              ? null
                              : () => Navigator.of(context).pop(),
                          child: Text('Cancelar'),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed:
                              (_dados != null && !_confirmando)
                                  ? _confirmarFechamento
                                  : null,
                          icon: _confirmando
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : Icon(Icons.lock, size: 18),
                          label: Text(_confirmando
                              ? 'Registrando...'
                              : 'Confirmar Fechamento'),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildDiferenca(NumberFormat fmt) {
    final saldoEsperado = _parseDouble(_dados!['saldo_esperado']);
    final informado = _saldoInformado!;
    final diferenca = informado - saldoEsperado;
    final color = diferenca.abs() < 0.01
        ? AppTheme.greenSuccess
        : AppTheme.error;
    final label = diferenca.abs() < 0.01
        ? 'Conferido'
        : diferenca > 0
            ? 'Sobra: ${fmt.format(diferenca)}'
            : 'Falta: ${fmt.format(diferenca.abs())}';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: color,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildVendasTable(NumberFormat fmt) {
    final vendas =
        (_dados!['vendas_por_forma_pagamento'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (vendas.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nenhuma venda no periodo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border, width: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBackground,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusSm)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('Forma Pagamento',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
                Expanded(
                    child: Text('Qtd',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
                Expanded(
                    flex: 2,
                    child: Text('Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
              ],
            ),
          ),
          ...vendas.map((v) {
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppTheme.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      _formatFormaPagamento(v['forma_pagamento']?.toString()),
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${v['quantidade'] ?? 0}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      fmt.format(_parseDouble(v['total'])),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.greenSuccess,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMovimentosTable(NumberFormat fmt) {
    final movs =
        (_dados!['movimentos_por_categoria'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (movs.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('Nenhum movimento no periodo',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border, width: 0.5),
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      ),
      child: Column(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.scaffoldBackground,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppTheme.radiusSm)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text('Tipo',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
                Expanded(
                    flex: 2,
                    child: Text('Categoria',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
                Expanded(
                    child: Text('Qtd',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
                Expanded(
                    flex: 2,
                    child: Text('Total',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary))),
              ],
            ),
          ),
          ...movs.map((m) {
            final isEntrada = m['tipo'] == 'entrada';
            final color =
                isEntrada ? AppTheme.greenSuccess : AppTheme.error;

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: AppTheme.border, width: 0.5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusSm),
                      ),
                      child: Text(
                        isEntrada ? 'Entrada' : 'Saida',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _formatCategoria(m['categoria']?.toString()),
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textPrimary),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${m['quantidade'] ?? 0}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      fmt.format(_parseDouble(m['total'])),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTotalRow(
    String label,
    double value,
    Color color,
    NumberFormat fmt, {
    bool bold = false,
    double fontSize = 15,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: fontSize - 1,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: AppTheme.textSecondary,
          ),
        ),
        Spacer(),
        Text(
          fmt.format(value),
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

// ── Importar CSV Dialog ──────────────────────────────────────────────────────

class _ImportarCsvDialog extends StatefulWidget {
  final int caixaId;
  const _ImportarCsvDialog({required this.caixaId});

  @override
  State<_ImportarCsvDialog> createState() => _ImportarCsvDialogState();
}

class _ImportarCsvDialogState extends State<_ImportarCsvDialog> {
  List<List<dynamic>>? _csvData;
  List<String> _headers = [];
  String? _fileName;

  // Column mapping
  int? _colDescricao;
  int? _colValor;
  int? _colTipo;

  // Parsed items for preview
  List<_CsvItem> _parsedItems = [];

  bool _importing = false;

  final _currFmt = NumberFormat.currency(locale: 'pt_BR', symbol: r'R$');

  Future<void> _baixarModelo() async {
    const csvContent =
        'descricao,valor,tipo\r\n'
        'Pagamento fornecedor,150.00,saida\r\n'
        'Venda em dinheiro,250.00,entrada\r\n'
        'Conta de luz,89.90,saida\r\n'
        'Recebimento cliente,320.50,entrada\r\n';

    final path = await FilePicker.platform.saveFile(
      dialogTitle: 'Salvar modelo CSV',
      fileName: 'modelo_importacao.csv',
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (path == null) return;

    try {
      final filePath = path.endsWith('.csv') ? path : '$path.csv';
      await File(filePath).writeAsString(csvContent);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Modelo salvo com sucesso')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar modelo: $e')),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );

    if (result == null || result.files.isEmpty) return;

    final path = result.files.single.path;
    if (path == null) return;

    try {
      final content = await File(path).readAsString();
      final rows =
          CsvToListConverter(shouldParseNumbers: false).convert(content);

      if (rows.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Arquivo CSV vazio')),
          );
        }
        return;
      }

      setState(() {
        _csvData = rows;
        _fileName = result.files.single.name;
        _headers = rows.first.map((e) => e.toString().trim()).toList();
        _colDescricao = null;
        _colValor = null;
        _colTipo = null;
        _autoDetectColumns();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ler arquivo: $e')),
        );
      }
    }
  }

  void _autoDetectColumns() {
    for (int i = 0; i < _headers.length; i++) {
      final h = _headers[i].toLowerCase();
      if (h.contains('descri') ||
          h.contains('historico') ||
          h.contains('memo')) {
        _colDescricao ??= i;
      }
      if (h.contains('valor') ||
          h.contains('amount') ||
          h.contains('value')) {
        _colValor ??= i;
      }
      if (h.contains('tipo') ||
          h.contains('type') ||
          h.contains('d/c')) {
        _colTipo ??= i;
      }
    }
    _parseItems();
  }

  void _parseItems() {
    if (_csvData == null || _csvData!.length < 2) {
      _parsedItems = [];
      return;
    }

    final items = <_CsvItem>[];
    for (int i = 1; i < _csvData!.length; i++) {
      final row = _csvData![i];

      final descricao =
          _colDescricao != null && _colDescricao! < row.length
              ? row[_colDescricao!].toString().trim()
              : 'Linha ${i + 1}';

      double valor = 0;
      if (_colValor != null && _colValor! < row.length) {
        final rawVal = row[_colValor!]
            .toString()
            .trim()
            .replaceAll('R\$', '')
            .replaceAll(' ', '')
            .replaceAll('.', '')
            .replaceAll(',', '.');
        valor = double.tryParse(rawVal) ?? 0;
      }

      String tipo = 'entrada';
      if (_colTipo != null && _colTipo! < row.length) {
        final rawTipo = row[_colTipo!].toString().trim().toLowerCase();
        if (rawTipo.contains('said') ||
            rawTipo.contains('debit') ||
            rawTipo == 'd' ||
            rawTipo.contains('-')) {
          tipo = 'saida';
        }
      } else if (valor < 0) {
        tipo = 'saida';
        valor = valor.abs();
      }

      if (valor > 0) {
        items.add(_CsvItem(
          descricao: descricao,
          valor: valor,
          tipo: tipo,
        ));
      }
    }

    setState(() => _parsedItems = items);
  }

  Future<void> _importar() async {
    if (_parsedItems.isEmpty) return;

    setState(() => _importing = true);

    try {
      final provider = context.read<CaixasProvider>();
      final itens = _parsedItems
          .map((item) => {
                'descricao': item.descricao,
                'valor': item.valor,
                'tipo': item.tipo,
              })
          .toList();

      final result = await provider.importarCsvBatch(
        caixaId: widget.caixaId,
        itens: itens,
      );

      if (mounted) {
        if (result != null) {
          final importados = result['data']?['importados'] ?? itens.length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('$importados lancamentos importados com sucesso')),
          );
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Erro: ${provider.error ?? "Falha na importacao"}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 700,
        height: 600,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.upload_file,
                      color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Importar CSV Bancario',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // File picker
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _importing ? null : _pickFile,
                    icon: Icon(Icons.folder_open, size: 18),
                    label: Text('Selecionar Arquivo'),
                  ),
                  SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _importing ? null : _baixarModelo,
                    icon: Icon(Icons.download, size: 18),
                    label: Text('Baixar Modelo'),
                  ),
                  SizedBox(width: 12),
                  if (_fileName != null)
                    Expanded(
                      child: Text(
                        _fileName!,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16),

              // Column mapping
              if (_csvData != null) ...[
                Text(
                  'Mapeamento de Colunas',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildColumnDropdown(
                        'Descricao',
                        _colDescricao,
                        (v) {
                          setState(() => _colDescricao = v);
                          _parseItems();
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildColumnDropdown(
                        'Valor',
                        _colValor,
                        (v) {
                          setState(() => _colValor = v);
                          _parseItems();
                        },
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _buildColumnDropdown(
                        'Tipo (opcional)',
                        _colTipo,
                        (v) {
                          setState(() => _colTipo = v);
                          _parseItems();
                        },
                        optional: true,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '${_parsedItems.length} lancamentos encontrados',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                SizedBox(height: 8),
              ],

              // Preview table
              if (_parsedItems.isNotEmpty)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: AppTheme.border, width: 0.5),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusSm),
                    ),
                    child: SingleChildScrollView(
                      child: SizedBox(
                        width: double.infinity,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(
                              AppTheme.scaffoldBackground),
                          dataRowColor: WidgetStateProperty.all(
                              AppTheme.cardSurface),
                          columnSpacing: 16,
                          columns: [
                            DataColumn(label: Text('Tipo')),
                            DataColumn(label: Text('Descricao')),
                            DataColumn(
                                label: Text('Valor'), numeric: true),
                          ],
                          rows: _parsedItems.map((item) {
                            final isEntrada = item.tipo == 'entrada';
                            final color = isEntrada
                                ? AppTheme.greenSuccess
                                : AppTheme.error;
                            return DataRow(cells: [
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.radiusSm),
                                  ),
                                  child: Text(
                                    isEntrada ? 'Entrada' : 'Saida',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(Text(
                                item.descricao,
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              )),
                              DataCell(Text(
                                _currFmt.format(item.valor),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),

              if (_csvData == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file_outlined,
                            size: 48, color: AppTheme.textSecondary),
                        SizedBox(height: 12),
                        Text(
                          'Selecione um arquivo CSV para importar',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Formatos aceitos: .csv, .txt',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Use "Baixar Modelo" para ver o formato esperado',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 16),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _importing
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: (_parsedItems.isNotEmpty && !_importing)
                        ? _importar
                        : null,
                    icon: _importing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                        : Icon(Icons.check, size: 18),
                    label: Text(
                      _importing
                          ? 'Importando...'
                          : 'Importar ${_parsedItems.length} lancamentos',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColumnDropdown(
    String label,
    int? value,
    ValueChanged<int?> onChanged, {
    bool optional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 12, color: AppTheme.textSecondary)),
        SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.inputFill,
            border: Border.all(color: AppTheme.border),
            borderRadius: BorderRadius.circular(AppTheme.radiusSm),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int?>(
              value: value,
              hint: Text(
                optional ? '(nenhum)' : 'Selecionar',
                style: TextStyle(
                    fontSize: 13, color: AppTheme.textSecondary),
              ),
              dropdownColor: AppTheme.cardSurface,
              style: TextStyle(
                  fontSize: 13, color: AppTheme.textPrimary),
              isExpanded: true,
              items: [
                if (optional)
                  DropdownMenuItem<int?>(
                    value: null,
                    child: Text('(nenhum)',
                        style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary)),
                  ),
                ..._headers.asMap().entries.map((e) {
                  return DropdownMenuItem<int>(
                    value: e.key,
                    child: Text(
                      e.value,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _CsvItem {
  final String descricao;
  final double valor;
  final String tipo;

  _CsvItem({
    required this.descricao,
    required this.valor,
    required this.tipo,
  });
}

// ── Abrir Caixa Dialog ─────────────────────────────────────────────────────

class _AbrirCaixaDialog extends StatefulWidget {
  final int caixaId;
  final String caixaNome;

  const _AbrirCaixaDialog({
    required this.caixaId,
    required this.caixaNome,
  });

  @override
  State<_AbrirCaixaDialog> createState() => _AbrirCaixaDialogState();
}

class _AbrirCaixaDialogState extends State<_AbrirCaixaDialog> {
  final _valorCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _valorCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final valor = double.tryParse(
      _valorCtrl.text
          .replaceAll('R\$', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.'),
    );
    if (valor == null || valor < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Informe um valor valido')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<CaixasProvider>();
      final ok = await provider.abrirCaixa(
        caixaId: widget.caixaId,
        valorInicial: valor,
      );
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Caixa "${widget.caixaNome}" aberto com sucesso',
            ),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erro: ${provider.error ?? "Falha ao abrir caixa"}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 400,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_open,
                      color: AppTheme.greenSuccess, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Abrir Caixa - ${widget.caixaNome}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                'Informe o valor inicial (fundo de troco) que sera colocado no caixa.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _valorCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Valor Inicial (Fundo de Troco)',
                  hintText: '0,00',
                  prefixText: r'R$ ',
                ),
                style: TextStyle(
                    color: AppTheme.textPrimary, fontSize: 16),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
                ],
                onSubmitted: (_) => _confirmar(),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: Text('Cancelar'),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saving ? null : _confirmar,
                    icon: _saving
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.lock_open, size: 18),
                    label: Text(_saving ? 'Abrindo...' : 'Abrir Caixa'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.greenSuccess,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Historico de Fechamentos Dialog ────────────────────────────────────────

class _HistoricoFechamentosDialog extends StatefulWidget {
  final int caixaId;
  final NumberFormat currencyFormat;

  const _HistoricoFechamentosDialog({
    required this.caixaId,
    required this.currencyFormat,
  });

  @override
  State<_HistoricoFechamentosDialog> createState() =>
      _HistoricoFechamentosDialogState();
}

class _HistoricoFechamentosDialogState
    extends State<_HistoricoFechamentosDialog> {
  bool _loading = true;
  List<Map<String, dynamic>> _fechamentos = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final provider = context.read<CaixasProvider>();
    final result = await provider.carregarFechamentos(widget.caixaId);
    if (mounted) {
      setState(() {
        _fechamentos = result ?? [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = widget.currencyFormat;
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    return Dialog(
      backgroundColor: AppTheme.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        side: BorderSide(color: AppTheme.border),
      ),
      child: SizedBox(
        width: 700,
        height: 500,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, color: AppTheme.primary, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Historico de Fechamentos',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              if (_loading)
                Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (_fechamentos.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Nenhum fechamento registrado',
                      style: TextStyle(
                          color: AppTheme.textSecondary, fontSize: 14),
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: SizedBox(
                      width: double.infinity,
                      child: DataTable(
                        headingRowColor:
                            WidgetStateProperty.all(AppTheme.scaffoldBackground),
                        dataRowColor:
                            WidgetStateProperty.all(AppTheme.cardSurface),
                        columnSpacing: 12,
                        columns: [
                          DataColumn(label: Text('Data')),
                          DataColumn(label: Text('Operador')),
                          DataColumn(
                              label: Text('Esperado'), numeric: true),
                          DataColumn(
                              label: Text('Contado'), numeric: true),
                          DataColumn(
                              label: Text('Diferenca'), numeric: true),
                        ],
                        rows: _fechamentos.map((f) {
                          final criadoEm =
                              f['criado_em']?.toString() ?? '';
                          String dataStr = criadoEm;
                          try {
                            dataStr =
                                dateFmt.format(DateTime.parse(criadoEm));
                          } catch (_) {}

                          final operador =
                              f['nome_usuario']?.toString() ?? '-';
                          final saldoEsperado =
                              _parseDouble(f['saldo_esperado']);
                          final saldoInformado =
                              f['saldo_informado'];
                          final diferenca = f['diferenca'];

                          return DataRow(cells: [
                            DataCell(Text(dataStr,
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12))),
                            DataCell(Text(operador,
                                style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 12))),
                            DataCell(Text(
                              fmt.format(saldoEsperado),
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                  fontSize: 12),
                            )),
                            DataCell(Text(
                              saldoInformado != null
                                  ? fmt.format(
                                      _parseDouble(saldoInformado))
                                  : '-',
                              style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12),
                            )),
                            DataCell(
                              diferenca != null
                                  ? Text(
                                      fmt.format(
                                          _parseDouble(diferenca)),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                        color: _parseDouble(diferenca)
                                                    .abs() <
                                                0.01
                                            ? AppTheme.greenSuccess
                                            : AppTheme.error,
                                      ),
                                    )
                                  : Text('-',
                                      style: TextStyle(
                                          color: AppTheme.textSecondary,
                                          fontSize: 12)),
                            ),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ),

              SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Fechar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
