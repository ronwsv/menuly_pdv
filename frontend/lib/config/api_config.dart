class ApiConfig {
  static const String serverUrl = 'http://127.0.0.1:8080';
  static const String baseUrl = '$serverUrl/api';

  // Auth
  static const String login = '$baseUrl/auth/login';
  static const String logout = '$baseUrl/auth/logout';
  static const String alterarSenha = '$baseUrl/auth/alterar-senha';
  static const String validarAdmin = '$baseUrl/auth/validar-admin';

  // Categorias
  static const String categorias = '$baseUrl/categorias';
  static String categoriaById(int id) => '$categorias/$id';

  // Produtos
  static const String produtos = '$baseUrl/produtos';
  static String produtoById(int id) => '$produtos/$id';
  static String produtoByBarcode(String codigo) => '$produtos/barcode/$codigo';
  static String produtoByInterno(String codigo) => '$produtos/interno/$codigo';
  static String produtoInativar(int id) => '$produtos/$id/inativar';
  static String produtoBloquear(int id) => '$produtos/$id/bloquear';
  static String produtoImagem(int id) => '$produtos/$id/imagem';
  static String produtoComboItens(int id) => '$produtos/$id/combo-itens';
  static const String produtosImportar = '$produtos/importar';
  static const String produtosBatchEstoqueMinimo = '$produtos/batch/estoque-minimo';
  static const String produtosBatchMargem = '$produtos/batch/margem';
  static const String produtosRankingGeral = '$produtos/ranking/geral';
  static const String produtosRankingPorData = '$produtos/ranking/por-data';
  static String uploadUrl(String path) => '$serverUrl/$path';

  // Estoque
  static const String estoquePosicao = '$baseUrl/estoque/posicao';
  static const String estoqueAbaixoMinimo = '$baseUrl/estoque/abaixo-minimo';
  static const String estoqueHistorico = '$baseUrl/estoque/historico';
  static const String estoqueMovimentos = '$baseUrl/estoque/movimentos';
  static String estoqueProduto(int id) => '$baseUrl/estoque/$id';

  // Vendas
  static const String vendas = '$baseUrl/vendas';
  static String vendaById(int id) => '$vendas/$id';
  static String vendaCancelar(int id) => '$vendas/$id/cancelar';
  static String vendaConverter(int id) => '$vendas/$id/converter';

  // Caixas
  static const String caixas = '$baseUrl/caixas';
  static const String caixaMovimentos = '$baseUrl/caixas/movimentos';
  static const String caixaLancamento = '$baseUrl/caixas/lancamento';
  static const String caixaTransferencia = '$baseUrl/caixas/transferencia';
  static const String caixaLancamentoBatch = '$baseUrl/caixas/lancamento/batch';
  static String caixaById(int id) => '$caixas/$id';
  static String caixaResumo(int id) => '$caixas/$id/resumo';
  static String caixaFechamento(int id) => '$caixas/$id/fechamento';
  static String caixaAbrir(int id) => '$caixas/$id/abrir';
  static String caixaFechar(int id) => '$caixas/$id/fechar';
  static String caixaFechamentos(int id) => '$caixas/$id/fechamentos';

  // Clientes
  static const String clientes = '$baseUrl/clientes';
  static String clienteById(int id) => '$clientes/$id';

  // Fornecedores
  static const String fornecedores = '$baseUrl/fornecedores';
  static String fornecedorById(int id) => '$fornecedores/$id';

  // Compras
  static const String compras = '$baseUrl/compras';
  static String compraById(int id) => '$compras/$id';
  static const String comprasImportarXml = '$compras/importar-xml';

  // Contas a Receber
  static const String contasReceber = '$baseUrl/contas-receber';
  static const String contasReceberTotais = '$baseUrl/contas-receber/totais';
  static String contaReceberById(int id) => '$contasReceber/$id';
  static String contaReceberBaixa(int id) => '$contasReceber/$id/baixa';
  static String contaReceberCancelar(int id) => '$contasReceber/$id/cancelar';

  // Contas a Pagar
  static const String contasPagar = '$baseUrl/contas-pagar';
  static const String contasPagarTotais = '$baseUrl/contas-pagar/totais';
  static String contaPagarById(int id) => '$contasPagar/$id';
  static String contaPagarBaixa(int id) => '$contasPagar/$id/baixa';
  static String contaPagarCancelar(int id) => '$contasPagar/$id/cancelar';

  // Servicos
  static const String servicos = '$baseUrl/servicos';
  static String servicoById(int id) => '$servicos/$id';
  static String servicoInativar(int id) => '$servicos/$id/inativar';

  // Ordens de Servico
  static const String ordensServico = '$baseUrl/ordens-servico';
  static String ordemServicoById(int id) => '$ordensServico/$id';
  static String osAdicionarItemServico(int id) => '$ordensServico/$id/itens-servico';
  static String osRemoverItemServico(int id, int itemId) => '$ordensServico/$id/itens-servico/$itemId';
  static String osAdicionarItemProduto(int id) => '$ordensServico/$id/itens-produto';
  static String osRemoverItemProduto(int id, int itemId) => '$ordensServico/$id/itens-produto/$itemId';
  static String osFinalizar(int id) => '$ordensServico/$id/finalizar';
  static String osCancelar(int id) => '$ordensServico/$id/cancelar';

  // Crediario
  static const String crediario = '$baseUrl/crediario';
  static const String crediarioTotais = '$baseUrl/crediario/totais';
  static String crediarioById(int id) => '$crediario/$id';
  static String crediarioPagar(int id) => '$crediario/$id/pagar';
  static String crediarioLimiteCliente(int clienteId) => '$crediario/cliente/$clienteId/limite';

  // Devolucoes
  static const String devolucoes = '$baseUrl/devolucoes';
  static String devolucaoById(int id) => '$devolucoes/$id';
  static String devolucaoBuscarVenda(String numero) => '$devolucoes/venda/$numero';
  static String devolucaoBuscarVendasPorValor(double valor) => '$devolucoes/venda-por-valor?valor=$valor';
  static const String creditos = '$baseUrl/devolucoes/creditos';
  static const String creditosTotais = '$baseUrl/devolucoes/creditos/totais';
  static String creditosCliente(int clienteId) => '$devolucoes/creditos/cliente/$clienteId';
  static String creditoUtilizar(int id) => '$devolucoes/creditos/$id/utilizar';

  // Analytics / Graficos
  static const String vendasResumoDiario = '$baseUrl/vendas/resumo-diario';
  static const String vendasPorFormaPagamento = '$baseUrl/vendas/por-forma-pagamento';
  static const String vendasReceitaPorCategoria = '$baseUrl/vendas/receita-por-categoria';

  // Comissoes
  static const String comissoes = '$baseUrl/vendas/comissoes';
  static const String comissoesResumo = '$baseUrl/vendas/comissoes/resumo';

  // Consignacoes
  static const String consignacoes = '$baseUrl/consignacoes';
  static String consignacaoById(int id) => '$consignacoes/$id';
  static String consignacaoAcerto(int id) => '$consignacoes/$id/acerto';
  static String consignacaoCancelar(int id) => '$consignacoes/$id/cancelar';

  // Gaveta de dinheiro (ESC/POS via impressora térmica)
  static const String gavetaAbrir = '$baseUrl/gaveta/abrir';

  // Emitente
  static const String emitente = '$baseUrl/emitente';

  // Configuracoes
  static const String configuracoes = '$baseUrl/configuracoes';
  static String configuracaoByChave(String chave) => '$configuracoes/chave/$chave';
  static const String configuracoesBatch = '$configuracoes/batch';
  static const String usuarios = '$configuracoes/usuarios';
  static String usuarioById(int id) => '$usuarios/$id';

  // Backup
  static const String backupGerar = '$baseUrl/backup/gerar';
  static const String backupRestaurar = '$baseUrl/backup/restaurar';
}
