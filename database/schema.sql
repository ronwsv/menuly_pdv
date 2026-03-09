-- ====================================================================
-- MENULY PDV - Schema Completo do Banco de Dados
-- MySQL/MariaDB 10.6+
-- 32 tabelas | Charset: utf8mb4 | Engine: InnoDB
-- ====================================================================

-- Criar banco e usuário
CREATE DATABASE IF NOT EXISTS menuly_pdv
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'pdv_user'@'localhost' IDENTIFIED BY 'pdv_senha_segura';
GRANT ALL PRIVILEGES ON menuly_pdv.* TO 'pdv_user'@'localhost';
FLUSH PRIVILEGES;

USE menuly_pdv;

-- Desabilitar verificação de FK temporariamente para criar em qualquer ordem
SET FOREIGN_KEY_CHECKS = 0;

-- ====================================================================
-- TABELA 1: USUÁRIOS
-- Operadores do sistema com permissões por módulo
-- ====================================================================
CREATE TABLE IF NOT EXISTS usuarios (
  id INT PRIMARY KEY AUTO_INCREMENT,
  login VARCHAR(50) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,
  nome VARCHAR(100) NOT NULL,
  papel ENUM('admin', 'gerente', 'operador', 'vendedor') NOT NULL DEFAULT 'operador',
  max_desconto DECIMAL(5,2) DEFAULT 0.10,
  perm_pdv TINYINT(1) DEFAULT 1,
  perm_produtos TINYINT(1) DEFAULT 0,
  perm_estoque TINYINT(1) DEFAULT 0,
  perm_vendas TINYINT(1) DEFAULT 0,
  perm_compras TINYINT(1) DEFAULT 0,
  perm_clientes TINYINT(1) DEFAULT 1,
  perm_fornecedores TINYINT(1) DEFAULT 0,
  perm_categorias TINYINT(1) DEFAULT 0,
  perm_caixa TINYINT(1) DEFAULT 1,
  perm_contas_receber TINYINT(1) DEFAULT 0,
  perm_contas_pagar TINYINT(1) DEFAULT 0,
  perm_crediario TINYINT(1) DEFAULT 0,
  perm_servicos TINYINT(1) DEFAULT 0,
  perm_ordens_servico TINYINT(1) DEFAULT 0,
  perm_devolucoes TINYINT(1) DEFAULT 0,
  perm_consignacoes TINYINT(1) DEFAULT 0,
  perm_relatorios TINYINT(1) DEFAULT 0,
  comissao_percentual DECIMAL(5,2) DEFAULT NULL,
  ativo TINYINT(1) DEFAULT 1,
  auto_login TINYINT(1) DEFAULT 0,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 2: EMITENTE (Dados da Empresa)
-- ====================================================================
CREATE TABLE IF NOT EXISTS emitente (
  id INT PRIMARY KEY AUTO_INCREMENT,
  razao_social VARCHAR(200) NOT NULL,
  nome_fantasia VARCHAR(200),
  cnpj VARCHAR(18) NOT NULL,
  inscricao_estadual VARCHAR(20),
  inscricao_municipal VARCHAR(20),
  endereco VARCHAR(200),
  numero VARCHAR(20),
  complemento VARCHAR(100),
  bairro VARCHAR(100),
  cidade VARCHAR(100),
  estado VARCHAR(2),
  cep VARCHAR(10),
  telefone VARCHAR(20),
  email VARCHAR(200),
  logo_path VARCHAR(500),
  regime_tributario ENUM('simples', 'presumido', 'real') DEFAULT 'simples',
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 3: CLIENTES
-- ====================================================================
CREATE TABLE IF NOT EXISTS clientes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(200) NOT NULL,
  tipo_pessoa ENUM('F', 'J') NOT NULL DEFAULT 'F',
  cpf_cnpj VARCHAR(18) UNIQUE,
  inscricao_estadual VARCHAR(20),
  telefone VARCHAR(20),
  email VARCHAR(200),
  cep VARCHAR(10),
  endereco VARCHAR(200),
  numero VARCHAR(20),
  bairro VARCHAR(100),
  cidade VARCHAR(100),
  estado VARCHAR(2),
  limite_credito DECIMAL(10,2) DEFAULT 0.00,
  outros_dados TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_clientes_cpf (cpf_cnpj),
  INDEX idx_clientes_nome (nome)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 4: FORNECEDORES
-- ====================================================================
CREATE TABLE IF NOT EXISTS fornecedores (
  id INT PRIMARY KEY AUTO_INCREMENT,
  razao_social VARCHAR(200) NOT NULL,
  nome_fantasia VARCHAR(200),
  cnpj VARCHAR(18) UNIQUE,
  inscricao_estadual VARCHAR(20),
  inscricao_municipal VARCHAR(20),
  telefone VARCHAR(20),
  email VARCHAR(200),
  contato VARCHAR(100),
  endereco VARCHAR(200),
  numero VARCHAR(20),
  bairro VARCHAR(100),
  cidade VARCHAR(100),
  estado VARCHAR(2),
  cep VARCHAR(10),
  observacoes TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_fornecedores_cnpj (cnpj)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 5: CATEGORIAS
-- ====================================================================
CREATE TABLE IF NOT EXISTS categorias (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL UNIQUE,
  descricao TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 6: PRODUTOS
-- ====================================================================
CREATE TABLE IF NOT EXISTS produtos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  codigo_barras VARCHAR(50) UNIQUE,
  codigo_interno VARCHAR(50) UNIQUE,
  descricao VARCHAR(200) NOT NULL,
  detalhes TEXT,
  categoria_id INT,
  ncm_code VARCHAR(10),
  tributacao VARCHAR(100),
  fornecedor_id INT,
  preco_custo DECIMAL(10,2) NOT NULL DEFAULT 0,
  preco_venda DECIMAL(10,2) NOT NULL,
  margem_lucro DECIMAL(5,2),
  unidade VARCHAR(10) NOT NULL DEFAULT 'un',
  tamanho VARCHAR(20) DEFAULT NULL,
  estoque_atual INT DEFAULT 0,
  estoque_minimo INT DEFAULT 0,
  imagem_path VARCHAR(500),
  thumbnail_path VARCHAR(500),
  ativo TINYINT(1) DEFAULT 1,
  bloqueado TINYINT(1) DEFAULT 0,
  is_combo TINYINT(1) DEFAULT 0,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (categoria_id) REFERENCES categorias(id),
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  INDEX idx_produtos_barras (codigo_barras),
  INDEX idx_produtos_descricao (descricao),
  INDEX idx_produtos_tamanho (tamanho),
  INDEX idx_produtos_ncm (ncm_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 6B: COMBO ITENS (Componentes de produtos combo/kit)
-- ====================================================================
CREATE TABLE IF NOT EXISTS combo_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  combo_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL DEFAULT 1,
  FOREIGN KEY (combo_id) REFERENCES produtos(id) ON DELETE CASCADE,
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  INDEX idx_combo_itens_combo (combo_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 7: HISTÓRICO DE ESTOQUE
-- ====================================================================
CREATE TABLE IF NOT EXISTS historico_estoque (
  id INT PRIMARY KEY AUTO_INCREMENT,
  produto_id INT NOT NULL,
  tipo ENUM('entrada', 'saida') NOT NULL,
  ocorrencia VARCHAR(50) NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  referencia_id INT,
  referencia_tipo VARCHAR(50),
  observacoes TEXT,
  usuario_id INT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_hist_estoque_produto (produto_id),
  INDEX idx_hist_estoque_data (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 8: SERVIÇOS
-- ====================================================================
CREATE TABLE IF NOT EXISTS servicos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  preco DECIMAL(10,2) NOT NULL,
  comissao_fixa DECIMAL(10,2) DEFAULT 0,
  outros_dados TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 9: VENDAS
-- ====================================================================
CREATE TABLE IF NOT EXISTS vendas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL UNIQUE,
  tipo ENUM('Venda', 'Orcamento') NOT NULL DEFAULT 'Venda',
  cliente_id INT,
  usuario_id INT NOT NULL,
  vendedor_id INT,
  total_itens INT NOT NULL DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  desconto_percentual DECIMAL(5,2) DEFAULT 0,
  desconto_valor DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  forma_pagamento VARCHAR(50),
  valor_recebido DECIMAL(10,2),
  troco DECIMAL(10,2) DEFAULT 0,
  status ENUM('finalizada', 'cancelada', 'orcamento') DEFAULT 'finalizada',
  sincronizado_nfce TINYINT(1) DEFAULT 0,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  FOREIGN KEY (vendedor_id) REFERENCES usuarios(id),
  INDEX idx_vendas_data (criado_em),
  INDEX idx_vendas_usuario (usuario_id),
  INDEX idx_vendas_numero (numero),
  INDEX idx_vendas_tipo (tipo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 10: VENDA ITENS
-- ====================================================================
CREATE TABLE IF NOT EXISTS venda_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  produto_id INT,
  servico_id INT,
  quantidade DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  desconto DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) NOT NULL,
  combo_snapshot JSON DEFAULT NULL COMMENT 'Snapshot dos componentes do combo no momento da venda',
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  FOREIGN KEY (servico_id) REFERENCES servicos(id),
  INDEX idx_venda_itens_venda (venda_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 11: ORDENS DE SERVIÇO
-- ====================================================================
CREATE TABLE IF NOT EXISTS ordens_servico (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL UNIQUE,
  prestador_id INT NOT NULL,
  cliente_id INT NOT NULL,
  data_inicio DATETIME NOT NULL,
  data_termino DATETIME,
  detalhes TEXT,
  pedido VARCHAR(100),
  status ENUM('aberta', 'em_andamento', 'finalizada', 'cancelada') DEFAULT 'aberta',
  forma_pagamento VARCHAR(50),
  subtotal DECIMAL(10,2) DEFAULT 0,
  desconto DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) DEFAULT 0,
  texto_padrao TEXT,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (prestador_id) REFERENCES usuarios(id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  INDEX idx_os_numero (numero),
  INDEX idx_os_status (status),
  INDEX idx_os_data (data_inicio)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 12: OS ITENS SERVIÇO
-- ====================================================================
CREATE TABLE IF NOT EXISTS os_itens_servico (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ordem_servico_id INT NOT NULL,
  servico_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL DEFAULT 1,
  preco_unitario DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id),
  FOREIGN KEY (servico_id) REFERENCES servicos(id),
  INDEX idx_os_itens_serv_os (ordem_servico_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 13: OS ITENS PRODUTO
-- ====================================================================
CREATE TABLE IF NOT EXISTS os_itens_produto (
  id INT PRIMARY KEY AUTO_INCREMENT,
  ordem_servico_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (ordem_servico_id) REFERENCES ordens_servico(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  INDEX idx_os_itens_prod_os (ordem_servico_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 14: COMPRAS
-- ====================================================================
CREATE TABLE IF NOT EXISTS compras (
  id INT PRIMARY KEY AUTO_INCREMENT,
  fornecedor_id INT NOT NULL,
  data_compra DATETIME NOT NULL,
  valor_bruto DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_final DECIMAL(10,2) NOT NULL DEFAULT 0,
  forma_pagamento VARCHAR(50),
  chave_nfe VARCHAR(44),
  xml_importado TINYINT(1) DEFAULT 0,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  INDEX idx_compras_fornecedor (fornecedor_id),
  INDEX idx_compras_data (data_compra),
  UNIQUE INDEX idx_compras_chave_nfe (chave_nfe)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 15: COMPRA ITENS
-- ====================================================================
CREATE TABLE IF NOT EXISTS compra_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  compra_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (compra_id) REFERENCES compras(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  INDEX idx_compra_itens_compra (compra_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 16: CAIXAS
-- ====================================================================
CREATE TABLE IF NOT EXISTS caixas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,
  descricao TEXT,
  saldo_atual DECIMAL(10,2) DEFAULT 0,
  ativo TINYINT(1) DEFAULT 1,
  status ENUM('aberto', 'fechado') NOT NULL DEFAULT 'fechado',
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 17: CAIXA MOVIMENTOS
-- ====================================================================
CREATE TABLE IF NOT EXISTS caixa_movimentos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  caixa_id INT NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  tipo ENUM('entrada', 'saida') NOT NULL,
  categoria VARCHAR(50),
  referencia_id INT,
  referencia_tipo VARCHAR(50),
  usuario_id INT,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (caixa_id) REFERENCES caixas(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_caixa_mov_caixa (caixa_id),
  INDEX idx_caixa_mov_data (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 18: CONTAS A PAGAR
-- ====================================================================
CREATE TABLE IF NOT EXISTS contas_pagar (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  tipo VARCHAR(50),
  status ENUM('pendente', 'pago', 'cancelado') DEFAULT 'pendente',
  data_vencimento DATE NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  informacoes TEXT,
  data_pagamento DATE,
  forma_pagamento VARCHAR(50),
  fornecedor_id INT,
  compra_id INT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  FOREIGN KEY (compra_id) REFERENCES compras(id),
  INDEX idx_contas_pagar_venc (data_vencimento),
  INDEX idx_contas_pagar_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 19: CONTAS A RECEBER
-- ====================================================================
CREATE TABLE IF NOT EXISTS contas_receber (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  tipo VARCHAR(50),
  status ENUM('pendente', 'recebido', 'cancelado') DEFAULT 'pendente',
  data_vencimento DATE NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  informacoes TEXT,
  data_recebimento DATE,
  forma_recebimento VARCHAR(50),
  cliente_id INT,
  venda_id INT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  INDEX idx_contas_receber_venc (data_vencimento),
  INDEX idx_contas_receber_status (status),
  INDEX idx_contas_receber_cliente (cliente_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 20: CREDIÁRIO PARCELAS
-- ====================================================================
CREATE TABLE IF NOT EXISTS crediario_parcelas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  cliente_id INT NOT NULL,
  numero_parcela INT NOT NULL,
  total_parcelas INT NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  data_vencimento DATE NOT NULL,
  status ENUM('pendente', 'pago', 'atrasado', 'cancelado') DEFAULT 'pendente',
  data_pagamento DATE,
  forma_pagamento VARCHAR(50),
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  INDEX idx_crediario_venda (venda_id),
  INDEX idx_crediario_cliente (cliente_id),
  INDEX idx_crediario_venc (data_vencimento),
  INDEX idx_crediario_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 20B: VENDA PAGAMENTOS (pagamentos combinados/split)
-- ====================================================================
CREATE TABLE IF NOT EXISTS venda_pagamentos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  forma_pagamento VARCHAR(50) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  INDEX idx_vp_venda (venda_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 21: CONFIGURAÇÕES
-- ====================================================================
CREATE TABLE IF NOT EXISTS configuracoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  chave VARCHAR(100) NOT NULL UNIQUE,
  valor TEXT,
  grupo VARCHAR(50),
  descricao VARCHAR(200),
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_config_chave (chave),
  INDEX idx_config_grupo (grupo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 22: NCM (Nomenclatura Comum do Mercosul)
-- 13.737 registros importados via LOAD DATA do CSV oficial
-- ====================================================================
CREATE TABLE IF NOT EXISTS ncm (
  id INT PRIMARY KEY AUTO_INCREMENT,
  co_ncm VARCHAR(10) NOT NULL UNIQUE,
  co_unid VARCHAR(5),
  co_sh6 VARCHAR(10),
  co_ppe VARCHAR(10),
  co_ppi VARCHAR(10),
  co_fat_agreg VARCHAR(5),
  co_cuci_item VARCHAR(10),
  co_cgce_n3 VARCHAR(10),
  co_siit VARCHAR(10),
  co_isic_classe VARCHAR(10),
  co_exp_subset VARCHAR(10),
  no_ncm_por VARCHAR(500) NOT NULL,
  no_ncm_esp VARCHAR(500),
  no_ncm_ing VARCHAR(500),
  INDEX idx_ncm_code (co_ncm),
  INDEX idx_ncm_sh6 (co_sh6),
  FULLTEXT INDEX idx_ncm_descricao (no_ncm_por)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 23: CONFIGURAÇÃO DA IMPRESSORA TÉRMICA
-- ====================================================================
CREATE TABLE IF NOT EXISTS printer_config (
  id INT PRIMARY KEY AUTO_INCREMENT,
  printer_name VARCHAR(200) NOT NULL,
  connection_type ENUM('usb', 'serial', 'network') NOT NULL,
  port VARCHAR(100),
  ip_address VARCHAR(45),
  tcp_port INT DEFAULT 9100,
  paper_width ENUM('58mm', '80mm') DEFAULT '80mm',
  auto_cut TINYINT(1) DEFAULT 1,
  print_logo TINYINT(1) DEFAULT 0,
  active TINYINT(1) DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 24: DEVOLUÇÕES
-- ====================================================================
CREATE TABLE IF NOT EXISTS devolucoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  cliente_id INT,
  usuario_id INT NOT NULL,
  data_devolucao DATETIME DEFAULT CURRENT_TIMESTAMP,
  motivo VARCHAR(500) NOT NULL,
  tipo ENUM('devolucao', 'troca') NOT NULL DEFAULT 'devolucao',
  status ENUM('pendente', 'aprovada', 'recusada', 'finalizada') DEFAULT 'pendente',
  valor_total DECIMAL(12,2) NOT NULL DEFAULT 0,
  forma_restituicao ENUM('dinheiro', 'credito', 'troca') NOT NULL DEFAULT 'credito',
  credito_gerado DECIMAL(12,2) DEFAULT 0,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_devolucoes_venda (venda_id),
  INDEX idx_devolucoes_status (status),
  INDEX idx_devolucoes_data (data_devolucao)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 25: DEVOLUÇÃO ITENS
-- ====================================================================
CREATE TABLE IF NOT EXISTS devolucao_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  devolucao_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  preco_unitario DECIMAL(12,2) NOT NULL,
  subtotal DECIMAL(12,2) NOT NULL,
  motivo_item VARCHAR(300),
  estado_produto ENUM('novo', 'usado', 'defeito') DEFAULT 'novo',
  retorna_estoque TINYINT(1) DEFAULT 1,
  FOREIGN KEY (devolucao_id) REFERENCES devolucoes(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  INDEX idx_devolucao_itens_dev (devolucao_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 26: CRÉDITOS DE CLIENTE (Vale/Nota de Crédito)
-- ====================================================================
CREATE TABLE IF NOT EXISTS customer_credits (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cliente_id INT NOT NULL,
  devolucao_id INT,
  valor DECIMAL(12,2) NOT NULL,
  valor_utilizado DECIMAL(12,2) DEFAULT 0,
  saldo DECIMAL(12,2) NOT NULL,
  status ENUM('ativo', 'utilizado', 'expirado', 'cancelado') DEFAULT 'ativo',
  data_expiracao DATE,
  observacoes VARCHAR(500),
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (devolucao_id) REFERENCES devolucoes(id),
  INDEX idx_credits_cliente (cliente_id),
  INDEX idx_credits_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 27: CAIXA FECHAMENTOS
-- Registro de fechamentos de caixa com conferência de valores
-- ====================================================================
CREATE TABLE IF NOT EXISTS caixa_fechamentos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  caixa_id INT NOT NULL,
  saldo_inicial DECIMAL(10,2) NOT NULL DEFAULT 0,
  usuario_id INT NOT NULL,
  data_inicio DATETIME NOT NULL,
  data_fim DATETIME NOT NULL,
  total_entradas DECIMAL(10,2) NOT NULL DEFAULT 0,
  total_saidas DECIMAL(10,2) NOT NULL DEFAULT 0,
  saldo_esperado DECIMAL(10,2) NOT NULL DEFAULT 0,
  saldo_informado DECIMAL(10,2),
  diferenca DECIMAL(10,2),
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (caixa_id) REFERENCES caixas(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_fech_caixa (caixa_id),
  INDEX idx_fech_data (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 28: CONSIGNAÇÕES
-- Consignações de saída (para clientes) e entrada (de fornecedores)
-- ====================================================================
CREATE TABLE IF NOT EXISTS consignacoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL UNIQUE,
  tipo ENUM('saida', 'entrada') NOT NULL,
  cliente_id INT,
  fornecedor_id INT,
  usuario_id INT NOT NULL,
  status ENUM('aberta', 'parcial', 'fechada', 'cancelada') DEFAULT 'aberta',
  total_itens INT NOT NULL DEFAULT 0,
  valor_total DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_acertado DECIMAL(10,2) NOT NULL DEFAULT 0,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_consig_tipo (tipo),
  INDEX idx_consig_status (status),
  INDEX idx_consig_cliente (cliente_id),
  INDEX idx_consig_fornecedor (fornecedor_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 29: CONSIGNAÇÃO ITENS
-- ====================================================================
CREATE TABLE IF NOT EXISTS consignacao_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  consignacao_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,
  quantidade_vendida DECIMAL(10,3) DEFAULT 0,
  quantidade_devolvida DECIMAL(10,3) DEFAULT 0,
  preco_unitario DECIMAL(10,2) NOT NULL,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (consignacao_id) REFERENCES consignacoes(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  INDEX idx_consig_itens_consig (consignacao_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 30: CONSIGNAÇÃO ACERTOS
-- Cada acerto parcial ou total de uma consignação
-- ====================================================================
CREATE TABLE IF NOT EXISTS consignacao_acertos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  consignacao_id INT NOT NULL,
  usuario_id INT NOT NULL,
  valor_vendido DECIMAL(10,2) NOT NULL DEFAULT 0,
  forma_pagamento VARCHAR(50),
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (consignacao_id) REFERENCES consignacoes(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_consig_acerto_consig (consignacao_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 31: CONSIGNAÇÃO ACERTO ITENS
-- Detalhe por item em cada acerto
-- ====================================================================
CREATE TABLE IF NOT EXISTS consignacao_acerto_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  acerto_id INT NOT NULL,
  consignacao_item_id INT NOT NULL,
  quantidade_vendida DECIMAL(10,3) DEFAULT 0,
  quantidade_devolvida DECIMAL(10,3) DEFAULT 0,
  valor DECIMAL(10,2) NOT NULL DEFAULT 0,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (acerto_id) REFERENCES consignacao_acertos(id),
  FOREIGN KEY (consignacao_item_id) REFERENCES consignacao_itens(id),
  INDEX idx_consig_acerto_item_acerto (acerto_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ====================================================================
-- TABELA 32: COMISSÕES
-- Registro de comissão de venda por vendedor
-- ====================================================================
CREATE TABLE IF NOT EXISTS comissoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  vendedor_id INT NOT NULL,
  valor_venda DECIMAL(10,2) NOT NULL,
  percentual DECIMAL(5,2) NOT NULL,
  valor_comissao DECIMAL(10,2) NOT NULL,
  status ENUM('ativa', 'cancelada') DEFAULT 'ativa',
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (vendedor_id) REFERENCES usuarios(id),
  INDEX idx_comissao_vendedor (vendedor_id),
  INDEX idx_comissao_status (status),
  INDEX idx_comissao_criado (criado_em)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Reabilitar verificação de FK
SET FOREIGN_KEY_CHECKS = 1;

-- ====================================================================
-- FIM DO SCHEMA - 32 tabelas criadas
-- ====================================================================
