# Mapeamento Completo do Sistema PDV

## Sistema: Facilite (Risko) - Análise para Recriação em Flutter

---

## 1. ESTRUTURA DE MENUS PRINCIPAIS

### 1.1 Menu Sistema
- Trocar Usuário
- Alterar Usuário e Senha
- Administrar Usuários
- Remover Auto Login
- Opções do Sistema
- Permissões de Acesso
- Dados do Emitente (Empresa)
- Frente de Caixa
- Backup do Banco de Dados
- Conexão com Banco de Dados

### 1.2 Menu Cadastros
- Cadastrar Cliente
- Cadastrar Lançamento no Caixa
- Cadastrar Conta a Pagar
- Cadastrar Conta a Receber
- Cadastrar Produto
- Cadastrar Entrada ou Saída (Estoque)
- Cadastrar Fornecedor
- Cadastrar Compra
- Cadastrar Orçamento ou Venda
- Cadastrar Serviço
- Cadastrar Ordem de Serviço

### 1.3 Menu Módulos
- Módulo Clientes
- Módulo Caixa
- Módulo Contas a Pagar
- Módulo Contas a Receber
- Módulo Crediário Próprio
- Módulo Produtos
- Módulo Histórico Estoque
- Módulo Fornecedores
- Módulo Compras
- Módulo Orçamentos e Vendas
- Módulo Serviços
- Módulo Ordens de Serviço

### 1.4 Menu Relatórios
- Relatório de Clientes
- Relatório de Caixa
- Relatório de Contas a Pagar
- Relatório de Contas a Receber
- Relatório de Crediário Próprio
- Relatório de Produtos
- Relatório de Histórico Estoque
- Relatório de Fornecedores
- Relatório de Compras
- Relatório de Orçamentos e Vendas
- Relatório de Serviços
- Relatório de Ordens de Serviço

### 1.5 Menu Ajuda
- Canal de Informações
- Sobre o Facilite

---

## 2. TELA PRINCIPAL - FRENTE DE CAIXA (PDV)

### 2.1 Layout da Tela
- **Cabeçalho**: Campo de busca de produto (código/descrição)
- **Área Principal**: Grid/Listagem de produtos da venda
  - Colunas: PRODUTO, QTD, PREÇO, TOTAL
- **Painel Direito**: 
  - Campo de busca
  - Display de Total (R$ 0,00)
- **Rodapé**: 
  - Usuário logado (Admin)
  - Horário atual
  - Logo da empresa

### 2.2 Atalhos de Teclado (F-Keys)
| Tecla | Função |
|-------|--------|
| F2 | Alterar Quantidade |
| F3 | Consultar Preço |
| F4 | Integração com Balança |
| F8 | Escolher Orçamento/Venda |
| F9 | Finalizar Venda |
| F10 | Informar Cliente |
| F11 | Informar Vendedor |
| F12 | Cancelar Venda |
| Del | Deletar Item |

### 2.3 Funcionalidades do PDV
- Leitura de código de barras
- Busca por descrição
- Alteração de quantidade
- Consulta de preço
- Integração com balança
- Seleção de cliente
- Seleção de vendedor
- Finalização de venda (múltiplas formas de pagamento)
- Cancelamento de venda
- Impressão de recibo

---

## 3. MÓDULOS E FUNCIONALIDADES DETALHADAS

### 3.1 MÓDULO CLIENTES

#### Campos do Cadastro:
- Nome ou Razão Social
- Telefone
- CPF ou CNPJ
- Inscrição Estadual
- CEP
- Endereço
- Número
- Bairro (dropdown)
- Estado (dropdown)
- Cidade (dropdown)
- Outros Dados (textarea)
- Data de Cadastro

#### Funcionalidades:
- Cadastrar novo cliente
- Pesquisar cliente
- Editar cliente
- Excluir cliente
- Relatórios de clientes
- Limite de crédito

---

### 3.2 MÓDULO PRODUTOS

#### Campos do Cadastro:
- Descrição
- Preço de Venda
- Código de Barras ou Código Interno
- Estoque Atual
- Mínimo Estoque
- Unidade (dropdown: Unidade, etc.)
- Categoria (dropdown)
- Preço de Custo
- NCM (Nomenclatura Comum do Mercosul)
- Tributação
- Outros Dados (textarea)
- Imagem do Produto
- Ativo/Inativo
- Bloqueado/Desbloqueado
- Data de Cadastro

