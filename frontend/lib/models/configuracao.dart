class Configuracao {
  final int id;
  final String chave;
  final String? valor;
  final String? grupo;
  final String? descricao;

  Configuracao({
    required this.id,
    required this.chave,
    this.valor,
    this.grupo,
    this.descricao,
  });

  factory Configuracao.fromJson(Map<String, dynamic> json) {
    return Configuracao(
      id: _parseInt(json['id']),
      chave: json['chave']?.toString() ?? '',
      valor: json['valor']?.toString(),
      grupo: json['grupo']?.toString(),
      descricao: json['descricao']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'chave': chave,
    'valor': valor,
    'grupo': grupo,
    'descricao': descricao,
  };

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }
}

class Usuario {
  final int id;
  final String login;
  final String nome;
  final String papel;
  final double maxDesconto;
  final bool permPdv;
  final bool permProdutos;
  final bool permEstoque;
  final bool permVendas;
  final bool permCompras;
  final bool permClientes;
  final bool permFornecedores;
  final bool permCategorias;
  final bool permCaixa;
  final bool permContasReceber;
  final bool permContasPagar;
  final bool permCrediario;
  final bool permServicos;
  final bool permOrdensServico;
  final bool permDevolucoes;
  final bool permRelatorios;
  final bool ativo;
  final bool autoLogin;

  Usuario({
    required this.id,
    required this.login,
    required this.nome,
    this.papel = 'operador',
    this.maxDesconto = 0.0,
    this.permPdv = true,
    this.permProdutos = false,
    this.permEstoque = false,
    this.permVendas = false,
    this.permCompras = false,
    this.permClientes = true,
    this.permFornecedores = false,
    this.permCategorias = false,
    this.permCaixa = false,
    this.permContasReceber = false,
    this.permContasPagar = false,
    this.permCrediario = false,
    this.permServicos = false,
    this.permOrdensServico = false,
    this.permDevolucoes = false,
    this.permRelatorios = false,
    this.ativo = true,
    this.autoLogin = false,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: _parseInt(json['id']),
      login: json['login']?.toString() ?? '',
      nome: json['nome']?.toString() ?? '',
      papel: json['papel']?.toString() ?? 'operador',
      maxDesconto: _parseDouble(json['max_desconto']),
      permPdv: _parseBool(json['perm_pdv']),
      permProdutos: _parseBool(json['perm_produtos']),
      permEstoque: _parseBool(json['perm_estoque']),
      permVendas: _parseBool(json['perm_vendas']),
      permCompras: _parseBool(json['perm_compras']),
      permClientes: _parseBool(json['perm_clientes']),
      permFornecedores: _parseBool(json['perm_fornecedores']),
      permCategorias: _parseBool(json['perm_categorias']),
      permCaixa: _parseBool(json['perm_caixa']),
      permContasReceber: _parseBool(json['perm_contas_receber']),
      permContasPagar: _parseBool(json['perm_contas_pagar']),
      permCrediario: _parseBool(json['perm_crediario']),
      permServicos: _parseBool(json['perm_servicos']),
      permOrdensServico: _parseBool(json['perm_ordens_servico']),
      permDevolucoes: _parseBool(json['perm_devolucoes']),
      permRelatorios: _parseBool(json['perm_relatorios']),
      ativo: json['ativo'] == 1 || json['ativo'] == '1' || json['ativo'] == true,
      autoLogin: _parseBool(json['auto_login']),
    );
  }

  Map<String, dynamic> toJson() => {
    'login': login,
    'nome': nome,
    'papel': papel,
    'max_desconto': maxDesconto,
    'perm_pdv': permPdv,
    'perm_produtos': permProdutos,
    'perm_estoque': permEstoque,
    'perm_vendas': permVendas,
    'perm_compras': permCompras,
    'perm_clientes': permClientes,
    'perm_fornecedores': permFornecedores,
    'perm_categorias': permCategorias,
    'perm_caixa': permCaixa,
    'perm_contas_receber': permContasReceber,
    'perm_contas_pagar': permContasPagar,
    'perm_crediario': permCrediario,
    'perm_servicos': permServicos,
    'perm_ordens_servico': permOrdensServico,
    'perm_devolucoes': permDevolucoes,
    'perm_relatorios': permRelatorios,
    'ativo': ativo,
    'auto_login': autoLogin,
  };

  static int _parseInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _parseDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static bool _parseBool(dynamic v) {
    return v == 1 || v == '1' || v == true;
  }
}