#### Funcionalidades:
- Cadastrar produto
- Pesquisar produto
- Editar produto
- Excluir produto
- Importar produtos via XML
- Combinar produtos repetidos
- Definir estoque mínimo para todos
- Alterar margem bruta da importação XML
- Bloquear/Desbloquear produtos
- Relatórios:
  - Listagem Atual
  - Listagem Atual Detalhada
  - Produtos em Falta no Estoque
  - Ranking Geral de Produtos
  - Ranking de Produtos por Data

---

### 3.3 MÓDULO ESTOQUE / HISTÓRICO DE ESTOQUE

#### Campos do Movimento:
- Produto
- Tipo (Entrada/Saída)
- Ocorrência (Venda, Cadastro, Consignação, Ajuste, etc.)
- Quantidade
- Data
- Usuário
- Observações

#### Funcionalidades:
- Registrar entrada de estoque
- Registrar saída de estoque
- Pesquisar entradas e saídas
- Relatório de histórico de estoque
- Visualizar movimentações por produto

---

### 3.4 MÓDULO FORNECEDORES

#### Campos do Cadastro:
- Razão Social
- Telefone
- CNPJ
- Outros Dados (textarea)

#### Funcionalidades:
- Cadastrar fornecedor
- Pesquisar fornecedor
- Editar fornecedor
- Excluir fornecedor
- Escolher fornecedor em compras
- Relatórios de fornecedores

---

### 3.5 MÓDULO COMPRAS

#### Campos do Cadastro:
- Fornecedor (com botão de escolher/lupa)
- Data da Compra
- Produtos (grid com Qtd, Preço, Subtotal)
- Valor Bruto
- Valor Final
- Forma de Pagamento (dropdown: Outros, etc.)
- Observações

#### Funcionalidades:
- Cadastrar compra
- Pesquisar compras
- Editar compra
- Excluir compra
- Importar XML de compra
- Configurar margem bruta automática
- Escolher fornecedor
- Relatórios de compras

---

### 3.6 MÓDULO CAIXA

#### Campos do Lançamento:
- Descrição
- Valor (formato moeda R$)
- Tipo (Entrada/Saída - dropdown)
- Caixa (dropdown: CAIXA, etc.)
- Data (com calendário)

#### Funcionalidades:
- Cadastrar lançamento
- Pesquisar lançamentos
- Filtrar por caixa
- Transferência entre caixas
- Saldos (exibe saldo atual)
- Importação de movimentações bancárias (CSV)
- Relatórios de caixa

---

### 3.7 MÓDULO CONTAS A PAGAR

#### Campos do Cadastro:
- Descrição
- Tipo (A pagar - dropdown)
- Status (Em aberto - dropdown)
- Data de Vencimento (com calendário)
- Valor (formato moeda R$)
- Informações (textarea)
- Data de Pagamento
- Forma de Pagamento

#### Funcionalidades:
- Cadastrar conta
- Pesquisar contas (por descrição)
- Filtrar (Hoje, Em Atraso, Listar Todas)
- Dar baixa (quitar)
- Exibir Total
- Relatórios de contas a pagar

---

### 3.8 MÓDULO CONTAS A RECEBER

#### Campos do Cadastro:
- Descrição
- Tipo (A receber - dropdown)
- Status (Em aberto - dropdown)
- Data de Vencimento (com calendário)
- Valor (formato moeda R$)
- Informações (textarea)
- Data de Recebimento
- Forma de Recebimento

#### Funcionalidades:
- Cadastrar conta
- Pesquisar contas (por descrição)
- Filtrar (Hoje, Em Atraso, Listar Todas)
- Receber (dar baixa)
- Exibir Total
- Relatórios de contas a receber

---

### 3.9 MÓDULO ORÇAMENTOS E VENDAS

#### Campos do Cadastro:
- Tipo (Venda/Orçamento - dropdown)
- Vendedor (dropdown)
- Número
- Data (com calendário)
- Cliente (com botão de escolher/lupa)
- Produtos (grid com Qtd, Preço, Subtotal)
- Forma de Pagamento (dropdown: À vista, etc.)
- Valor Bruto
- Desconto (% ou R$)
- Valor Final
- Observações

#### Funcionalidades:
- Cadastrar orçamento/venda
- Pesquisar orçamentos/vendas
- Editar
- Excluir
- Finalizar orçamento (converter em venda)
- Emitir recibo
- Emitir nota fiscal
- Configurar máximo de desconto permitido
- Comissões (por vendedor, percentual, período)
- Exibir contador (Orçamentos e Vendas: X)
- Relatórios:
  - Listagem atual
  - Ranking de clientes
  - Orçamentos/vendas por data
  - Orçamentos/vendas por cliente
  - Orçamentos/vendas por vendedor
  - Orçamentos/vendas por pagamento

---

### 3.10 MÓDULO SERVIÇOS

#### Campos do Cadastro:
- Descrição
- Preço (formato moeda R$)
- Comissão Fixa (formato moeda R$)
- Outros Dados (textarea)

#### Funcionalidades:
- Cadastrar serviço
- Pesquisar serviço
- Editar serviço
- Excluir serviço
- Ranking de serviços
- Exibir contador (Serviços: X)
- Relatórios de serviços

---

### 3.11 MÓDULO ORDENS DE SERVIÇO (OS)

#### Campos do Cadastro:
- Número da OS
- Prestador/Técnico (dropdown)
- Início (data com calendário)
- Término (data com calendário)
- Cliente (com botão de escolher/lupa)
- Serviços (grid com Qtd, Preço, Subtotal)
- Detalhes (textarea)
- Pedido (com botão de escolher/lupa)
- Status (Em Andamento, etc. - dropdown)
- Pagamento (À vista, etc. - dropdown)
- Serviços (valor total)
- Serviços e Produtos (valor total)
- Texto Padrão (laudo/observações)

#### Funcionalidades:
- Cadastrar OS
- Pesquisar OS
- Editar OS
- Finalizar OS
- Emitir recibo
- Texto padrão configurável
- Comissões
- Exibir contador (Ordens de Serviço: X)
- Relatórios:
  - Listagem atual
  - Ranking de clientes
  - Ranking de prestadores
  - OS por data
  - OS por cliente
  - OS por prestador
  - OS por pagamento

---

### 3.12 MÓDULO CREDIÁRIO PRÓPRIO

#### Funcionalidades:
- Cadastrar venda a prazo
- Controle de parcelas
- Recebimento de parcelas
- Relatórios de crediário

---

## 4. CONFIGURAÇÕES DO SISTEMA (OPÇÕES)

### 4.1 Aba Visual
- Cor de Fundo da interface
- Imagem de Fundo
- Logotipo para Recibos
- Abrir recibos automaticamente

### 4.2 Aba Campos Padrão
- Orçamento ou Venda (padrão)
- Vendedor padrão
- Status OS padrão
- Prestador padrão
- Pagamento padrão
- Bairro padrão
- Estado padrão
- Cidade padrão
- Exibir botões Carnê
- Habilitar campos de atacadista

### 4.3 Aba Frente de Caixa
- Logo
- Impressora padrão
- Título do Impreso
- Nome do Caixa
- Tratar Código Interno
- Configuração do Código Interno
- Confirmar Impressão
- Confirmar Estoque
- Integrar com NFCe

### 4.4 Aba Geral
- Modelo de Nota Fiscal
- Backup Automático na Inicialização
- Otimizar para conexões remotas

---

## 5. PERMISSÕES DE ACESSO

### Níveis de Permissão por Módulo:
- Caixa: Permitido/Bloqueado
- Crediário Próprio: Permitido/Bloqueado
- Histórico Estoque: Permitido/Bloqueado
- Contas Pagar/Receber: Permitido/Bloqueado
- Tributação: Permitido/Bloqueado
- Fornecedores e Compras: Permitido/Bloqueado

---

## 5. PADRÕES DE UI/UX IDENTIFICADOS

### 5.1 Layout das Telas de Cadastro
- **Janela principal**: Lista de registros com colunas principais
- **Botões laterais**: Cadastrar, Pesquisar, Relatório, etc.
- **Contador**: Exibe total de registros no canto inferior direito
- **Janela modal**: Formulário de cadastro/edição

### 5.2 Componentes Comuns
| Componente | Descrição |
|------------|-----------|
| Grid/Listagem | Exibe registros com colunas ordenáveis |
| Botões de Ação | Posicionados à direita da tela |
| Campos de Texto | Com labels acima |
| Dropdowns | Para seleção de valores pré-definidos |
| DatePicker | Ícone de calendário ao lado do campo de data |
| Botão Lupa | Para pesquisar/selecionar registros relacionados |
| Botão OK/Cancelar | Verde (OK) e cinza (Cancelar) |
| Formato Moeda | R$ 0,00 |

### 5.3 Padrão de Cores
- **Botão OK**: Verde com ícone de check
- **Botão Cancelar**: Cinza
- **Linha selecionada**: Azul (#1976D2)
- **Cabeçalho**: Azul escuro

### 5.4 Ícones da Toolbar Principal
- OS (Ordem de Serviço)
- Checklist (Cadastros)
- Carrinho (Vendas)
- Caixa/Notas (Financeiro)
- Cifrão ($) (Caixa)

### 5.5 Formatos de Dados
- **Data**: DD/MM/AAAA
- **Moeda**: R$ 0,00
- **CPF/CNPJ**: Formatado com pontos e traços
- **Telefone**: Formatado com parênteses e traço

---

## 6. ESTRUTURA DE BANCO DE DADOS (TABELAS)

### 6.1 TABELA: usuarios
```sql
CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL,
    login VARCHAR(50) NOT NULL UNIQUE,
    senha VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    ativo BOOLEAN DEFAULT 1,
    admin BOOLEAN DEFAULT 0,
    perm_caixa VARCHAR(20) DEFAULT 'Permitido',
    perm_crediario VARCHAR(20) DEFAULT 'Permitido',
    perm_estoque VARCHAR(20) DEFAULT 'Permitido',
    perm_contas VARCHAR(20) DEFAULT 'Permitido',
    perm_tributacao VARCHAR(20) DEFAULT 'Permitido',
    perm_fornecedores VARCHAR(20) DEFAULT 'Permitido',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.2 TABELA: emitente (Dados da Empresa)
```sql
CREATE TABLE emitente (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    razao_social VARCHAR(150) NOT NULL,
    nome_fantasia VARCHAR(150),
    cnpj VARCHAR(20),
    regime_tributario VARCHAR(50),
    inscricao_estadual VARCHAR(20),
    inscricao_municipal VARCHAR(20),
    endereco VARCHAR(150),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50),
    cidade VARCHAR(50),
    estado VARCHAR(2),
    cep VARCHAR(10),
    telefone VARCHAR(20),
    email VARCHAR(100),
    site VARCHAR(100),
    logo_path VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.3 TABELA: clientes
```sql
CREATE TABLE clientes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tipo_pessoa VARCHAR(1) DEFAULT 'F', -- F/J
    nome_razao VARCHAR(150) NOT NULL,
    cpf_cnpj VARCHAR(20),
    rg_ie VARCHAR(20),
    telefone VARCHAR(20),
    celular VARCHAR(20),
    email VARCHAR(100),
    cep VARCHAR(10),
    endereco VARCHAR(150),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50),
    cidade VARCHAR(50),
    estado VARCHAR(2),
    observacoes TEXT,
    data_cadastro DATE,
    ativo BOOLEAN DEFAULT 1,
    limite_credito DECIMAL(10,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.4 TABELA: fornecedores
```sql
CREATE TABLE fornecedores (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    razao_social VARCHAR(150) NOT NULL,
    nome_fantasia VARCHAR(150),
    cnpj VARCHAR(20),
    inscricao_estadual VARCHAR(20),
    inscricao_municipal VARCHAR(20),
    telefone VARCHAR(20),
    email VARCHAR(100),
    contato VARCHAR(100),
    cep VARCHAR(10),
    endereco VARCHAR(150),
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50),
    cidade VARCHAR(50),
    estado VARCHAR(2),
    observacoes TEXT,
    ativo BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.5 TABELA: categorias
```sql
CREATE TABLE categorias (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    ativo BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.6 TABELA: produtos
```sql
CREATE TABLE produtos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    codigo_interno VARCHAR(50) UNIQUE,
    codigo_barras VARCHAR(50),
    descricao VARCHAR(200) NOT NULL,
    descricao_curta VARCHAR(100),
    categoria_id INTEGER,
    fornecedor_id INTEGER,
    preco_custo DECIMAL(10,2) DEFAULT 0,
    preco_venda DECIMAL(10,2) DEFAULT 0,
    margem_lucro DECIMAL(5,2) DEFAULT 0,
    estoque_atual DECIMAL(10,3) DEFAULT 0,
    estoque_minimo DECIMAL(10,3) DEFAULT 0,
    unidade_medida VARCHAR(10) DEFAULT 'UN',
    imagem_path VARCHAR(255),
    ativo BOOLEAN DEFAULT 1,
    bloqueado BOOLEAN DEFAULT 0,
    observacoes TEXT,
    data_cadastro DATE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id)
);
```

### 6.7 TABELA: historico_estoque
```sql
CREATE TABLE historico_estoque (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    produto_id INTEGER NOT NULL,
    tipo VARCHAR(10) NOT NULL, -- ENTRADA/SAIDA
    ocorrencia VARCHAR(50), -- Venda, Cadastro, Consignacao, Ajuste, etc
    quantidade DECIMAL(10,3) NOT NULL,
    estoque_anterior DECIMAL(10,3),
    estoque_atual DECIMAL(10,3),
    usuario_id INTEGER,
    observacoes TEXT,
    data_movimento DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (produto_id) REFERENCES produtos(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);
```

### 6.8 TABELA: servicos
```sql
CREATE TABLE servicos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao VARCHAR(200) NOT NULL,
    preco DECIMAL(10,2) DEFAULT 0,
    categoria_id INTEGER,
    tempo_estimado INTEGER, -- em minutos
    ativo BOOLEAN DEFAULT 1,
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id)
);
```

### 6.9 TABELA: vendas
```sql
CREATE TABLE vendas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero INTEGER,
    tipo VARCHAR(20) DEFAULT 'Venda', -- Venda/Orcamento
    data_venda DATETIME DEFAULT CURRENT_TIMESTAMP,
    cliente_id INTEGER,
    vendedor_id INTEGER,
    forma_pagamento VARCHAR(50),
    valor_bruto DECIMAL(10,2) DEFAULT 0,
    desconto_valor DECIMAL(10,2) DEFAULT 0,
    desconto_percentual DECIMAL(5,2) DEFAULT 0,
    valor_final DECIMAL(10,2) DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Finalizada', -- Finalizada/Cancelada/Pendente
    observacoes TEXT,
    sincronizado_nfce BOOLEAN DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (vendedor_id) REFERENCES usuarios(id)
);
```

### 6.10 TABELA: venda_itens
```sql
CREATE TABLE venda_itens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    venda_id INTEGER NOT NULL,
    produto_id INTEGER,
    servico_id INTEGER,
    quantidade DECIMAL(10,3) NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    desconto DECIMAL(10,2) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venda_id) REFERENCES vendas(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id),
    FOREIGN KEY (servico_id) REFERENCES servicos(id)
);
```

### 6.11 TABELA: ordens_servico
```sql
CREATE TABLE ordens_servico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    numero INTEGER,
    data_inicio DATETIME DEFAULT CURRENT_TIMESTAMP,
    data_finalizacao DATETIME,
    cliente_id INTEGER,
    prestador_id INTEGER,
    status VARCHAR(20) DEFAULT 'Aberta', -- Aberta/Em Andamento/Finalizada/Cancelada
    valor_servicos DECIMAL(10,2) DEFAULT 0,
    valor_produtos DECIMAL(10,2) DEFAULT 0,
    valor_total DECIMAL(10,2) DEFAULT 0,
    texto_padrao TEXT,
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (prestador_id) REFERENCES usuarios(id)
);
```

### 6.12 TABELA: os_itens_servico
```sql
CREATE TABLE os_itens_servico (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    os_id INTEGER NOT NULL,
    servico_id INTEGER NOT NULL,
    quantidade DECIMAL(10,2) DEFAULT 1,
    valor_unitario DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (os_id) REFERENCES ordens_servico(id) ON DELETE CASCADE,
    FOREIGN KEY (servico_id) REFERENCES servicos(id)
);
```

### 6.13 TABELA: os_itens_produto
```sql
CREATE TABLE os_itens_produto (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    os_id INTEGER NOT NULL,
    produto_id INTEGER NOT NULL,
    quantidade DECIMAL(10,3) NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (os_id) REFERENCES ordens_servico(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);
```

### 6.14 TABELA: compras
```sql
CREATE TABLE compras (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    fornecedor_id INTEGER,
    data_compra DATE,
    forma_pagamento VARCHAR(50),
    valor_bruto DECIMAL(10,2) DEFAULT 0,
    valor_final DECIMAL(10,2) DEFAULT 0,
    observacoes TEXT,
    xml_importado BOOLEAN DEFAULT 0,
    chave_nfe VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id)
);
```

### 6.15 TABELA: compra_itens
```sql
CREATE TABLE compra_itens (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    compra_id INTEGER NOT NULL,
    produto_id INTEGER,
    quantidade DECIMAL(10,3) NOT NULL,
    valor_unitario DECIMAL(10,2) NOT NULL,
    valor_total DECIMAL(10,2) NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (compra_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (produto_id) REFERENCES produtos(id)
);
```

### 6.16 TABELA: caixas
```sql
CREATE TABLE caixas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    nome VARCHAR(50) NOT NULL,
    descricao VARCHAR(100),
    ativo BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 6.17 TABELA: caixa_movimentos
```sql
CREATE TABLE caixa_movimentos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    caixa_id INTEGER NOT NULL,
    descricao VARCHAR(200) NOT NULL,
    valor DECIMAL(10,2) NOT NULL,
    tipo VARCHAR(10) NOT NULL, -- ENTRADA/SAIDA
    data_movimento DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario_id INTEGER,
    venda_id INTEGER,
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (caixa_id) REFERENCES caixas(id),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
    FOREIGN KEY (venda_id) REFERENCES vendas(id)
);
```

### 6.18 TABELA: contas_pagar
```sql
CREATE TABLE contas_pagar (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao VARCHAR(200) NOT NULL,
    fornecedor_id INTEGER,
    valor DECIMAL(10,2) NOT NULL,
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    status VARCHAR(20) DEFAULT 'Pendente', -- Pendente/Pago/Em Atraso
    forma_pagamento VARCHAR(50),
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id)
);
```

### 6.19 TABELA: contas_receber
```sql
CREATE TABLE contas_receber (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    descricao VARCHAR(200) NOT NULL,
    cliente_id INTEGER,
    venda_id INTEGER,
    valor DECIMAL(10,2) NOT NULL,
    data_vencimento DATE NOT NULL,
    data_recebimento DATE,
    status VARCHAR(20) DEFAULT 'Pendente', -- Pendente/Recebido/Em Atraso
    forma_recebimento VARCHAR(50),
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (cliente_id) REFERENCES clientes(id),
    FOREIGN KEY (venda_id) REFERENCES vendas(id)
);
```

### 6.20 TABELA: crediario_parcelas
```sql
CREATE TABLE crediario_parcelas (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    venda_id INTEGER NOT NULL,
    parcela_numero INTEGER,
    valor DECIMAL(10,2) NOT NULL,
    data_vencimento DATE NOT NULL,
    data_pagamento DATE,
    status VARCHAR(20) DEFAULT 'Pendente',
    valor_pago DECIMAL(10,2) DEFAULT 0,
    juros DECIMAL(10,2) DEFAULT 0,
    observacoes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venda_id) REFERENCES vendas(id)
);
```

### 6.21 TABELA: configuracoes
```sql
CREATE TABLE configuracoes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    chave VARCHAR(100) NOT NULL UNIQUE,
    valor TEXT,
    descricao VARCHAR(200),
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

---

## 7. INTEGRAÇÕES NECESSÁRIAS

### 7.1 Impressora Térmica/Recibo
- Biblioteca para impressão direta
- Suporte a ESC/POS
- Configuração de porta (USB, Serial, Rede)
- Preview de impressão

### 7.2 Gaveta de Dinheiro
- Acionamento via impressora (sinal pulse)
- Comando padrão ESC/POS
- Configuração de porta

### 7.3 Balança
- Protocolo de comunicação serial
- Leitura automática do peso
- Configuração de porta COM
- Baud rate, bits de dados, paridade

### 7.4 Leitor de Código de Barras
- Suporte a USB HID (teclado)
- Suporte a serial

### 7.5 NFC-e (Nota Fiscal)
- Integração com emissor de NFC-e
- Geração de XML
- Transmissão para SEFAZ

### 7.6 Importação de XML
- Parser de XML de NFe
- Leitura de produtos
- Cálculo automático de preços com margem

---

## 8. RELATÓRIOS DISPONÍVEIS

### 8.1 Relatórios de Produtos
- Listagem Atual
- Listagem Atual Detalhada
- Produtos em Falta no Estoque
- Ranking Geral de Produtos
- Ranking de Produtos por Data

### 8.2 Relatórios de Vendas
- Listagem de Orçamentos e Vendas
- Ranking de Clientes
- Vendas por Data
- Vendas por Cliente
- Vendas por Vendedor
- Vendas por Forma de Pagamento

### 8.3 Relatórios de Serviços/OS
- Listagem de Ordens de Serviço
- Ranking de Clientes (OS)
- Ranking de Prestadores
- OS por Data
- OS por Cliente
- OS por Prestador
- OS por Pagamento

### 8.4 Relatórios Financeiros
- Relatório de Caixa
- Relatório de Contas a Pagar
- Relatório de Contas a Receber
- Relatório de Crediário

### 8.5 Relatórios de Estoque
- Histórico de Movimentações
- Entradas e Saídas

---

## 9. FLUXOS DE TRABALHO PRINCIPAIS

### 9.1 Fluxo de Venda no PDV
1. Abrir Frente de Caixa
2. Ler código de barras ou buscar produto
3. Adicionar produtos à lista
4. (Opcional) Informar cliente (F10)
5. (Opcional) Informar vendedor (F11)
6. Finalizar venda (F9)
7. Selecionar forma de pagamento
8. Confirmar e imprimir recibo

### 9.2 Fluxo de Compra com Importação XML
1. Acessar Módulo Compras
2. Clicar em Importar XML
3. Selecionar arquivo XML da NFe
4. Sistema lê produtos e atualiza estoque
5. Configurar margem bruta de lucro
6. Preços de venda são calculados automaticamente
7. Finalizar compra

### 9.3 Fluxo de Ordem de Serviço
1. Cadastrar nova OS
2. Selecionar cliente
3. Selecionar prestador
4. Adicionar serviços
5. Adicionar produtos utilizados
6. (Opcional) Adicionar texto padrão
7. Finalizar OS
8. Emitir recibo

---

## 10. RECURSOS ADICIONAIS

### 10.1 Backup Automático
- Backup na inicialização (opcional)
- Backup manual
- Agendamento de backups

### 10.2 Multi-Caixa
- Cadastro de múltiplos caixas
- Transferência entre caixas
- Controle de saldo por caixa

### 10.3 Controle de Comissões
- Cadastro de percentual por vendedor
- Cálculo automático de comissões
- Relatório de comissões

### 10.4 Descontos Configuráveis
- Máximo de desconto por forma de pagamento
- Controle de permissões para descontos

---

## 11. TECNOLOGIAS RECOMENDADAS PARA FLUTTER

### 11.1 Banco de Dados Local
- **SQLite** (sqflite package) - Para dados principais
- **Hive** - Para cache e configurações
- **Drift** - ORM alternativo para SQLite

### 11.2 Impressão
- **esc_pos_utils** + **flutter_bluetooth_serial** ou **usb_serial**
- **printing** - Para preview e impressão PDF

### 11.3 Comunicação Serial (Balança)
- **flutter_libserialport** ou **usb_serial**

### 11.4 Geração de PDF/Recibos
- **pdf** package
- **printing** package

### 11.5 Leitura de XML
- **xml** package

### 11.6 Gerenciamento de Estado
- **Riverpod** ou **Bloc**

### 11.7 Interface
- **Flutter** desktop (Windows)
- **fluent_ui** ou **macos_ui** para interface nativa

---

## 12. CONSIDERAÇÕES PARA DESENVOLVIMENTO

### 12.1 Arquitetura Recomendada
- Clean Architecture
- Repository Pattern
- Dependency Injection

### 12.2 Estrutura de Pastas
```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── usecases/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── bloc/
│   ├── pages/
│   └── widgets/
└── main.dart
```

### 12.3 Funcionalidades Prioritárias (MVP)
1. Cadastro de produtos com imagem
2. Frente de caixa (PDV) completo
3. Controle de estoque
4. Cadastro de clientes
5. Vendas e orçamentos
6. Relatórios básicos
7. Impressão de recibos

### 12.4 Funcionalidades Secundárias
1. Ordens de serviço
2. Contas a pagar/receber
3. Crediário próprio
4. Importação de XML
5. Integração com balança
6. NFC-e

---

**Documento gerado em:** 24/02/2026  
**Versão:** 1.0  
**Total de Tabelas:** 21  
**Total de Módulos:** 12  
**Total de Funcionalidades:** 100+
