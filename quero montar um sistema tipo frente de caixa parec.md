# Menuly PDV - Especificação Completa do Sistema

Você está basicamente descrevendo um **PDV local + backoffice completo** baseado no **Facilite (Risko)**: rodando em .exe Windows, com imagens otimizadas e API HTTP local para integrar um app. O sistema conta com **12 módulos**, **25+ tabelas no banco de dados** e **100+ funcionalidades** mapeadas a partir do sistema Facilite. Tecnologias: Flutter Desktop + MySQL/MariaDB + Dart Shelf + ESC/POS.[^1]

---

# 📊 FASE 1: Módulos do Sistema

O Menuly PDV é composto por **12 módulos principais**, cada um com funcionalidades completas de CRUD, relatórios e integrações entre si.

---

## Módulo 1: Frente de Caixa (PDV)

### Layout da Tela Principal

```
┌──────────────────────────────────────────────────────────────────────────────┐
│  ██ MENULY PDV ██        FRENTE DE CAIXA         Caixa: 01    F9=Finalizar  │
│  Produto atual: PÃO FRANCÊS                      Preço: R$ 0,75            │
├──────────────────────────────────────────┬───────────────────────────────────┤
│  # │ PRODUTO              │ QTD │ PREÇO  │ TOTAL  │  ┌─────────────────────┐│
│  1 │ Arroz Tio João 5kg   │  2  │ 24,90  │  49,80 │  │ [_______________]   ││
│  2 │ Feijão Carioca 1kg   │  3  │  8,50  │  25,50 │  │  Código de Barras   ││
│  3 │ Óleo de Soja 900ml   │  1  │  7,90  │   7,90 │  │                     ││
│  4 │ Açúcar Cristal 1kg   │  2  │  5,20  │  10,40 │  │  ┌───────────────┐  ││
│    │                      │     │        │        │  │  │               │  ││
│    │                      │     │        │        │  │  │  TOTAL:       │  ││
│    │                      │     │        │        │  │  │  R$ 93,60     │  ││
│    │                      │     │        │        │  │  │               │  ││
│    │                      │     │        │        │  │  └───────────────┘  ││
├──────────────────────────────────────────┴───────────────────────────────────┤
│  Operador: Maria Silva    │  14:35:22  │  13/02/2026  │  [LOGO MENULY]      │
└──────────────────────────────────────────────────────────────────────────────┘
```

- **Header azul**: nome do sistema, produto atual em destaque, preço unitário
- **Tabela central**: colunas PRODUTO / QTD / PREÇO / TOTAL
- **Painel direito**: campo de código de barras + total em destaque
- **Footer**: operador logado, hora, data, logotipo

### Atalhos de Teclado

| Tecla | Ação |
|-------|------|
| **F2** | Alterar Quantidade do item selecionado |
| **F3** | Consultar Preço (busca sem adicionar ao carrinho) |
| **F4** | Balança (ler peso da balança serial) |
| **F6** | Troca/Devolução (abre modal de devolução rápida no PDV) |
| **F8** | Escolher Orçamento (importar orçamento salvo) |
| **F9** | Finalizar Venda (abre tela de pagamento) |
| **F10** | Informar Cliente (vincular CPF/CNPJ à venda) |
| **F11** | Informar Vendedor (vincular vendedor para comissão) |
| **F12** | Cancelar Venda inteira |
| **Del** | Deletar Item selecionado da lista |
| **Enter** | Confirmar código de barras / adicionar item |
| **Esc** | Voltar / fechar diálogo |

### Funcionalidades

- Leitura de código de barras via leitor USB (simula teclado)
- Busca por descrição do produto (campo de pesquisa)
- Múltiplas formas de pagamento na mesma venda (split payment)
- Cálculo automático de troco
- Impressão de cupom não fiscal na impressora térmica
- Integração com balança serial (F4)
- Importação de orçamento salvo (F8)
- Vinculação de cliente e vendedor à venda
- Desconto por item ou desconto geral (conforme permissão do usuário)
- Troca/devolução rápida via F6 (busca venda, seleciona itens, gera crédito ou inicia troca)
- Utilização de crédito/vale como forma de pagamento

---

## Módulo 2: Produtos

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Descrição | VARCHAR(200) | Sim | Nome do produto |
| Preço Venda | DECIMAL(10,2) | Sim | Preço de venda ao consumidor |
| Código de Barras | VARCHAR(50) | Não | EAN-13, CODE128, etc. |
| Código Interno | VARCHAR(50) | Não | Código interno da loja |
| Estoque Atual | INT | Sim | Quantidade em estoque |
| Mínimo Estoque | INT | Não | Quantidade mínima para alerta |
| Unidade | VARCHAR(10) | Sim | un, kg, l, m, cx, pct |
| Categoria | FK categorias | Sim | Categoria do produto |
| Preço Custo | DECIMAL(10,2) | Sim | Preço de custo/compra |
| NCM | VARCHAR(10) | Não* | Código NCM (obrigatório para NF-e) |
| Tributação | VARCHAR(100) | Não | Informações tributárias |
| Fornecedor | FK fornecedores | Não | Fornecedor principal |
| Margem de Lucro | DECIMAL(5,2) | Auto | Calculada: (venda - custo) / custo * 100 |
| Outros Dados | TEXT | Não | Observações gerais |
| Imagem | VARCHAR(500) | Não | Caminho da imagem do produto |
| Ativo/Inativo | TINYINT(1) | Sim | Status do produto |
| Bloqueado | TINYINT(1) | Sim | Impede venda se bloqueado |
| Data Cadastro | DATETIME | Auto | Data de criação |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, inativar produtos
- **Importação via XML**: Importar produtos a partir de XML de NF-e de compra
- **Combinar repetidos**: Mesclar cadastros duplicados de um mesmo produto
- **Definir estoque mínimo para todos**: Aplicar um valor mínimo de estoque em lote
- **Alterar margem bruta**: Recalcular preço de venda com base em nova margem
- **Bloquear/Desbloquear**: Impedir ou liberar a venda de produtos específicos
- **Otimização de imagens**: Ao cadastrar, gerar thumbnail (256x256) comprimido

### Relatórios

- **Listagem Atual**: Todos os produtos ativos com estoque, preço e categoria
- **Listagem Detalhada**: Todos os campos, incluindo custo, margem, NCM, fornecedor
- **Produtos em Falta**: Produtos com estoque abaixo do mínimo configurado
- **Ranking Geral**: Produtos mais vendidos (por quantidade e por faturamento)
- **Ranking por Data**: Ranking de vendas filtrado por período

---

## Módulo 3: Clientes

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Nome / Razão Social | VARCHAR(200) | Sim | Nome completo ou razão social |
| Telefone | VARCHAR(20) | Não | Telefone de contato |
| CPF / CNPJ | VARCHAR(18) | Não | Documento (PF ou PJ) |
| Inscrição Estadual | VARCHAR(20) | Não | IE para pessoa jurídica |
| CEP | VARCHAR(10) | Não | CEP do endereço |
| Endereço | VARCHAR(200) | Não | Logradouro |
| Número | VARCHAR(20) | Não | Número do endereço |
| Bairro | VARCHAR(100) | Não | Bairro |
| Estado | VARCHAR(2) | Não | UF (sigla) |
| Cidade | VARCHAR(100) | Não | Cidade |
| Outros Dados | TEXT | Não | Observações |
| Data Cadastro | DATETIME | Auto | Data de criação |
| Limite de Crédito | DECIMAL(10,2) | Não | Limite para crediário |
| Tipo Pessoa | ENUM('F','J') | Sim | Física ou Jurídica |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, excluir clientes
- **Pesquisar**: Busca por nome, CPF/CNPJ, telefone
- **Relatórios**: Listagem de clientes, histórico de compras por cliente
- **Limite de crédito**: Definir e controlar limite para compras no crediário
- **Vincular a vendas**: Associar cliente na finalização da venda (F10 no PDV)

---

## Módulo 4: Fornecedores

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Razão Social | VARCHAR(200) | Sim | Razão social da empresa |
| Nome Fantasia | VARCHAR(200) | Não | Nome fantasia |
| CNPJ | VARCHAR(18) | Sim | CNPJ do fornecedor |
| Inscrição Estadual | VARCHAR(20) | Não | IE do fornecedor |
| Inscrição Municipal | VARCHAR(20) | Não | IM do fornecedor |
| Telefone | VARCHAR(20) | Não | Telefone de contato |
| Email | VARCHAR(200) | Não | E-mail de contato |
| Contato | VARCHAR(100) | Não | Nome da pessoa de contato |
| Endereço | VARCHAR(200) | Não | Logradouro completo |
| Número | VARCHAR(20) | Não | Número |
| Bairro | VARCHAR(100) | Não | Bairro |
| Cidade | VARCHAR(100) | Não | Cidade |
| Estado | VARCHAR(2) | Não | UF |
| CEP | VARCHAR(10) | Não | CEP |
| Observações | TEXT | Não | Notas gerais |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, excluir fornecedores
- **Vincular a compras**: Associar fornecedor nas compras realizadas
- **Vincular a produtos**: Definir fornecedor principal de cada produto
- **Relatórios**: Listagem de fornecedores, compras por fornecedor

---

## Módulo 5: Compras

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Fornecedor | FK fornecedores | Sim | Fornecedor da compra |
| Data | DATETIME | Sim | Data da compra |
| Produtos (grid) | Relação | Sim | Lista de itens comprados |
| Valor Bruto | DECIMAL(10,2) | Auto | Soma dos itens |
| Valor Final | DECIMAL(10,2) | Sim | Valor efetivamente pago |
| Forma Pagamento | VARCHAR(50) | Sim | Forma de pagamento |
| Observações | TEXT | Não | Notas sobre a compra |
| Chave NF-e | VARCHAR(44) | Não | Chave de acesso da NF-e |
| XML Importado | TINYINT(1) | Auto | Se foi importado de XML |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar compras
- **Importar XML de NF-e**: Ler XML da nota fiscal e preencher automaticamente fornecedor, produtos, quantidades e valores
- **Cálculo automático de margem bruta**: Ao registrar custo, calcular margem em relação ao preço de venda
- **Entrada automática de estoque**: Ao confirmar compra, dar entrada no estoque
- **Relatórios**: Listagem de compras, compras por fornecedor, por período

---

## Módulo 6: Estoque / Histórico

### Campos do Movimento

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Produto | FK produtos | Sim | Produto movimentado |
| Tipo | ENUM | Sim | Entrada ou Saída |
| Ocorrência | VARCHAR(50) | Sim | Venda, Cadastro, Consignação, Ajuste, Compra, Devolução |
| Quantidade | DECIMAL(10,3) | Sim | Quantidade movimentada |
| Data | DATETIME | Auto | Data do movimento |
| Usuário | FK usuarios | Auto | Quem realizou |
| Observações | TEXT | Não | Justificativa/notas |

### Funcionalidades

- **Registrar entrada**: Entrada manual de estoque (compra, ajuste, devolução)
- **Registrar saída**: Saída manual (perda, ajuste, consignação)
- **Movimentação automática**: Vendas e compras geram movimentos automaticamente
- **Pesquisar**: Filtrar por produto, tipo, período, usuário
- **Relatório de histórico**: Visualizar todas as movimentações com filtros
- **Visualizar por produto**: Ver todo o histórico de um produto específico
- **Alertas de estoque mínimo**: Destaque em vermelho para produtos abaixo do mínimo

---

## Módulo 7: Caixa (Multi-caixa)

### Campos do Lançamento

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Descrição | VARCHAR(200) | Sim | Descrição do lançamento |
| Valor (R$) | DECIMAL(10,2) | Sim | Valor do lançamento |
| Tipo | ENUM | Sim | Entrada ou Saída |
| Caixa | FK caixas | Sim | Caixa destino (dropdown) |
| Data | DATETIME | Auto | Data do lançamento |
| Usuário | FK usuarios | Auto | Quem registrou |
| Observações | TEXT | Não | Notas adicionais |

### Funcionalidades

- **Lançamentos**: Registrar entradas e saídas manuais no caixa (sangria, suprimento, despesas)
- **Pesquisar**: Filtrar lançamentos por data, tipo, caixa
- **Filtrar por caixa**: Cada caixa físico tem seu controle independente
- **Transferência entre caixas**: Mover valores de um caixa para outro
- **Saldos**: Visualizar saldo atual de cada caixa em tempo real
- **Importação CSV bancário**: Importar extrato bancário em CSV para conciliação
- **Relatórios**: Resumo por caixa, por período, movimentações detalhadas
- **Fechamento de caixa**: Totalizar por forma de pagamento, comparar esperado x realizado

---

## Módulo 8: Contas a Pagar

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Descrição | VARCHAR(200) | Sim | Descrição da conta |
| Tipo | VARCHAR(50) | Não | Categoria (aluguel, fornecedor, etc.) |
| Status | ENUM | Sim | Pendente, Pago, Cancelado |
| Data Vencimento | DATE | Sim | Data de vencimento |
| Valor | DECIMAL(10,2) | Sim | Valor da conta |
| Informações | TEXT | Não | Detalhes adicionais |
| Data Pagamento | DATE | Não | Data em que foi pago |
| Forma Pagamento | VARCHAR(50) | Não | Como foi pago |

### Funcionalidades

- **Cadastrar**: Registrar novas contas a pagar
- **Pesquisar**: Busca por descrição, fornecedor, período
- **Filtrar**: Vencendo hoje, em atraso, todas as contas
- **Dar baixa**: Registrar pagamento (data + forma de pagamento)
- **Exibir total**: Mostrar total pendente, total pago, total em atraso
- **Relatórios**: Contas por período, por status, por tipo

---

## Módulo 9: Contas a Receber

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Descrição | VARCHAR(200) | Sim | Descrição da conta |
| Tipo | VARCHAR(50) | Não | Categoria (venda, serviço, etc.) |
| Status | ENUM | Sim | Pendente, Recebido, Cancelado |
| Data Vencimento | DATE | Sim | Data de vencimento |
| Valor | DECIMAL(10,2) | Sim | Valor a receber |
| Cliente | FK clientes | Não | Cliente devedor |
| Venda | FK vendas | Não | Venda de origem |
| Informações | TEXT | Não | Detalhes adicionais |
| Data Recebimento | DATE | Não | Data em que foi recebido |
| Forma Recebimento | VARCHAR(50) | Não | Como foi recebido |

### Funcionalidades

- **Cadastrar**: Registrar novas contas a receber
- **Pesquisar**: Busca por cliente, descrição, período
- **Filtrar**: Vencendo hoje, em atraso, todas as contas
- **Dar baixa**: Registrar recebimento (data + forma)
- **Vincular a vendas/clientes**: Contas geradas automaticamente a partir de vendas a prazo
- **Exibir total**: Total pendente, total recebido, total em atraso
- **Relatórios**: Contas por período, por cliente, por status

---

## Módulo 10: Orçamentos e Vendas

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Tipo | ENUM | Sim | Venda ou Orçamento |
| Vendedor | FK usuarios | Não | Vendedor responsável (para comissão) |
| Número | VARCHAR(20) | Auto | Número sequencial |
| Data | DATETIME | Auto | Data da venda/orçamento |
| Cliente | FK clientes | Não | Cliente vinculado |
| Produtos (grid) | Relação | Sim | Lista de itens |
| Forma Pagamento | VARCHAR(50) | Sim* | Obrigatório para venda |
| Valor Bruto | DECIMAL(10,2) | Auto | Soma dos itens |
| Desconto (% ou R$) | DECIMAL(10,2) | Não | Desconto aplicado |
| Valor Final | DECIMAL(10,2) | Auto | Bruto - desconto |
| Observações | TEXT | Não | Notas adicionais |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, cancelar vendas e orçamentos
- **Converter orçamento em venda**: Transformar orçamento salvo em venda efetiva (F8 no PDV)
- **Emitir recibo**: Gerar e imprimir recibo da venda
- **Emitir NF**: Integração futura com NFC-e/NF-e
- **Comissões**: Calcular comissão do vendedor sobre a venda
- **Máximo desconto configurável**: Limitar desconto por perfil de usuário
- **Split payment**: Múltiplas formas de pagamento na mesma venda

### Relatórios

- **Listagem**: Todas as vendas/orçamentos com filtros
- **Ranking de Clientes**: Clientes que mais compraram
- **Por Data**: Vendas filtradas por período
- **Por Cliente**: Histórico de compras de um cliente
- **Por Vendedor**: Vendas por vendedor (para comissão)
- **Por Forma de Pagamento**: Totalizado por forma de pagamento

---

## Módulo 11: Serviços

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Descrição | VARCHAR(200) | Sim | Nome/descrição do serviço |
| Preço | DECIMAL(10,2) | Sim | Valor cobrado pelo serviço |
| Comissão Fixa | DECIMAL(10,2) | Não | Valor fixo de comissão ao prestador |
| Outros Dados | TEXT | Não | Observações |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, excluir serviços
- **Vincular a OS**: Associar serviços às Ordens de Serviço
- **Ranking**: Serviços mais realizados
- **Relatórios**: Listagem de serviços, faturamento por serviço

---

## Módulo 12: Ordens de Serviço (OS)

### Campos do Cadastro

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| Número OS | VARCHAR(20) | Auto | Número sequencial da OS |
| Prestador/Técnico | FK usuarios | Sim | Responsável pela execução |
| Início | DATETIME | Sim | Data/hora de início |
| Término | DATETIME | Não | Data/hora de conclusão |
| Cliente | FK clientes | Sim | Cliente da OS |
| Serviços (grid) | Relação | Sim | Lista de serviços prestados |
| Produtos (grid) | Relação | Não | Materiais/peças utilizados |
| Detalhes | TEXT | Não | Descrição detalhada do trabalho |
| Pedido | VARCHAR(100) | Não | Referência do pedido do cliente |
| Status | ENUM | Sim | Aberta, Em Andamento, Finalizada, Cancelada |
| Pagamento | VARCHAR(50) | Não | Forma de pagamento |
| Texto Padrão | TEXT | Não | Texto pré-configurado (termos, garantia) |

### Funcionalidades

- **CRUD completo**: Criar, visualizar, editar, cancelar OS
- **Finalizar OS**: Marcar como concluída e gerar financeiro
- **Emitir recibo**: Gerar e imprimir recibo da OS
- **Comissões**: Calcular comissão do prestador/técnico
- **Texto padrão configurável**: Template de termos, garantia, condições
- **Produtos + Serviços**: Combinar materiais e mão-de-obra na mesma OS

### Relatórios

- **Listagem**: Todas as OS com filtros de status/data
- **Ranking de Clientes**: Clientes com mais OS
- **Ranking de Prestadores**: Prestadores/técnicos mais produtivos
- **Por Data**: OS filtradas por período
- **Por Cliente**: Histórico de OS de um cliente
- **Por Prestador**: OS por técnico/prestador
- **Por Forma de Pagamento**: Totalizado por forma de pagamento

---

## Crediário Próprio

O sistema permite **venda a prazo** com controle de parcelas, sem necessidade de cartão de crédito externo.

### Funcionamento

1. **Na venda**: O operador seleciona "Crediário" como forma de pagamento
2. **Parcelamento**: Define número de parcelas, valor de cada parcela e datas de vencimento
3. **Vinculação ao cliente**: Obrigatório informar o cliente (F10)
4. **Limite de crédito**: O sistema verifica se o cliente tem limite disponível
5. **Geração de parcelas**: Cada parcela vira uma "conta a receber" com data de vencimento

### Controle de Parcelas

- Visualizar parcelas pendentes por cliente
- Dar baixa em parcelas (recebimento parcial ou total)
- Relatório de inadimplência (parcelas em atraso)
- Bloqueio automático de crediário quando há parcelas vencidas

---

## Módulo 13: Trocas e Devoluções

O sistema possui um fluxo completo para **devoluções** e **trocas** de produtos vendidos.

### Fluxo de Devolução

1. **Localizar venda original** por: código da venda, data, CPF/CNPJ ou nome do cliente
2. **Selecionar itens** a devolver e quantidade de cada
3. **Escolher tipo**:
   - **Devolução com estorno**: gera movimento de entrada no estoque + estorno financeiro (dinheiro, estorno no cartão ou crédito na loja)
   - **Troca por outro produto**: gera entrada do devolvido + saída do novo produto
4. **Registrar motivo** (obrigatório): defeito, arrependimento, erro de operação, tamanho errado, produto avariado
5. **Autorização**: Se o operador não tiver permissão, precisa de autorização do gerente/admin (senha de supervisão)
6. **Impressão**: Gerar comprovante de devolução/troca na impressora térmica

### Campos da Devolução

| Campo | Tipo | Obrigatório | Observação |
|-------|------|-------------|------------|
| Venda Original | INT (FK) | Sim | Referência à venda onde o item foi comprado |
| Tipo | ENUM | Sim | 'devolucao' ou 'troca' |
| Motivo | VARCHAR | Sim | Defeito, arrependimento, erro, tamanho, avariado |
| Data | DATETIME | Sim | Data/hora da devolução |
| Usuário que autorizou | INT (FK) | Sim | Quem autorizou (operador ou gerente) |
| Observações | TEXT | Não | Detalhes adicionais |

### Campos dos Itens da Devolução

| Campo | Tipo | Obrigatório | Observação |
|-------|------|-------------|------------|
| Produto devolvido | INT (FK) | Sim | Produto que está sendo devolvido |
| Quantidade devolvida | DECIMAL | Sim | Quanto está voltando |
| Produto de troca | INT (FK) | Não | Novo produto (somente em trocas) |
| Quantidade troca | DECIMAL | Não | Quantidade do novo produto |
| Diferença de valor | DECIMAL | Não | Valor a pagar ou receber na troca |

### Regras de Negócio

- Não é possível devolver mais do que a quantidade vendida no item original
- Devoluções geram **movimento de entrada** automático no estoque (ocorrência: "Devolução")
- Trocas geram **entrada** do devolvido + **saída** do novo produto
- Se o produto de troca for mais caro, o cliente paga a diferença
- Se for mais barato, gera **crédito na loja** (`customer_credits`) ou estorno
- O sistema registra quem autorizou a operação (auditoria)
- Prazo máximo para devolução pode ser configurado nas configurações do sistema

### Acesso pelo Frente de Caixa (F6)

O módulo de Trocas e Devoluções é acessível **diretamente do PDV** via tecla **F6**, sem precisar sair da tela de frente de caixa:

1. **F6 → Modal de Devolução Rápida**:
   - Campo para digitar número da venda original ou escanear código de barras do cupom
   - Exibe dados da venda (data, cliente, itens, valores)
   - Checkboxes para selecionar itens a devolver com campo de quantidade
   - Seleção do tipo (Devolução / Troca) e forma de restituição

2. **Fluxo de Troca no PDV**:
   - Após processar a devolução dos itens antigos, o sistema **inicia automaticamente uma nova venda**
   - O crédito gerado pela devolução é **aplicado como desconto/pagamento** na nova venda
   - Se o cliente levar produtos de valor maior, paga apenas a diferença
   - Se levar de valor menor, o saldo restante vira crédito/vale

3. **Crédito como Forma de Pagamento**:
   - Na tela de pagamento (F9), aparece opção "Crédito/Vale" se o cliente tiver saldo
   - O operador pode usar crédito parcial ou total
   - Combinável com outras formas (ex: R$30 crédito + R$20 dinheiro)

4. **Verificação automática**:
   - Ao informar cliente (F10), o PDV mostra aviso se há créditos disponíveis
   - Badge no rodapé do PDV: "Cliente tem R$ XX,XX em créditos"

### Notas de Crédito / Vale

- Quando o cliente opta por não receber estorno imediato, o sistema gera um **crédito em nome do cliente**
- O crédito fica vinculado ao CPF/CNPJ e pode ser utilizado em compras futuras
- O PDV verifica automaticamente se o cliente tem créditos ao informar o cliente (F10)
- Créditos podem ter data de expiração configurável
- Relatório de créditos pendentes por cliente

### Relatórios de Devoluções

- **Listagem de devoluções**: Por período, por motivo, por operador
- **Ranking de motivos**: Quais os motivos mais frequentes
- **Impacto financeiro**: Total devolvido por período
- **Produtos mais devolvidos**: Ranking para identificar problemas de qualidade

---

# Estrutura de Menus

O sistema organiza suas funcionalidades em **5 menus principais**:

## Menu 1: Sistema

| Item | Descrição |
|------|-----------|
| Trocar Usuário | Fazer logout e entrar com outro usuário |
| Alterar Senha | Alterar senha do usuário atual |
| Administrar Usuários | CRUD de usuários (somente admin) |
| Remover Auto Login | Desativar login automático |
| Opções do Sistema | Configurações gerais do sistema |
| Permissões de Acesso | Definir permissões por módulo/usuário |
| Dados do Emitente | Dados da empresa (CNPJ, endereço, logo) |
| Frente de Caixa | Abrir o PDV |
| Backup BD | Realizar backup do banco de dados |
| Conexão BD | Configurar conexão com MySQL |

## Menu 2: Cadastros

| Item | Descrição |
|------|-----------|
| Cliente | Cadastro de clientes |
| Lançamento Caixa | Lançar entrada/saída no caixa |
| Conta a Pagar | Cadastrar conta a pagar |
| Conta a Receber | Cadastrar conta a receber |
| Produto | Cadastro de produtos |
| Entrada/Saída Estoque | Registrar movimentação de estoque |
| Fornecedor | Cadastro de fornecedores |
| Compra | Registrar compra de mercadoria |
| Orçamento/Venda | Cadastrar orçamento ou venda |
| Serviço | Cadastro de serviços |
| Ordem de Serviço | Cadastrar ordem de serviço |

## Menu 3: Módulos

| Item | Descrição |
|------|-----------|
| Frente de Caixa | Módulo PDV completo |
| Produtos | Gerenciamento de produtos |
| Clientes | Gerenciamento de clientes |
| Fornecedores | Gerenciamento de fornecedores |
| Compras | Gerenciamento de compras |
| Estoque/Histórico | Controle de estoque |
| Caixa | Controle financeiro de caixa |
| Contas a Pagar | Gestão de contas a pagar |
| Contas a Receber | Gestão de contas a receber |
| Orçamentos e Vendas | Gestão de vendas e orçamentos |
| Serviços | Cadastro de serviços |
| Ordens de Serviço | Gestão de OS |
| Crediário | Controle de crediário próprio |
| Trocas e Devoluções | Gestão de trocas, devoluções e créditos |

## Menu 4: Relatórios

| Item | Descrição |
|------|-----------|
| Relatório de Produtos | Listagem, ranking, falta |
| Relatório de Clientes | Listagem, histórico |
| Relatório de Fornecedores | Listagem, compras |
| Relatório de Compras | Por período, fornecedor |
| Relatório de Estoque | Posição atual, movimentações |
| Relatório de Caixa | Fechamento, movimentações |
| Relatório de Contas a Pagar | Por status, período |
| Relatório de Contas a Receber | Por status, cliente |
| Relatório de Vendas | Por período, vendedor, cliente |
| Relatório de Serviços | Ranking, faturamento |
| Relatório de OS | Por prestador, cliente, período |
| Relatório de Crediário | Inadimplência, parcelas |
| Relatório de Devoluções | Por período, motivo, produto |

## Menu 5: Ajuda

| Item | Descrição |
|------|-----------|
| Canal de Informações | Links para suporte, tutoriais |
| Sobre | Versão do sistema, créditos |

---

# Permissões de Acesso

O sistema controla o acesso por módulo para cada usuário. O administrador pode habilitar ou desabilitar o acesso a cada área:

| Permissão | Campo no BD | Descrição |
|-----------|-------------|-----------|
| **Caixa** | perm_caixa | Acesso à Frente de Caixa e lançamentos de caixa |
| **Crediário** | perm_crediario | Acesso ao módulo de crediário e parcelas |
| **Histórico Estoque** | perm_estoque | Acesso ao histórico de movimentações de estoque |
| **Contas Pagar/Receber** | perm_contas | Acesso aos módulos financeiros |
| **Tributação** | perm_tributacao | Acesso a configurações tributárias e NCM |
| **Fornecedores e Compras** | perm_fornecedores | Acesso a fornecedores e registro de compras |

### Níveis de Acesso

- **Administrador**: Acesso total a todos os módulos e configurações
- **Gerente**: Acesso configurável, geralmente todos os módulos exceto configurações do sistema
- **Operador de Caixa**: Acesso restrito ao PDV e consultas básicas
- **Vendedor**: Acesso ao PDV, orçamentos e vendas

### Regras

- Cada permissão é um campo TINYINT(1) na tabela `usuarios`
- O admin pode configurar as permissões na tela "Permissões de Acesso"
- Menus e botões são ocultados automaticamente conforme as permissões
- Tentativas de acesso não autorizado são registradas em log

---

# Configurações do Sistema

O sistema possui uma tela de configurações dividida em abas:

## Aba Visual

| Configuração | Descrição |
|-------------|-----------|
| Cor de Fundo | Cor de fundo da aplicação (color picker) |
| Imagem de Fundo | Imagem de fundo personalizada (opcional) |
| Logotipo para Recibos | Imagem do logo impresso nos cupons/recibos |

## Aba Campos Padrão

| Configuração | Descrição |
|-------------|-----------|
| Orçamento/Venda Padrão | Tipo padrão ao abrir nova venda (Orçamento ou Venda) |
| Vendedor Padrão | Vendedor pré-selecionado em novas vendas |
| Status OS Padrão | Status inicial de novas Ordens de Serviço |
| Prestador Padrão | Prestador/técnico pré-selecionado em novas OS |
| Pagamento Padrão | Forma de pagamento pré-selecionada |
| Bairro Padrão | Bairro padrão para novos cadastros |
| Estado Padrão | UF padrão para novos cadastros |
| Cidade Padrão | Cidade padrão para novos cadastros |

## Aba Frente de Caixa

| Configuração | Descrição |
|-------------|-----------|
| Logo do PDV | Imagem exibida no rodapé do PDV |
| Impressora | Configuração da impressora térmica |
| Título Impresso | Texto do cabeçalho no cupom impresso |
| Nome do Caixa | Identificação do caixa (ex: "Caixa 01") |
| Código Interno | Usar código interno em vez de código de barras |
| Confirmar Impressão | Perguntar antes de imprimir cupom |
| Confirmar Estoque | Verificar estoque antes de vender |
| Integrar NFC-e | Habilitar integração com Nota Fiscal ao Consumidor |

## Aba Geral

| Configuração | Descrição |
|-------------|-----------|
| Modelo NF | Modelo de Nota Fiscal (NFC-e, NF-e, SAT) |
| Backup Automático | Ativar/desativar backup automático do BD |
| Intervalo Backup | Intervalo entre backups (horas) |
| Otimizar Conexões Remotas | Compressão e cache para conexões de rede |

---

# Integrações de Hardware

O Menuly PDV suporta **5 tipos de integração com hardware**:

## 1. Impressora Térmica (ESC/POS)

| Aspecto | Detalhe |
|---------|---------|
| **Protocolo** | ESC/POS (padrão da indústria) |
| **Conexão** | USB/Serial (COM), Rede TCP/IP (porta 9100) |
| **Marcas** | Epson, Bematech, Elgin, Daruma, Sweda |
| **Largura** | 80mm (padrão) ou 58mm |
| **Uso** | Impressão de cupons não fiscais e recibos |
| **Recursos** | Texto formatado, negrito, centralizado, guilhotina automática |

## 2. Gaveta de Dinheiro (Pulse via Impressora)

| Aspecto | Detalhe |
|---------|---------|
| **Protocolo** | Comando ESC/POS de pulso elétrico |
| **Conexão** | Via impressora térmica (conector RJ-11) |
| **Comando** | `ESC p 0 25 250` (pulso no pino 2) |
| **Uso** | Abertura automática ao finalizar venda em dinheiro |
| **Configuração** | Ativar/desativar na config da impressora |

## 3. Balança (Serial/COM)

| Aspecto | Detalhe |
|---------|---------|
| **Protocolo** | Serial RS-232 (protocolo Toledo/Filizola) |
| **Conexão** | Porta Serial COM ou adaptador USB-Serial |
| **Baud Rate** | 4800 ou 9600 (conforme modelo) |
| **Uso** | Leitura de peso para produtos vendidos por kg |
| **Atalho** | F4 no PDV para ler peso da balança |
| **Marcas** | Toledo, Filizola, Urano |

## 4. Leitor de Código de Barras (USB HID)

| Aspecto | Detalhe |
|---------|---------|
| **Protocolo** | USB HID (simula teclado) |
| **Conexão** | USB plug-and-play |
| **Formatos** | EAN-13, CODE128, CODE39, UPC-A, QR Code |
| **Uso** | Leitura de código de barras dos produtos no PDV |
| **Implementação** | O leitor envia caracteres como teclado; o campo de barcode captura automaticamente |

## 5. NFC-e (XML/SEFAZ)

| Aspecto | Detalhe |
|---------|---------|
| **Protocolo** | Web Service SEFAZ (XML SOAP) |
| **Certificado** | Certificado digital A1 (arquivo .pfx) |
| **Uso** | Emissão de Nota Fiscal do Consumidor Eletrônica |
| **Status** | Integração futura (preparar campos no BD) |
| **Campos preparados** | sincronizado_nfce, chave_nfe na tabela vendas |

---

# 📊 FASE 1: Banco de Dados (MySQL/MariaDB)

## Por que MySQL em vez de SQLite?

| Critério | SQLite | MySQL/MariaDB |
|----------|--------|---------------|
| Multi-caixa (rede local) | Não suporta bem | Suporta nativamente via TCP |
| Backup | Copiar arquivo | `mysqldump` robusto + replicação |
| Tipos monetários | `REAL` (float impreciso) | `DECIMAL(10,2)` (precisão exata) |
| Concorrência | Lock no arquivo inteiro | Lock por registro (InnoDB) |
| Instalação | Zero config | Requer instalar MySQL/MariaDB |
| Performance em loja única | Excelente | Excelente |

**Decisão: MySQL/MariaDB** - melhor para cenários com múltiplos caixas e precisão monetária.

## Configuração do MySQL

### Requisitos:
- **MySQL 8.0+** ou **MariaDB 10.6+**
- Porta padrão: `3306` (localhost)
- Charset: `utf8mb4` (suporte completo a caracteres especiais)

### Criação do banco:
```sql
CREATE DATABASE menuly_pdv
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER 'pdv_user'@'localhost' IDENTIFIED BY 'senha_segura_aqui';
GRANT ALL PRIVILEGES ON menuly_pdv.* TO 'pdv_user'@'localhost';
FLUSH PRIVILEGES;

USE menuly_pdv;
```

## Schema Completo (MySQL) - 23 Tabelas

```sql
-- ====================================================================
-- TABELA 1: USUÁRIOS
-- Operadores do sistema com permissões por módulo
-- ====================================================================
CREATE TABLE usuarios (
  id INT PRIMARY KEY AUTO_INCREMENT,
  login VARCHAR(50) NOT NULL UNIQUE,
  senha_hash VARCHAR(255) NOT NULL,           -- bcrypt recomendado
  nome VARCHAR(100) NOT NULL,
  papel ENUM('admin', 'gerente', 'operador', 'vendedor') NOT NULL DEFAULT 'operador',
  max_desconto DECIMAL(5,2) DEFAULT 0.10,     -- 10% máximo de desconto permitido
  -- Permissões por módulo
  perm_caixa TINYINT(1) DEFAULT 1,            -- acesso à Frente de Caixa
  perm_crediario TINYINT(1) DEFAULT 0,        -- acesso ao Crediário
  perm_estoque TINYINT(1) DEFAULT 0,          -- acesso ao Histórico de Estoque
  perm_contas TINYINT(1) DEFAULT 0,           -- acesso a Contas Pagar/Receber
  perm_tributacao TINYINT(1) DEFAULT 0,       -- acesso a configurações tributárias
  perm_fornecedores TINYINT(1) DEFAULT 0,     -- acesso a Fornecedores e Compras
  ativo TINYINT(1) DEFAULT 1,
  auto_login TINYINT(1) DEFAULT 0,            -- login automático ao iniciar
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 2: EMITENTE (Dados da Empresa)
-- Informações da empresa para NF-e, recibos e configurações
-- ====================================================================
CREATE TABLE emitente (
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
  logo_path VARCHAR(500),                     -- caminho do logotipo
  regime_tributario ENUM('simples', 'presumido', 'real') DEFAULT 'simples',
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 3: CLIENTES
-- Cadastro completo com endereço e controle de crédito
-- ====================================================================
CREATE TABLE clientes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(200) NOT NULL,                 -- nome ou razão social
  tipo_pessoa ENUM('F', 'J') NOT NULL DEFAULT 'F', -- Física ou Jurídica
  cpf_cnpj VARCHAR(18) UNIQUE,               -- CPF ou CNPJ formatado
  inscricao_estadual VARCHAR(20),
  telefone VARCHAR(20),
  email VARCHAR(200),
  cep VARCHAR(10),
  endereco VARCHAR(200),
  numero VARCHAR(20),
  bairro VARCHAR(100),
  cidade VARCHAR(100),
  estado VARCHAR(2),
  limite_credito DECIMAL(10,2) DEFAULT 0.00,  -- limite para crediário
  outros_dados TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_clientes_cpf (cpf_cnpj),
  INDEX idx_clientes_nome (nome)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 4: FORNECEDORES
-- Cadastro completo de fornecedores
-- ====================================================================
CREATE TABLE fornecedores (
  id INT PRIMARY KEY AUTO_INCREMENT,
  razao_social VARCHAR(200) NOT NULL,
  nome_fantasia VARCHAR(200),
  cnpj VARCHAR(18) UNIQUE,
  inscricao_estadual VARCHAR(20),
  inscricao_municipal VARCHAR(20),
  telefone VARCHAR(20),
  email VARCHAR(200),
  contato VARCHAR(100),                       -- pessoa de contato
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 5: CATEGORIAS
-- Categorias de produtos
-- ====================================================================
CREATE TABLE categorias (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL UNIQUE,
  descricao TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 6: PRODUTOS
-- Cadastro completo com NCM, tributação, fornecedor e margem
-- ====================================================================
CREATE TABLE produtos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  codigo_barras VARCHAR(50) UNIQUE,           -- EAN-13, CODE128, etc.
  codigo_interno VARCHAR(50) UNIQUE,          -- código interno da loja
  descricao VARCHAR(200) NOT NULL,
  detalhes TEXT,
  categoria_id INT,
  ncm_code VARCHAR(10),                       -- código NCM (ref tabela ncm)
  tributacao VARCHAR(100),                    -- informações tributárias
  fornecedor_id INT,                          -- fornecedor principal
  preco_custo DECIMAL(10,2) NOT NULL DEFAULT 0,
  preco_venda DECIMAL(10,2) NOT NULL,
  margem_lucro DECIMAL(5,2),                  -- calculada: (venda-custo)/custo*100
  unidade VARCHAR(10) NOT NULL DEFAULT 'un',  -- un, kg, l, m, cx, pct
  estoque_atual INT DEFAULT 0,
  estoque_minimo INT DEFAULT 0,
  imagem_path VARCHAR(500),                   -- caminho da imagem original
  thumbnail_path VARCHAR(500),                -- caminho do thumbnail (256x256)
  ativo TINYINT(1) DEFAULT 1,
  bloqueado TINYINT(1) DEFAULT 0,             -- se bloqueado, impede venda
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (categoria_id) REFERENCES categorias(id),
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  INDEX idx_produtos_barras (codigo_barras),
  INDEX idx_produtos_descricao (descricao),
  INDEX idx_produtos_ncm (ncm_code)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 7: HISTÓRICO DE ESTOQUE
-- Movimentações de entrada e saída com auditoria
-- ====================================================================
CREATE TABLE historico_estoque (
  id INT PRIMARY KEY AUTO_INCREMENT,
  produto_id INT NOT NULL,
  tipo ENUM('entrada', 'saida') NOT NULL,
  ocorrencia VARCHAR(50) NOT NULL,            -- venda, cadastro, consignacao, ajuste, compra, devolucao
  quantidade DECIMAL(10,3) NOT NULL,
  referencia_id INT,                          -- id da venda/compra/ajuste
  referencia_tipo VARCHAR(50),                -- 'venda', 'compra', 'ajuste', etc.
  observacoes TEXT,
  usuario_id INT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_hist_estoque_produto (produto_id),
  INDEX idx_hist_estoque_data (criado_em)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 8: SERVIÇOS
-- Cadastro de serviços prestados
-- ====================================================================
CREATE TABLE servicos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  preco DECIMAL(10,2) NOT NULL,
  comissao_fixa DECIMAL(10,2) DEFAULT 0,      -- comissão fixa ao prestador
  outros_dados TEXT,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 9: VENDAS
-- Cabeçalho de vendas e orçamentos
-- ====================================================================
CREATE TABLE vendas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL UNIQUE,         -- número sequencial (ex: 000001)
  tipo ENUM('Venda', 'Orcamento') NOT NULL DEFAULT 'Venda',
  cliente_id INT,                             -- NULL se venda anônima
  usuario_id INT NOT NULL,                    -- operador que registrou
  vendedor_id INT,                            -- vendedor (para comissão)
  total_itens INT NOT NULL DEFAULT 0,
  subtotal DECIMAL(10,2) NOT NULL DEFAULT 0,
  desconto_percentual DECIMAL(5,2) DEFAULT 0, -- desconto em %
  desconto_valor DECIMAL(10,2) DEFAULT 0,     -- desconto em R$
  total DECIMAL(10,2) NOT NULL,
  forma_pagamento VARCHAR(50),                -- dinheiro, cartao, pix, cheque, crediario
  valor_recebido DECIMAL(10,2),               -- valor recebido (para troco)
  troco DECIMAL(10,2) DEFAULT 0,
  status ENUM('finalizada', 'cancelada', 'orcamento') DEFAULT 'finalizada',
  sincronizado_nfce TINYINT(1) DEFAULT 0,    -- se já emitiu NFC-e
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 10: VENDA ITENS
-- Itens de cada venda (produtos e/ou serviços)
-- ====================================================================
CREATE TABLE venda_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,
  produto_id INT,                             -- produto vendido (pode ser NULL se for serviço)
  servico_id INT,                             -- serviço vendido (pode ser NULL se for produto)
  quantidade DECIMAL(10,3) NOT NULL,          -- pode ser fração (kg)
  preco_unitario DECIMAL(10,2) NOT NULL,      -- preço no momento da venda
  desconto DECIMAL(10,2) DEFAULT 0,           -- desconto por item
  total DECIMAL(10,2) NOT NULL,               -- (quantidade * preco_unitario) - desconto
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id),
  FOREIGN KEY (servico_id) REFERENCES servicos(id),
  INDEX idx_venda_itens_venda (venda_id)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 11: ORDENS DE SERVIÇO
-- Cabeçalho das OS
-- ====================================================================
CREATE TABLE ordens_servico (
  id INT PRIMARY KEY AUTO_INCREMENT,
  numero VARCHAR(20) NOT NULL UNIQUE,         -- número sequencial da OS
  prestador_id INT NOT NULL,                  -- técnico/prestador responsável
  cliente_id INT NOT NULL,
  data_inicio DATETIME NOT NULL,
  data_termino DATETIME,
  detalhes TEXT,
  pedido VARCHAR(100),                        -- referência do pedido do cliente
  status ENUM('aberta', 'em_andamento', 'finalizada', 'cancelada') DEFAULT 'aberta',
  forma_pagamento VARCHAR(50),
  subtotal DECIMAL(10,2) DEFAULT 0,
  desconto DECIMAL(10,2) DEFAULT 0,
  total DECIMAL(10,2) DEFAULT 0,
  texto_padrao TEXT,                          -- termos, garantia, condições
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (prestador_id) REFERENCES usuarios(id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  INDEX idx_os_numero (numero),
  INDEX idx_os_status (status),
  INDEX idx_os_data (data_inicio)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 12: OS ITENS SERVIÇO
-- Serviços vinculados a cada OS
-- ====================================================================
CREATE TABLE os_itens_servico (
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 13: OS ITENS PRODUTO
-- Produtos/materiais utilizados em cada OS
-- ====================================================================
CREATE TABLE os_itens_produto (
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 14: COMPRAS
-- Registro de compras de mercadoria
-- ====================================================================
CREATE TABLE compras (
  id INT PRIMARY KEY AUTO_INCREMENT,
  fornecedor_id INT NOT NULL,
  data_compra DATETIME NOT NULL,
  valor_bruto DECIMAL(10,2) NOT NULL DEFAULT 0,
  valor_final DECIMAL(10,2) NOT NULL DEFAULT 0,
  forma_pagamento VARCHAR(50),
  chave_nfe VARCHAR(44),                      -- chave de acesso da NF-e
  xml_importado TINYINT(1) DEFAULT 0,         -- se foi importado de XML
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  INDEX idx_compras_fornecedor (fornecedor_id),
  INDEX idx_compras_data (data_compra)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 15: COMPRA ITENS
-- Itens de cada compra
-- ====================================================================
CREATE TABLE compra_itens (
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 16: CAIXAS
-- Caixas físicos do estabelecimento
-- ====================================================================
CREATE TABLE caixas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  nome VARCHAR(100) NOT NULL,                 -- ex: "Caixa 01", "Caixa 02"
  descricao TEXT,
  saldo_atual DECIMAL(10,2) DEFAULT 0,
  ativo TINYINT(1) DEFAULT 1,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 17: CAIXA MOVIMENTOS
-- Lançamentos de entrada/saída nos caixas
-- ====================================================================
CREATE TABLE caixa_movimentos (
  id INT PRIMARY KEY AUTO_INCREMENT,
  caixa_id INT NOT NULL,
  descricao VARCHAR(200) NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  tipo ENUM('entrada', 'saida') NOT NULL,
  categoria VARCHAR(50),                      -- venda, sangria, suprimento, despesa
  referencia_id INT,                          -- id da venda, se for automático
  referencia_tipo VARCHAR(50),                -- 'venda', 'manual', 'transferencia'
  usuario_id INT,
  observacoes TEXT,
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (caixa_id) REFERENCES caixas(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
  INDEX idx_caixa_mov_caixa (caixa_id),
  INDEX idx_caixa_mov_data (criado_em)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 18: CONTAS A PAGAR
-- Controle de contas a pagar
-- ====================================================================
CREATE TABLE contas_pagar (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  tipo VARCHAR(50),                           -- aluguel, fornecedor, salario, outros
  status ENUM('pendente', 'pago', 'cancelado') DEFAULT 'pendente',
  data_vencimento DATE NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  informacoes TEXT,
  data_pagamento DATE,
  forma_pagamento VARCHAR(50),
  fornecedor_id INT,                          -- fornecedor relacionado (opcional)
  compra_id INT,                              -- compra relacionada (opcional)
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (fornecedor_id) REFERENCES fornecedores(id),
  FOREIGN KEY (compra_id) REFERENCES compras(id),
  INDEX idx_contas_pagar_venc (data_vencimento),
  INDEX idx_contas_pagar_status (status)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 19: CONTAS A RECEBER
-- Controle de contas a receber
-- ====================================================================
CREATE TABLE contas_receber (
  id INT PRIMARY KEY AUTO_INCREMENT,
  descricao VARCHAR(200) NOT NULL,
  tipo VARCHAR(50),                           -- venda, servico, crediario, outros
  status ENUM('pendente', 'recebido', 'cancelado') DEFAULT 'pendente',
  data_vencimento DATE NOT NULL,
  valor DECIMAL(10,2) NOT NULL,
  informacoes TEXT,
  data_recebimento DATE,
  forma_recebimento VARCHAR(50),
  cliente_id INT,                             -- cliente relacionado
  venda_id INT,                               -- venda relacionada (opcional)
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  INDEX idx_contas_receber_venc (data_vencimento),
  INDEX idx_contas_receber_status (status),
  INDEX idx_contas_receber_cliente (cliente_id)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 20: CREDIÁRIO PARCELAS
-- Controle de parcelas do crediário próprio
-- ====================================================================
CREATE TABLE crediario_parcelas (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,                      -- venda de origem
  cliente_id INT NOT NULL,                    -- cliente devedor
  numero_parcela INT NOT NULL,                -- 1, 2, 3...
  total_parcelas INT NOT NULL,                -- total de parcelas
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
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 21: CONFIGURAÇÕES
-- Configurações do sistema em formato chave/valor
-- ====================================================================
CREATE TABLE configuracoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  chave VARCHAR(100) NOT NULL UNIQUE,         -- ex: 'cor_fundo', 'vendedor_padrao'
  valor TEXT,                                 -- valor da configuração
  grupo VARCHAR(50),                          -- visual, campos_padrao, pdv, geral
  descricao VARCHAR(200),
  criado_em DATETIME DEFAULT CURRENT_TIMESTAMP,
  atualizado_em DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_config_chave (chave),
  INDEX idx_config_grupo (grupo)
) ENGINE=InnoDB;

-- ====================================================================
-- TABELA 22: NCM (Nomenclatura Comum do Mercosul)
-- Fonte: CSV oficial do governo (13.737 registros)
-- Necessária para classificação fiscal dos produtos e emissão de
-- documentos fiscais (NF-e, SAT, cupom fiscal). O código NCM compõe
-- o código de barras EAN-13 na classificação do produto.
-- ====================================================================
CREATE TABLE ncm (
  id INT PRIMARY KEY AUTO_INCREMENT,
  co_ncm VARCHAR(10) NOT NULL UNIQUE,       -- código NCM (8 dígitos, ex: "90183930")
  co_unid VARCHAR(5),                       -- código da unidade estatística
  co_sh6 VARCHAR(10),                       -- código SH6 (6 primeiros dígitos do NCM)
  co_ppe VARCHAR(10),                       -- código PPE (Pauta de Produtos Exportados)
  co_ppi VARCHAR(10),                       -- código PPI (Pauta de Produtos Importados)
  co_fat_agreg VARCHAR(5),                  -- fator agregado
  co_cuci_item VARCHAR(10),                 -- código CUCI (Classificação Uniforme Comércio Internacional)
  co_cgce_n3 VARCHAR(10),                   -- código CGCE nível 3
  co_siit VARCHAR(10),                      -- código SIIT
  co_isic_classe VARCHAR(10),               -- código ISIC (classificação industrial)
  co_exp_subset VARCHAR(10),                -- subconjunto de exportação
  no_ncm_por VARCHAR(500) NOT NULL,         -- descrição em português
  no_ncm_esp VARCHAR(500),                  -- descrição em espanhol
  no_ncm_ing VARCHAR(500),                  -- descrição em inglês
  INDEX idx_ncm_code (co_ncm),
  INDEX idx_ncm_sh6 (co_sh6),
  FULLTEXT INDEX idx_ncm_descricao (no_ncm_por)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ====================================================================
-- TABELA 23: CONFIGURAÇÃO DA IMPRESSORA TÉRMICA
-- Configurações de impressoras ESC/POS
-- ====================================================================
CREATE TABLE printer_config (
  id INT PRIMARY KEY AUTO_INCREMENT,
  printer_name VARCHAR(200) NOT NULL,         -- nome/modelo da impressora
  connection_type ENUM('usb', 'serial', 'network') NOT NULL,
  port VARCHAR(100),                          -- COM3, /dev/ttyUSB0, etc.
  ip_address VARCHAR(45),                     -- para impressoras de rede
  tcp_port INT DEFAULT 9100,                  -- porta TCP padrão
  paper_width ENUM('58mm', '80mm') DEFAULT '80mm',
  auto_cut TINYINT(1) DEFAULT 1,
  print_logo TINYINT(1) DEFAULT 0,
  active TINYINT(1) DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- =============================================
-- TROCAS E DEVOLUÇÕES
-- =============================================

CREATE TABLE devolucoes (
  id INT PRIMARY KEY AUTO_INCREMENT,
  venda_id INT NOT NULL,                          -- venda original
  cliente_id INT,                                 -- cliente (se identificado)
  usuario_id INT NOT NULL,                        -- operador que processou
  data_devolucao DATETIME DEFAULT CURRENT_TIMESTAMP,
  motivo VARCHAR(500) NOT NULL,                   -- motivo da devolução/troca
  tipo ENUM('devolucao', 'troca') NOT NULL DEFAULT 'devolucao',
  status ENUM('pendente', 'aprovada', 'recusada', 'finalizada') DEFAULT 'pendente',
  valor_total DECIMAL(12,2) NOT NULL DEFAULT 0,   -- valor total devolvido
  forma_restituicao ENUM('dinheiro', 'credito', 'troca') NOT NULL DEFAULT 'credito',
  credito_gerado DECIMAL(12,2) DEFAULT 0,         -- valor de crédito/vale gerado
  observacoes TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (venda_id) REFERENCES vendas(id),
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
) ENGINE=InnoDB;

CREATE TABLE devolucao_itens (
  id INT PRIMARY KEY AUTO_INCREMENT,
  devolucao_id INT NOT NULL,
  produto_id INT NOT NULL,
  quantidade DECIMAL(10,3) NOT NULL,              -- quantidade devolvida
  preco_unitario DECIMAL(12,2) NOT NULL,          -- preço original do item
  subtotal DECIMAL(12,2) NOT NULL,                -- quantidade * preco_unitario
  motivo_item VARCHAR(300),                       -- motivo específico do item (defeito, tamanho errado, etc.)
  estado_produto ENUM('novo', 'usado', 'defeito') DEFAULT 'novo',
  retorna_estoque TINYINT(1) DEFAULT 1,           -- se o item volta ao estoque
  FOREIGN KEY (devolucao_id) REFERENCES devolucoes(id),
  FOREIGN KEY (produto_id) REFERENCES produtos(id)
) ENGINE=InnoDB;

CREATE TABLE customer_credits (
  id INT PRIMARY KEY AUTO_INCREMENT,
  cliente_id INT NOT NULL,
  devolucao_id INT,                               -- devolução que gerou o crédito
  valor DECIMAL(12,2) NOT NULL,                   -- valor do crédito
  valor_utilizado DECIMAL(12,2) DEFAULT 0,        -- quanto já foi usado
  saldo DECIMAL(12,2) NOT NULL,                   -- valor - valor_utilizado
  status ENUM('ativo', 'utilizado', 'expirado', 'cancelado') DEFAULT 'ativo',
  data_expiracao DATE,                            -- data limite para uso (null = sem limite)
  observacoes VARCHAR(500),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  FOREIGN KEY (cliente_id) REFERENCES clientes(id),
  FOREIGN KEY (devolucao_id) REFERENCES devolucoes(id)
) ENGINE=InnoDB;
```

### Dados Iniciais (Seed):
```sql
-- Usuário admin padrão (senha: admin123 - trocar no primeiro acesso)
INSERT INTO usuarios (login, senha_hash, nome, papel, max_desconto, perm_caixa, perm_crediario, perm_estoque, perm_contas, perm_tributacao, perm_fornecedores)
VALUES ('admin', '$2b$10$hash_do_bcrypt_aqui', 'Administrador', 'admin', 1.00, 1, 1, 1, 1, 1, 1);

-- Categorias iniciais
INSERT INTO categorias (nome, descricao) VALUES
  ('Alimentos', 'Produtos alimentícios em geral'),
  ('Bebidas', 'Bebidas em geral'),
  ('Limpeza', 'Produtos de limpeza'),
  ('Higiene', 'Produtos de higiene pessoal'),
  ('Outros', 'Outros produtos');

-- Caixa padrão
INSERT INTO caixas (nome, descricao) VALUES
  ('Caixa 01', 'Caixa principal do estabelecimento');

-- Configuração padrão da impressora
INSERT INTO printer_config (printer_name, connection_type, port, paper_width, auto_cut)
VALUES ('Impressora PDV', 'usb', 'COM3', '80mm', 1);

-- Configurações padrão do sistema
INSERT INTO configuracoes (chave, valor, grupo, descricao) VALUES
  ('cor_fundo', '#FFFFFF', 'visual', 'Cor de fundo da aplicação'),
  ('logo_recibo', '', 'visual', 'Caminho do logotipo para recibos'),
  ('tipo_padrao_venda', 'Venda', 'campos_padrao', 'Tipo padrão: Venda ou Orcamento'),
  ('vendedor_padrao', '', 'campos_padrao', 'ID do vendedor padrão'),
  ('status_os_padrao', 'aberta', 'campos_padrao', 'Status padrão de novas OS'),
  ('pagamento_padrao', 'dinheiro', 'campos_padrao', 'Forma de pagamento padrão'),
  ('estado_padrao', '', 'campos_padrao', 'UF padrão para cadastros'),
  ('cidade_padrao', '', 'campos_padrao', 'Cidade padrão para cadastros'),
  ('bairro_padrao', '', 'campos_padrao', 'Bairro padrão para cadastros'),
  ('nome_caixa_pdv', 'Caixa 01', 'pdv', 'Nome do caixa no PDV'),
  ('usar_codigo_interno', '0', 'pdv', 'Usar código interno no PDV'),
  ('confirmar_impressao', '1', 'pdv', 'Confirmar antes de imprimir'),
  ('confirmar_estoque', '1', 'pdv', 'Verificar estoque antes de vender'),
  ('integrar_nfce', '0', 'pdv', 'Integrar com NFC-e'),
  ('modelo_nf', 'nfce', 'geral', 'Modelo de Nota Fiscal'),
  ('backup_automatico', '1', 'geral', 'Ativar backup automático'),
  ('intervalo_backup_horas', '24', 'geral', 'Intervalo entre backups em horas'),
  ('otimizar_conexoes', '0', 'geral', 'Otimizar conexões remotas');

-- ====================================================================
-- IMPORTAÇÃO DA TABELA NCM (13.737 registros)
-- Arquivo fonte: NCM.csv (separador ";", com aspas, encoding UTF-8)
-- Executar no MySQL/MariaDB via LOAD DATA:
-- ====================================================================
LOAD DATA LOCAL INFILE 'NCM.csv'
INTO TABLE ncm
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(co_ncm, co_unid, co_sh6, co_ppe, co_ppi, co_fat_agreg,
 co_cuci_item, co_cgce_n3, co_siit, co_isic_classe,
 co_exp_subset, no_ncm_por, no_ncm_esp, no_ncm_ing);
-- Nota: o campo id será auto-incrementado automaticamente
```

### NCM e Código de Barras (EAN-13)

O NCM (Nomenclatura Comum do Mercosul) é essencial para o funcionamento correto do sistema PDV:

1. **Classificação fiscal**: Todo produto vendido no Brasil precisa de um NCM para emissão de notas fiscais (NF-e), cupom fiscal eletrônico (SAT/MFe) e SPED.
2. **Relação com código de barras**: O código de barras EAN-13 identifica o produto no ponto de venda, enquanto o NCM classifica fiscalmente esse produto. Ambos são obrigatórios para operações comerciais regulares.
3. **Estrutura do NCM** (8 dígitos):
   - `XX` → Capítulo (ex: 61 = Vestuário de malha)
   - `XXXX` → Posição SH (Sistema Harmonizado)
   - `XXXXXX` → Subposição SH (campo `co_sh6`)
   - `XXXXXXXX` → Item NCM completo (campo `co_ncm`)
4. **No cadastro de produto**: O operador seleciona o NCM ao cadastrar o produto. O sistema oferece busca por descrição (FULLTEXT) para facilitar.
5. **Exemplos de NCM para loja de roupas**:
   - `61091000` → Camisetas de malha, de algodão
   - `62034200` → Calças de algodão, para homens
   - `62044400` → Vestidos de fibras sintéticas
   - `42022200` → Bolsas com superfície exterior de folhas de plástico
   - `64039990` → Outros calçados de couro

---

# 🛠️ FASE 2: Backend (API HTTP Local)

## Opção A: Dart + Shelf (No mesmo executável Flutter)

A API HTTP local roda em `http://127.0.0.1:8080` e serve tanto o próprio app Flutter quanto eventuais integrações externas.

### Endpoints da API

#### **Autenticação**
```
POST /api/auth/login
  Body: { "login": "...", "senha": "..." }
  Response: { "token": "jwt...", "usuario": {...} }

POST /api/auth/logout

POST /api/auth/alterar-senha
  Body: { "senha_atual": "...", "nova_senha": "..." }
```

#### **Produtos**
```
GET    /api/produtos                       # listar todos (com filtros: ?categoria=&ativo=&busca=)
GET    /api/produtos/:id                   # detalhes
GET    /api/produtos/barcode/:codigo       # buscar por código de barras
GET    /api/produtos/interno/:codigo       # buscar por código interno
POST   /api/produtos                       # criar
PUT    /api/produtos/:id                   # editar
PATCH  /api/produtos/:id/inativar          # inativar
PATCH  /api/produtos/:id/bloquear          # bloquear/desbloquear
POST   /api/produtos/importar-xml          # importar de XML de NF-e
POST   /api/produtos/combinar              # combinar produtos repetidos
PATCH  /api/produtos/estoque-minimo        # definir estoque mínimo em lote
PATCH  /api/produtos/margem-bruta          # alterar margem bruta em lote
```

#### **Clientes**
```
GET    /api/clientes                       # listar (com filtros: ?busca=&tipo_pessoa=)
GET    /api/clientes/:id                   # detalhes
GET    /api/clientes/:id/historico         # histórico de compras
POST   /api/clientes                       # criar
PUT    /api/clientes/:id                   # editar
DELETE /api/clientes/:id                   # excluir (se sem vendas vinculadas)
```

#### **Fornecedores**
```
GET    /api/fornecedores                   # listar
GET    /api/fornecedores/:id               # detalhes
POST   /api/fornecedores                   # criar
PUT    /api/fornecedores/:id               # editar
DELETE /api/fornecedores/:id               # excluir
```

#### **Compras**
```
GET    /api/compras                        # listar (filtros: ?fornecedor_id=&data_de=&data_ate=)
GET    /api/compras/:id                    # detalhes com itens
POST   /api/compras                        # criar
PUT    /api/compras/:id                    # editar
POST   /api/compras/importar-xml           # importar de XML de NF-e
```

#### **Estoque**
```
GET    /api/estoque/:produto_id            # quantidade atual de um produto
GET    /api/estoque/posicao                # posição de estoque completa
GET    /api/estoque/abaixo-minimo          # produtos abaixo do mínimo
POST   /api/estoque/movimentos             # registrar entrada/saída manual
  Body: { "produto_id": 1, "tipo": "entrada", "ocorrencia": "ajuste", "quantidade": 10, "observacoes": "..." }
GET    /api/estoque/historico              # histórico (filtros: ?produto_id=&tipo=&data_de=&data_ate=)
```

#### **Vendas e Orçamentos**
```
POST   /api/vendas                         # criar venda
  Body: {
    "tipo": "Venda",
    "cliente_id": null,
    "vendedor_id": 2,
    "itens": [
      { "produto_id": 1, "quantidade": 2, "preco_unitario": 10.00, "desconto": 0 }
    ],
    "forma_pagamento": "dinheiro",
    "valor_recebido": 50.00,
    "desconto_percentual": 0,
    "desconto_valor": 0
  }
GET    /api/vendas/:id                     # detalhes da venda com itens
GET    /api/vendas                         # listar (filtros: ?tipo=&data_de=&data_ate=&usuario_id=&cliente_id=)
PUT    /api/vendas/:id/cancelar            # cancelar venda
POST   /api/vendas/:id/converter           # converter orçamento em venda
POST   /api/vendas/:id/recibo              # gerar/imprimir recibo
```

#### **Caixas**
```
GET    /api/caixas                         # listar caixas com saldo
GET    /api/caixas/:id/movimentos          # movimentos de um caixa (filtros: ?data_de=&data_ate=)
POST   /api/caixas/lancamento              # registrar lançamento manual
  Body: { "caixa_id": 1, "descricao": "Sangria", "valor": 100.00, "tipo": "saida" }
POST   /api/caixas/transferencia           # transferência entre caixas
  Body: { "caixa_origem_id": 1, "caixa_destino_id": 2, "valor": 500.00 }
POST   /api/caixas/importar-csv            # importar extrato bancário
GET    /api/caixas/:id/fechamento          # fechamento do caixa (filtro: ?data=)
```

#### **Contas a Pagar**
```
GET    /api/contas-pagar                   # listar (filtros: ?status=&data_de=&data_ate=&tipo=)
GET    /api/contas-pagar/:id               # detalhes
POST   /api/contas-pagar                   # criar
PUT    /api/contas-pagar/:id               # editar
PATCH  /api/contas-pagar/:id/baixa         # dar baixa (pagamento)
  Body: { "data_pagamento": "2026-02-24", "forma_pagamento": "pix" }
GET    /api/contas-pagar/totais            # totais: pendente, pago, atraso
```

#### **Contas a Receber**
```
GET    /api/contas-receber                 # listar (filtros: ?status=&cliente_id=&data_de=&data_ate=)
GET    /api/contas-receber/:id             # detalhes
POST   /api/contas-receber                 # criar
PUT    /api/contas-receber/:id             # editar
PATCH  /api/contas-receber/:id/baixa       # dar baixa (recebimento)
  Body: { "data_recebimento": "2026-02-24", "forma_recebimento": "dinheiro" }
GET    /api/contas-receber/totais          # totais: pendente, recebido, atraso
```

#### **Serviços**
```
GET    /api/servicos                       # listar
GET    /api/servicos/:id                   # detalhes
POST   /api/servicos                       # criar
PUT    /api/servicos/:id                   # editar
DELETE /api/servicos/:id                   # excluir
```

#### **Ordens de Serviço**
```
GET    /api/ordens-servico                 # listar (filtros: ?status=&cliente_id=&prestador_id=&data_de=&data_ate=)
GET    /api/ordens-servico/:id             # detalhes com itens
POST   /api/ordens-servico                 # criar
PUT    /api/ordens-servico/:id             # editar
PATCH  /api/ordens-servico/:id/finalizar   # finalizar OS
POST   /api/ordens-servico/:id/recibo      # gerar/imprimir recibo
```

#### **Crediário**
```
GET    /api/crediario/parcelas             # listar parcelas (filtros: ?cliente_id=&status=&data_de=&data_ate=)
GET    /api/crediario/cliente/:id          # parcelas de um cliente
PATCH  /api/crediario/parcelas/:id/baixa   # dar baixa em parcela
GET    /api/crediario/inadimplencia        # parcelas em atraso
GET    /api/crediario/totais               # totais: pendente, pago, atraso
```

#### **Trocas e Devoluções**
```
POST   /api/devolucoes                     # criar devolução/troca
  Body: {
    "venda_id": 123,
    "tipo": "troca",
    "motivo": "Tamanho errado",
    "forma_restituicao": "credito",
    "itens": [
      { "produto_id": 5, "quantidade": 1, "motivo_item": "Tamanho P, precisa M", "estado_produto": "novo", "retorna_estoque": true }
    ]
  }
GET    /api/devolucoes                     # listar (filtros: ?tipo=&status=&cliente_id=&data_de=&data_ate=)
GET    /api/devolucoes/:id                 # detalhes com itens
PATCH  /api/devolucoes/:id/aprovar         # aprovar devolução
PATCH  /api/devolucoes/:id/recusar         # recusar devolução
PATCH  /api/devolucoes/:id/finalizar       # finalizar (gera crédito/estorna estoque)
POST   /api/devolucoes/:id/recibo          # gerar/imprimir comprovante de devolução
GET    /api/devolucoes/venda/:venda_id     # devoluções de uma venda específica
```

#### **Créditos de Cliente (Vale/Nota de Crédito)**
```
GET    /api/creditos                       # listar créditos (filtros: ?cliente_id=&status=)
GET    /api/creditos/cliente/:id           # créditos/saldo de um cliente
POST   /api/creditos/:id/utilizar          # utilizar crédito em nova venda
  Body: { "venda_id": 456, "valor": 50.00 }
GET    /api/creditos/totais                # totais: ativos, utilizados, expirados
```

#### **Configurações**
```
GET    /api/configuracoes                  # listar todas (ou ?grupo=visual)
GET    /api/configuracoes/:chave           # valor de uma configuração
PUT    /api/configuracoes/:chave           # atualizar configuração
  Body: { "valor": "novo_valor" }
```

#### **Emitente**
```
GET    /api/emitente                       # dados da empresa
PUT    /api/emitente                       # atualizar dados da empresa
```

#### **Relatórios**
```
GET /api/relatorios/vendas                 # por período, vendedor, pagamento
  Params: ?data_de=&data_ate=&usuario_id=&vendedor_id=&forma_pagamento=
  Response: { "total_vendas": 100, "total_valor": 5000.00, "por_pagamento": {...} }

GET /api/relatorios/vendas-por-produto     # ranking de produtos
  Params: ?data_de=&data_ate=
  Response: [ { "produto_id": 1, "descricao": "...", "qtd_vendida": 50, "faturamento": 500.00 } ]

GET /api/relatorios/estoque                # posição de estoque
  Response: [ { "produto_id": 1, "descricao": "...", "atual": 5, "minimo": 10, "abaixo_minimo": true } ]

GET /api/relatorios/caixa                  # fechamento de caixa
  Params: ?data=&caixa_id=
  Response: { "total_dinheiro": ..., "total_cartao": ..., "total_pix": ..., "saldo": ... }

GET /api/relatorios/contas-pagar           # resumo contas a pagar
GET /api/relatorios/contas-receber         # resumo contas a receber
GET /api/relatorios/crediario              # resumo crediário
GET /api/relatorios/compras                # resumo compras
GET /api/relatorios/servicos               # ranking serviços
GET /api/relatorios/ordens-servico         # resumo OS
GET /api/relatorios/clientes-ranking       # ranking de clientes
```

---

# 🎨 FASE 3: Frontend (Flutter Desktop)

## Estrutura de Telas

### 1. Tela de Login
- Entrada: login + senha
- Validação local + autenticação com backend
- Opção de auto-login (checkbox "Lembrar-me")
- Salvar token JWT no `SharedPreferences`

### 2. Dashboard Principal
- Atalhos rápidos para todos os 12 módulos
- Widgets de status:
  - Conexão com BD (online/offline)
  - Vendas do dia (total e quantidade)
  - Alertas de estoque baixo
  - Contas a pagar/receber vencendo hoje
  - Parcelas de crediário em atraso

### 3. Frente de Caixa (PDV)
- Layout conforme descrito no Módulo 1
- Header azul com produto atual
- Tabela central de itens
- Painel direito com barcode + total
- Footer com operador, hora, logo
- Atalhos de teclado (F2-F12, Del, Enter, Esc)
- Diálogo de finalização com formas de pagamento
- Integração com impressora, balança, leitor de barcode

### 4. Tela de Produtos
- Tabela com lista de produtos (grid com filtros)
- Botões: Novo, Editar, Inativar, Bloquear, Importar XML
- Formulário completo com todos os campos do Módulo 2
- Upload de imagem com preview e thumbnail automático
- Busca de NCM com autocomplete
- Seleção de categoria e fornecedor via dropdown

### 5. Tela de Clientes
- Tabela com lista de clientes
- Formulário completo com endereço
- Visualização do histórico de compras
- Controle de limite de crédito

### 6. Tela de Fornecedores
- Tabela com lista de fornecedores
- Formulário completo
- Visualização de compras por fornecedor

### 7. Tela de Compras
- Tabela com lista de compras
- Formulário com grid de itens
- Botão "Importar XML" para ler NF-e
- Cálculo automático de margem bruta

### 8. Tela de Estoque/Histórico
- Posição atual de estoque (tabela com alertas)
- Formulário de entrada/saída manual
- Histórico de movimentações com filtros
- Destaque em vermelho para produtos abaixo do mínimo

### 9. Tela de Caixa
- Seleção de caixa (dropdown)
- Lista de movimentos do caixa selecionado
- Formulário de lançamento (entrada/saída)
- Botão de transferência entre caixas
- Resumo/fechamento com totais por forma de pagamento

### 10. Tela de Contas a Pagar
- Tabela com filtros (hoje, em atraso, todas)
- Formulário de cadastro
- Botão "Dar Baixa" com data e forma de pagamento
- Totais exibidos no topo

### 11. Tela de Contas a Receber
- Mesma estrutura de Contas a Pagar
- Vinculação com cliente e venda

### 12. Tela de Orçamentos e Vendas
- Tabela com filtro por tipo (Venda/Orçamento)
- Formulário com grid de itens (produtos e serviços)
- Desconto por percentual ou valor
- Botão "Converter" para transformar orçamento em venda
- Botão "Recibo" para emitir e imprimir

### 13. Tela de Serviços
- Tabela com lista de serviços
- Formulário simples (descrição, preço, comissão)

### 14. Tela de Ordens de Serviço
- Tabela com filtro por status
- Formulário com grid de serviços e grid de produtos
- Seleção de prestador e cliente
- Texto padrão configurável
- Botão "Finalizar" e "Recibo"

### 15. Tela de Crediário
- Listagem de parcelas por cliente
- Filtros: pendentes, pagas, em atraso
- Botão "Dar Baixa" em parcelas
- Resumo de inadimplência

### 16. Tela de Configurações
- Abas: Visual, Campos Padrão, Frente de Caixa, Geral
- Formulários conforme seção "Configurações do Sistema"

### 17. Tela de Dados do Emitente
- Formulário com dados da empresa
- Upload de logotipo

### 18. Tela de Administração de Usuários
- CRUD de usuários
- Configuração de permissões por módulo
- Definir desconto máximo por usuário

### 19. Tela de Relatórios
- Sub-telas para cada tipo de relatório
- Filtros por período, categoria, etc.
- Exibição em tabela com opção de exportar/imprimir

### 20. Tela de Trocas e Devoluções
- Lista de devoluções com filtros (período, tipo, status, cliente)
- Botão "Nova Devolução" abre formulário:
  - Busca venda por número/código (obrigatório)
  - Exibe itens da venda original para seleção
  - Checkboxes para marcar itens a devolver
  - Campo quantidade, motivo e estado do produto por item
  - Seleção do tipo: Devolução ou Troca
  - Forma de restituição: Dinheiro, Crédito/Vale ou Troca direta
- **Acesso pelo PDV**: Tecla de atalho **F6** no frente de caixa abre modal de devolução rápida
  - Operador digita número da venda
  - Seleciona itens a devolver diretamente
  - Gera crédito que pode ser usado na venda corrente
  - Se tipo "Troca": após processar devolução, inicia nova venda com crédito aplicado automaticamente
- Detalhes da devolução com recibo imprimível
- Aba de Créditos/Vales do cliente com saldo disponível
- Status visual: Pendente (amarelo), Aprovada (azul), Finalizada (verde), Recusada (vermelho)

---

## 📱 Suporte a Código de Barras

### Implementação recomendada:

#### **Opção 1: Input de teclado (Recomendado para Desktop)**
```dart
// O leitor USB simula teclas; basta capturar no TextField
TextField(
  onChanged: (value) {
    if (value.length == 12 || value.length == 13) { // EAN
      _searchProductByBarcode(value);
    }
  },
)
```

#### **Opção 2: Plugin mobile_scanner (Se quiser suporte a câmera)**
```dart
// Para Flutter Desktop, use: flutter_barcode_scanner_web ou similar
final result = await FlutterBarcodeScanner.scanBarcode(
  '#ff6666', '#ffffff', false, ScanMode.QR
);
```

#### **Padrões de código de barras suportados:**
- **EAN-13** (padrão em varejo, 13 dígitos)
- **CODE128** (mais flexível, suporta caracteres especiais)
- **CODE39** (simples, menos comum)
- **UPC-A** (versão americana do EAN)

#### **Validação no backend:**
```dart
bool validateBarcode(String barcode) {
  if (barcode.isEmpty) return false;
  if (barcode.length == 13) return validateEAN13(barcode); // verificar check-digit
  if (barcode.length == 12) return validateUPC(barcode);
  return barcode.isNotEmpty; // aceitar outros comprimentos
}

bool validateEAN13(String ean) {
  // Implementar algoritmo de check-digit
  int sum = ean.substring(0, 12).split('').asMap().entries.fold(0, (s, e) {
    return s + int.parse(e.value) * ((e.key % 2 == 0) ? 1 : 3);
  });
  int checkDigit = (10 - (sum % 10)) % 10;
  return int.parse(ean[12]) == checkDigit;
}
```

---

# 🖨️ FASE 4: Impressora Térmica PDV (Cupom)

Impressoras térmicas de PDV (Epson, Bematech, Elgin, Daruma) usam o protocolo **ESC/POS**. Este é o padrão da indústria para impressão de cupons.

## Impressoras compatíveis (mais comuns no Brasil)

| Marca | Modelos comuns | Conexão | Largura |
|-------|---------------|---------|---------|
| **Epson** | TM-T20X, TM-T88 | USB, Serial, Rede | 80mm |
| **Bematech** | MP-4200 TH, MP-100S TH | USB, Serial | 80mm |
| **Elgin** | i9, i7, VOX+ | USB, Serial, Bluetooth | 80mm / 58mm |
| **Daruma** | DR800, DS348 | USB, Serial | 80mm |
| **Sweda** | SI-300 | USB, Serial | 80mm |

## Protocolo ESC/POS - Como funciona

O protocolo ESC/POS envia **bytes de comando** diretamente à impressora:
- `ESC @` → Reset da impressora
- `ESC E 1` → Negrito ligado
- `ESC a 1` → Centralizar texto
- `GS V 0` → Cortar papel (guilhotina)
- `ESC d 3` → Avançar 3 linhas

O Flutter envia esses bytes via USB (porta serial) ou TCP/IP (rede).

## Implementação no Flutter Desktop

### Dependências:
```yaml
dependencies:
  esc_pos_utils: ^1.1.0          # gera os bytes ESC/POS (formatação do cupom)
  esc_pos_printer: ^4.1.0        # envia para a impressora via rede TCP/IP
  flutter_libserialport: ^0.4.0  # comunicação USB/Serial no Windows
```

### Classe PrinterService (comunicação com hardware):
```dart
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_libserialport/flutter_libserialport.dart';

class PrinterService {
  SerialPort? _serialPort;
  Socket? _networkSocket;

  // Conexão via USB/Serial (COM3, COM4, etc.)
  Future<bool> connectUSB(String portName) async {
    try {
      _serialPort = SerialPort(portName); // ex: "COM3"
      final config = SerialPortConfig();
      config.baudRate = 9600; // padrão para maioria das impressoras
      config.bits = 8;
      config.stopBits = 1;
      config.parity = SerialPortParity.none;
      _serialPort!.config = config;
      return _serialPort!.openReadWrite();
    } catch (e) {
      print('Erro ao conectar USB: $e');
      return false;
    }
  }

  // Conexão via Rede TCP/IP
  Future<bool> connectNetwork(String ip, int port) async {
    try {
      _networkSocket = await Socket.connect(ip, port); // ex: 192.168.1.100:9100
      return true;
    } catch (e) {
      print('Erro ao conectar rede: $e');
      return false;
    }
  }

  // Enviar bytes para a impressora
  Future<void> printBytes(List<int> bytes) async {
    if (_serialPort != null && _serialPort!.isOpen) {
      _serialPort!.write(Uint8List.fromList(bytes));
    } else if (_networkSocket != null) {
      _networkSocket!.add(bytes);
      await _networkSocket!.flush();
    }
  }

  // Listar portas USB disponíveis no Windows
  static List<String> getAvailablePorts() {
    return SerialPort.availablePorts; // retorna ["COM1", "COM3", ...]
  }

  void disconnect() {
    _serialPort?.close();
    _networkSocket?.close();
  }
}
```

### Classe ReceiptBuilder (montagem do cupom):
```dart
import 'package:esc_pos_utils/esc_pos_utils.dart';

class ReceiptBuilder {

  /// Gerar cupom completo de venda
  static Future<List<int>> buildSaleReceipt({
    required String storeName,
    required String storeCnpj,
    required String storeAddress,
    required String saleNumber,
    required String operatorName,
    required List<SaleItemPrint> items,
    required double subtotal,
    required double discount,
    required double total,
    required String paymentMethod,
    required double amountReceived,
    required double changeAmount,
    String paperWidth = '80mm',
  }) async {
    final profile = await CapabilityProfile.load();
    final paperSize = paperWidth == '80mm' ? PaperSize.mm80 : PaperSize.mm58;
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // ====== CABEÇALHO DA LOJA ======
    bytes += generator.text(storeName,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ));
    bytes += generator.text('CNPJ: $storeCnpj',
      styles: PosStyles(align: PosAlign.center));
    bytes += generator.text(storeAddress,
      styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr(ch: '=');

    // ====== DADOS DA VENDA ======
    bytes += generator.text('CUPOM NAO FISCAL',
      styles: PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('Venda: $saleNumber  Operador: $operatorName',
      styles: PosStyles(align: PosAlign.center, codeTable: 'CP1252'));
    bytes += generator.text('Data: ${DateTime.now().toString().substring(0, 19)}',
      styles: PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // ====== ITENS ======
    bytes += generator.row([
      PosColumn(text: 'ITEM', width: 6, styles: PosStyles(bold: true)),
      PosColumn(text: 'QTD', width: 2, styles: PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'TOTAL', width: 4, styles: PosStyles(bold: true, align: PosAlign.right)),
    ]);
    bytes += generator.hr(ch: '-');

    for (var item in items) {
      bytes += generator.text(item.productName);
      bytes += generator.row([
        PosColumn(text: '  ${item.quantity} x R\$ ${item.unitPrice.toStringAsFixed(2)}', width: 8),
        PosColumn(text: 'R\$ ${item.total.toStringAsFixed(2)}', width: 4,
          styles: PosStyles(align: PosAlign.right)),
      ]);
    }

    // ====== TOTAIS ======
    bytes += generator.hr();
    bytes += generator.row([
      PosColumn(text: 'Subtotal:', width: 6),
      PosColumn(text: 'R\$ ${subtotal.toStringAsFixed(2)}', width: 6,
        styles: PosStyles(align: PosAlign.right)),
    ]);
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Desconto:', width: 6),
        PosColumn(text: '-R\$ ${discount.toStringAsFixed(2)}', width: 6,
          styles: PosStyles(align: PosAlign.right)),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'TOTAL:', width: 6,
        styles: PosStyles(bold: true, height: PosTextSize.size2)),
      PosColumn(text: 'R\$ ${total.toStringAsFixed(2)}', width: 6,
        styles: PosStyles(bold: true, height: PosTextSize.size2, align: PosAlign.right)),
    ]);

    // ====== PAGAMENTO ======
    bytes += generator.hr();
    String paymentLabel = {
      'cash': 'Dinheiro', 'card': 'Cartao', 'pix': 'Pix',
      'check': 'Cheque', 'credit': 'Credito'
    }[paymentMethod] ?? paymentMethod;

    bytes += generator.text('Forma de pagamento: $paymentLabel');
    if (paymentMethod == 'cash') {
      bytes += generator.text('Valor recebido: R\$ ${amountReceived.toStringAsFixed(2)}');
      bytes += generator.text('Troco: R\$ ${changeAmount.toStringAsFixed(2)}',
        styles: PosStyles(bold: true));
    }

    // ====== RODAPÉ ======
    bytes += generator.hr(ch: '=');
    bytes += generator.text('Obrigado pela preferencia!',
      styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Volte sempre!',
      styles: PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut(); // acionar guilhotina

    return bytes;
  }
}

/// Modelo auxiliar para itens do cupom
class SaleItemPrint {
  final String productName;
  final double quantity;
  final double unitPrice;
  final double total;

  SaleItemPrint({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}
```

### Integração no fluxo de venda (PDV):
```dart
// Ao finalizar a venda:
Future<void> finalizeSaleAndPrint(Sale sale) async {
  // 1. Salvar venda no MySQL
  await saleRepository.create(sale);

  // 2. Atualizar estoque
  for (var item in sale.items) {
    await stockRepository.decrementStock(item.productId, item.quantity);
  }

  // 3. Imprimir cupom na impressora térmica
  final printerConfig = await printerConfigRepository.getActive();
  final printerService = PrinterService();

  bool connected = false;
  if (printerConfig.connectionType == 'usb') {
    connected = await printerService.connectUSB(printerConfig.port!);
  } else if (printerConfig.connectionType == 'network') {
    connected = await printerService.connectNetwork(
      printerConfig.ipAddress!, printerConfig.tcpPort);
  }

  if (connected) {
    final receiptBytes = await ReceiptBuilder.buildSaleReceipt(
      storeName: 'MINHA LOJA',
      storeCnpj: '00.000.000/0001-00',
      storeAddress: 'Rua Exemplo, 123 - Centro',
      saleNumber: sale.saleNumber,
      operatorName: currentUser.name,
      items: sale.items.map((i) => SaleItemPrint(
        productName: i.productName,
        quantity: i.quantity,
        unitPrice: i.unitPrice,
        total: i.total,
      )).toList(),
      subtotal: sale.subtotal,
      discount: sale.discount,
      total: sale.total,
      paymentMethod: sale.paymentMethod,
      amountReceived: sale.amountReceived,
      changeAmount: sale.changeAmount,
    );
    await printerService.printBytes(receiptBytes);
    printerService.disconnect();
  } else {
    // Exibir alerta: "Impressora não conectada. Cupom não impresso."
    showPrinterErrorDialog();
  }
}
```

### Tela de configuração da impressora:
```
┌────────────────────────────────────────────────┐
│         CONFIGURAÇÃO DA IMPRESSORA             │
├────────────────────────────────────────────────┤
│                                                │
│  Tipo de conexão:  [● USB/Serial] [○ Rede]     │
│                                                │
│  Porta USB:        [COM3         ▼]            │
│    (Portas detectadas: COM1, COM3, COM5)       │
│                                                │
│  ── OU ──                                      │
│                                                │
│  IP da impressora: [192.168.1.100]             │
│  Porta TCP:        [9100        ]              │
│                                                │
│  Largura do papel: [● 80mm] [○ 58mm]          │
│  Guilhotina auto:  [✓]                         │
│  Imprimir logo:    [ ]                         │
│                                                │
│  [🔍 Detectar Portas] [🖨️ Imprimir Teste]     │
│                                                │
│           [Salvar Configuração]                │
└────────────────────────────────────────────────┘
```

### Exemplo de cupom impresso (80mm):
```
================================================
            MINHA LOJA
       CNPJ: 00.000.000/0001-00
       Rua Exemplo, 123 - Centro
================================================
          CUPOM NAO FISCAL
   Venda: 000042  Operador: Maria
   Data: 2026-02-13 14:35:22
------------------------------------------------
ITEM                QTD     TOTAL
------------------------------------------------
Arroz Tio Joao 5kg
  2 x R$ 24.90              R$ 49.80
Feijao Carioca 1kg
  3 x R$ 8.50               R$ 25.50
Oleo de Soja 900ml
  1 x R$ 7.90               R$ 7.90
Acucar Cristal 1kg
  2 x R$ 5.20               R$ 10.40
------------------------------------------------
Subtotal:                    R$ 93.60
Desconto:                   -R$ 3.60
TOTAL:                       R$ 90.00
------------------------------------------------
Forma de pagamento: Dinheiro
Valor recebido: R$ 100.00
Troco: R$ 10.00
================================================
       Obrigado pela preferencia!
            Volte sempre!


```

---

# 📦 FASE 5: Instalação no Cliente

## Estratégia de distribuição

O sistema será distribuído como um **instalador Windows (.exe)** que configura tudo automaticamente na máquina do cliente.

## Opção Recomendada: Inno Setup

**Inno Setup** é gratuito, leve e o padrão para distribuir apps Windows.

### Estrutura do instalador:
```
Instalador MenúlyPDV.exe
├── app/
│   ├── menuly_pdv.exe              (Flutter Desktop compilado)
│   ├── flutter_windows.dll         (runtime Flutter)
│   ├── *.dll                       (dependências nativas)
│   └── data/
│       └── flutter_assets/         (assets do Flutter)
├── mysql/
│   ├── mariadb-portable/           (MariaDB portable ~90MB)
│   │   ├── bin/
│   │   │   ├── mysqld.exe          (servidor)
│   │   │   ├── mysql.exe           (cliente)
│   │   │   └── mysqldump.exe       (backup)
│   │   └── data/                   (dados do banco)
│   └── my.ini                      (configuração do MySQL)
├── scripts/
│   ├── setup_database.sql          (schema completo + seed)
│   ├── start_services.bat          (iniciar MySQL + App)
│   └── backup.bat                  (script de backup automático)
├── images/
│   └── products/                   (pasta para imagens de produtos)
├── config/
│   └── app_config.json             (configurações do app)
└── drivers/
    └── printer/                    (drivers genéricos ESC/POS)
```

### Script Inno Setup (.iss):
```iss
[Setup]
AppName=Menuly PDV
AppVersion=1.0.0
AppPublisher=Sua Empresa
DefaultDirName={autopf}\MenúlyPDV
DefaultGroupName=Menuly PDV
OutputDir=output
OutputBaseFilename=MenülyPDV_Setup_v1.0.0
Compression=lzma2
SolidCompression=yes
SetupIconFile=assets\icon.ico
PrivilegesRequired=admin

[Files]
; App Flutter compilado
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: recursesubdirs

; MariaDB Portable
Source: "installer\mariadb-portable\*"; DestDir: "{app}\mysql"; Flags: recursesubdirs

; Scripts de setup
Source: "installer\scripts\*"; DestDir: "{app}\scripts"; Flags: recursesubdirs

; Configurações
Source: "installer\config\*"; DestDir: "{app}\config"; Flags: recursesubdirs

; Pasta de imagens (vazia inicialmente)
Source: "installer\images\*"; DestDir: "{app}\images"; Flags: recursesubdirs

[Icons]
Name: "{group}\Menuly PDV"; Filename: "{app}\menuly_pdv.exe"
Name: "{commondesktop}\Menuly PDV"; Filename: "{app}\menuly_pdv.exe"
Name: "{group}\Backup do Banco"; Filename: "{app}\scripts\backup.bat"

[Run]
; Instalar MariaDB como serviço Windows (roda em background automaticamente)
Filename: "{app}\mysql\bin\mysqld.exe"; Parameters: "--install MenülyMySQL --defaults-file=""{app}\mysql\my.ini"""; Flags: runhidden
; Iniciar o serviço MySQL
Filename: "net"; Parameters: "start MenülyMySQL"; Flags: runhidden
; Executar o schema do banco de dados
Filename: "{app}\mysql\bin\mysql.exe"; Parameters: "-u root < ""{app}\scripts\setup_database.sql"""; Flags: runhidden waituntilterminated
; Abrir o app ao finalizar
Filename: "{app}\menuly_pdv.exe"; Description: "Iniciar Menuly PDV"; Flags: nowait postinstall

[UninstallRun]
; Parar e remover o serviço MySQL na desinstalação
Filename: "net"; Parameters: "stop MenülyMySQL"; Flags: runhidden
Filename: "{app}\mysql\bin\mysqld.exe"; Parameters: "--remove MenülyMySQL"; Flags: runhidden
```

### Script de inicialização (start_services.bat):
```bat
@echo off
echo Iniciando Menuly PDV...

:: Verificar se o serviço MySQL está rodando
sc query MenülyMySQL | find "RUNNING" >nul
if errorlevel 1 (
    echo Iniciando banco de dados...
    net start MenülyMySQL
    timeout /t 3 /nobreak >nul
)

:: Iniciar o aplicativo
start "" "%~dp0..\menuly_pdv.exe"
```

### Script de backup (backup.bat):
```bat
@echo off
set BACKUP_DIR=%~dp0..\backups
set MYSQL_DIR=%~dp0..\mysql\bin
set DATE=%date:~6,4%-%date:~3,2%-%date:~0,2%_%time:~0,2%-%time:~3,2%

if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

echo Realizando backup do banco de dados...
"%MYSQL_DIR%\mysqldump.exe" -u pdv_user -psenha_aqui menuly_pdv > "%BACKUP_DIR%\backup_%DATE%.sql"

:: Manter apenas os últimos 30 backups
forfiles /p "%BACKUP_DIR%" /m "backup_*.sql" /d -30 /c "cmd /c del @path" 2>nul

echo Backup concluido: backup_%DATE%.sql
pause
```

### Arquivo de configuração (app_config.json):
```json
{
  "database": {
    "host": "localhost",
    "port": 3306,
    "database": "menuly_pdv",
    "username": "pdv_user",
    "password": "senha_segura_aqui"
  },
  "printer": {
    "enabled": true,
    "connection_type": "usb",
    "port": "COM3",
    "paper_width": "80mm",
    "auto_cut": true
  },
  "store": {
    "name": "Nome da Loja",
    "cnpj": "00.000.000/0001-00",
    "address": "Rua Exemplo, 123",
    "phone": "(00) 0000-0000"
  },
  "api_server": {
    "host": "127.0.0.1",
    "port": 8080
  },
  "backup": {
    "auto_backup": true,
    "interval_hours": 24,
    "keep_last": 30
  }
}
```

## Fluxo de instalação para o técnico/cliente:

```
1. Executar "MenülyPDV_Setup_v1.0.0.exe"
2. Tela de boas-vindas → Avançar
3. Escolher pasta de instalação → Avançar
4. Instalação automática:
   ├── Copia arquivos do app
   ├── Instala MariaDB como serviço Windows
   ├── Cria o banco de dados e tabelas
   ├── Insere dados iniciais (admin, categorias)
   └── Cria atalhos (Desktop + Menu Iniciar)
5. Finalizar → App abre automaticamente
6. Primeiro login: admin / admin123
7. Configurar impressora térmica (Configurações → Impressora)
8. Cadastrar produtos e começar a usar!
```

## Requisitos mínimos da máquina do cliente:

| Requisito | Mínimo | Recomendado |
|-----------|--------|-------------|
| SO | Windows 10 64-bit | Windows 10/11 64-bit |
| RAM | 4 GB | 8 GB |
| Disco | 500 MB livre | 2 GB livre (para imagens) |
| Processador | Dual-core 2GHz | Quad-core |
| Resolução | 1366x768 | 1920x1080 |
| Periféricos | - | Leitor de código de barras USB + Impressora térmica |

## Atualizações futuras:

Para enviar atualizações ao cliente:
- Gerar novo instalador com versão atualizada
- O Inno Setup detecta a versão instalada e faz upgrade automático
- O banco de dados é preservado (não sobrescreve pasta `data/`)
- Incluir scripts de migração SQL (`migrations/v1.1.0.sql`) para alterações no schema

---

# Estrutura de Pastas do Projeto

```
lib/
├── main.dart                          # entrada da app Flutter + init do servidor
├── config/
│   ├── server_config.dart             # porta, configurações do servidor
│   ├── database_config.dart           # configurações do MySQL
│   └── app_constants.dart             # constantes da aplicação
│
├── domain/
│   ├── models/
│   │   ├── usuario.dart
│   │   ├── emitente.dart
│   │   ├── cliente.dart
│   │   ├── fornecedor.dart
│   │   ├── categoria.dart
│   │   ├── produto.dart
│   │   ├── historico_estoque.dart
│   │   ├── servico.dart
│   │   ├── venda.dart
│   │   ├── venda_item.dart
│   │   ├── ordem_servico.dart
│   │   ├── os_item_servico.dart
│   │   ├── os_item_produto.dart
│   │   ├── compra.dart
│   │   ├── compra_item.dart
│   │   ├── caixa.dart
│   │   ├── caixa_movimento.dart
│   │   ├── conta_pagar.dart
│   │   ├── conta_receber.dart
│   │   ├── crediario_parcela.dart
│   │   ├── configuracao.dart
│   │   ├── ncm.dart
│   │   └── printer_config.dart
│   │
│   └── repositories/
│       ├── usuario_repository.dart
│       ├── emitente_repository.dart
│       ├── cliente_repository.dart
│       ├── fornecedor_repository.dart
│       ├── categoria_repository.dart
│       ├── produto_repository.dart
│       ├── estoque_repository.dart
│       ├── servico_repository.dart
│       ├── venda_repository.dart
│       ├── ordem_servico_repository.dart
│       ├── compra_repository.dart
│       ├── caixa_repository.dart
│       ├── conta_pagar_repository.dart
│       ├── conta_receber_repository.dart
│       ├── crediario_repository.dart
│       ├── configuracao_repository.dart
│       ├── ncm_repository.dart
│       └── printer_config_repository.dart
│
├── data/
│   ├── local/
│   │   ├── database.dart              # inicialização MySQL (conexão via mysql_client)
│   │   └── implementations/
│   │       ├── usuario_repo_impl.dart
│   │       ├── emitente_repo_impl.dart
│   │       ├── cliente_repo_impl.dart
│   │       ├── fornecedor_repo_impl.dart
│   │       ├── categoria_repo_impl.dart
│   │       ├── produto_repo_impl.dart
│   │       ├── estoque_repo_impl.dart
│   │       ├── servico_repo_impl.dart
│   │       ├── venda_repo_impl.dart
│   │       ├── ordem_servico_repo_impl.dart
│   │       ├── compra_repo_impl.dart
│   │       ├── caixa_repo_impl.dart
│   │       ├── conta_pagar_repo_impl.dart
│   │       ├── conta_receber_repo_impl.dart
│   │       ├── crediario_repo_impl.dart
│   │       ├── configuracao_repo_impl.dart
│   │       ├── ncm_repo_impl.dart
│   │       └── printer_config_repo_impl.dart
│
├── services/
│   ├── printer_service.dart           # comunicação ESC/POS com impressora térmica
│   ├── receipt_builder.dart           # montagem do layout do cupom
│   ├── balance_service.dart           # comunicação com balança serial
│   ├── drawer_service.dart            # acionamento da gaveta de dinheiro
│   ├── xml_import_service.dart        # importação de XML de NF-e
│   ├── mysql_backup.dart              # backup automático do MySQL
│   └── image_service.dart             # otimização e thumbnail de imagens
│
├── server/
│   ├── api_server.dart                # Shelf app setup
│   ├── routes/
│   │   ├── auth_routes.dart
│   │   ├── produtos_routes.dart
│   │   ├── clientes_routes.dart
│   │   ├── fornecedores_routes.dart
│   │   ├── compras_routes.dart
│   │   ├── estoque_routes.dart
│   │   ├── vendas_routes.dart
│   │   ├── caixas_routes.dart
│   │   ├── contas_pagar_routes.dart
│   │   ├── contas_receber_routes.dart
│   │   ├── servicos_routes.dart
│   │   ├── ordens_servico_routes.dart
│   │   ├── crediario_routes.dart
│   │   ├── configuracoes_routes.dart
│   │   ├── emitente_routes.dart
│   │   └── relatorios_routes.dart
│   └── middleware/
│       ├── auth.dart
│       ├── permissions.dart
│       └── error_handler.dart
│
└── presentation/
    ├── app.dart                        # MaterialApp / FluentApp root
    ├── theme/
    │   ├── app_theme.dart
    │   └── colors.dart
    ├── navigation/
    │   └── app_router.dart             # GoRouter config
    ├── providers/                      # Riverpod / Bloc providers
    │   ├── auth_provider.dart
    │   ├── produto_provider.dart
    │   ├── venda_provider.dart
    │   ├── estoque_provider.dart
    │   ├── caixa_provider.dart
    │   └── ... (um por módulo)
    ├── screens/
    │   ├── login/
    │   │   └── login_screen.dart
    │   ├── dashboard/
    │   │   └── dashboard_screen.dart
    │   ├── pdv/
    │   │   ├── pdv_screen.dart
    │   │   ├── pdv_payment_dialog.dart
    │   │   └── pdv_controller.dart
    │   ├── produtos/
    │   │   ├── produtos_list_screen.dart
    │   │   ├── produto_form_screen.dart
    │   │   └── produto_detail_screen.dart
    │   ├── clientes/
    │   │   ├── clientes_list_screen.dart
    │   │   └── cliente_form_screen.dart
    │   ├── fornecedores/
    │   │   ├── fornecedores_list_screen.dart
    │   │   └── fornecedor_form_screen.dart
    │   ├── compras/
    │   │   ├── compras_list_screen.dart
    │   │   └── compra_form_screen.dart
    │   ├── estoque/
    │   │   ├── estoque_screen.dart
    │   │   ├── estoque_movimento_form.dart
    │   │   └── estoque_historico_screen.dart
    │   ├── caixa/
    │   │   ├── caixa_screen.dart
    │   │   ├── caixa_lancamento_form.dart
    │   │   └── caixa_fechamento_screen.dart
    │   ├── contas_pagar/
    │   │   ├── contas_pagar_list_screen.dart
    │   │   └── conta_pagar_form_screen.dart
    │   ├── contas_receber/
    │   │   ├── contas_receber_list_screen.dart
    │   │   └── conta_receber_form_screen.dart
    │   ├── vendas/
    │   │   ├── vendas_list_screen.dart
    │   │   └── venda_form_screen.dart
    │   ├── servicos/
    │   │   ├── servicos_list_screen.dart
    │   │   └── servico_form_screen.dart
    │   ├── ordens_servico/
    │   │   ├── os_list_screen.dart
    │   │   └── os_form_screen.dart
    │   ├── crediario/
    │   │   └── crediario_screen.dart
    │   ├── devolucoes/
    │   │   ├── devolucoes_list_screen.dart
    │   │   ├── devolucao_form_screen.dart
    │   │   └── creditos_cliente_screen.dart
    │   ├── configuracoes/
    │   │   ├── configuracoes_screen.dart
    │   │   ├── emitente_screen.dart
    │   │   ├── impressora_screen.dart
    │   │   └── usuarios_screen.dart
    │   └── relatorios/
    │       ├── relatorios_menu_screen.dart
    │       ├── relatorio_vendas_screen.dart
    │       ├── relatorio_estoque_screen.dart
    │       ├── relatorio_caixa_screen.dart
    │       ├── relatorio_financeiro_screen.dart
    │       └── relatorio_os_screen.dart
    └── widgets/
        ├── app_sidebar.dart            # menu lateral de navegação
        ├── data_table_widget.dart      # tabela reutilizável
        ├── search_field.dart           # campo de busca
        ├── currency_field.dart         # campo de valor monetário (R$)
        ├── barcode_field.dart          # campo de código de barras
        ├── ncm_autocomplete.dart       # autocomplete de NCM
        ├── image_picker_widget.dart    # seletor de imagem com preview
        └── confirmation_dialog.dart    # diálogo de confirmação
```

---

# 🚀 Roadmap de Implementação

## MVP - Funcionalidades Essenciais

### Sprint 1: Setup + Banco de Dados
- [ ] Criar projeto Flutter Desktop
- [ ] Instalar e configurar MySQL/MariaDB local
- [ ] Integrar `mysql_client` no Flutter
- [ ] Executar schema completo (26 tabelas MySQL)
- [ ] Seed dados iniciais (admin, categorias, config impressora, configurações)
- [ ] Testar conexão Flutter ↔ MySQL
- [ ] Configurar estrutura de pastas do projeto

### Sprint 2: Autenticação + Produtos
- [ ] Setup Shelf + rotas base
- [ ] Autenticação JWT (login, logout, alterar senha)
- [ ] Tela de Login
- [ ] CRUD completo de Produtos (backend + frontend)
- [ ] Upload e otimização de imagens de produtos
- [ ] Busca de NCM com autocomplete
- [ ] Cadastro de Categorias

### Sprint 3: Frente de Caixa (PDV)
- [ ] Layout do PDV conforme especificação
- [ ] Leitura de código de barras (input USB)
- [ ] Busca por descrição
- [ ] Carrinho de venda (adicionar, remover, alterar quantidade)
- [ ] Atalhos de teclado (F2-F12, Del, Enter)
- [ ] Cálculo de totais e troco

### Sprint 4: Vendas + Estoque
- [ ] Finalização de venda com múltiplas formas de pagamento
- [ ] Movimentação automática de estoque ao vender
- [ ] Histórico de movimentações de estoque
- [ ] Entrada manual de estoque
- [ ] Alertas de estoque mínimo

### Sprint 5: Orçamentos + Clientes
- [ ] Tipo Venda/Orçamento no PDV e módulo de vendas
- [ ] Converter orçamento em venda (F8)
- [ ] CRUD completo de Clientes
- [ ] Vincular cliente à venda (F10)
- [ ] Histórico de compras por cliente

### Sprint 6: Impressora Térmica + Recibos
- [ ] Implementar `PrinterService` (USB/Serial e Rede)
- [ ] Implementar `ReceiptBuilder` (montagem do cupom ESC/POS)
- [ ] Tela de configuração da impressora
- [ ] Detecção automática de portas USB
- [ ] Impressão de cupom teste
- [ ] Integrar impressão no fluxo de finalização de venda
- [ ] Emissão de recibo para vendas e OS

## Funcionalidades Secundárias

### Sprint 7: Fornecedores + Compras
- [ ] CRUD de Fornecedores
- [ ] CRUD de Compras com grid de itens
- [ ] Importação de XML de NF-e (leitura e preenchimento automático)
- [ ] Cálculo automático de margem bruta
- [ ] Entrada automática de estoque ao registrar compra
- [ ] Vincular fornecedor a produtos

### Sprint 8: Caixa (Multi-caixa)
- [ ] CRUD de Caixas
- [ ] Lançamentos de entrada/saída
- [ ] Transferência entre caixas
- [ ] Fechamento de caixa (totais por forma de pagamento)
- [ ] Importação de CSV bancário

### Sprint 9: Vendedores + Comissões
- [ ] Vincular vendedor à venda (F11)
- [ ] Cálculo de comissões sobre vendas
- [ ] Relatório de vendas por vendedor
- [ ] Desconto máximo configurável por usuário

### Sprint 10: Relatórios
- [ ] Relatório de vendas (por período, vendedor, forma de pagamento)
- [ ] Relatório de estoque (posição atual, produtos críticos)
- [ ] Relatório de caixa (fechamento diário)
- [ ] Ranking de produtos mais vendidos
- [ ] Ranking de clientes
- [ ] Relatório de compras por fornecedor

## Funcionalidades Avançadas

### Sprint 11: Contas a Pagar / Receber
- [ ] CRUD de Contas a Pagar
- [ ] CRUD de Contas a Receber
- [ ] Filtros: vencendo hoje, em atraso, todas
- [ ] Dar baixa em contas (pagamento/recebimento)
- [ ] Totais e resumos
- [ ] Geração automática de contas a partir de compras/vendas
- [ ] Relatórios financeiros

### Sprint 12: Crediário Próprio
- [ ] Forma de pagamento "Crediário" no PDV
- [ ] Geração automática de parcelas
- [ ] Controle de parcelas (dar baixa, atrasos)
- [ ] Verificação de limite de crédito do cliente
- [ ] Bloqueio automático por inadimplência
- [ ] Relatório de inadimplência

### Sprint 13: Serviços + Ordens de Serviço
- [ ] CRUD de Serviços
- [ ] CRUD de Ordens de Serviço (com grid de serviços e produtos)
- [ ] Finalização de OS
- [ ] Emissão de recibo de OS
- [ ] Comissão do prestador/técnico
- [ ] Texto padrão configurável
- [ ] Relatórios de OS (por prestador, cliente, período)

### Sprint 14: Trocas e Devoluções
- [ ] CRUD de Devoluções (com seleção de itens da venda original)
- [ ] Fluxo de aprovação de devolução (pendente → aprovada → finalizada)
- [ ] Estorno automático de estoque (itens marcados para retorno)
- [ ] Geração de crédito/vale para cliente
- [ ] Controle de créditos (saldo, utilização, expiração)
- [ ] **Atalho F6 no PDV** para devolução rápida direto do frente de caixa
- [ ] Fluxo de troca no PDV: devolve + inicia nova venda com crédito aplicado
- [ ] Utilização de crédito como forma de pagamento no PDV
- [ ] Impressão de comprovante de devolução
- [ ] Relatório de devoluções (por período, motivo, produto)

### Sprint 15: NFC-e + Instalador + Polish
- [ ] Preparar integração NFC-e (campos no BD já prontos)
- [ ] Configurar Inno Setup (.iss) para instalador
- [ ] Empacotar MariaDB Portable no instalador
- [ ] Scripts de setup automático do banco
- [ ] Script de backup automático
- [ ] Registrar MySQL como serviço Windows
- [ ] Permissões de acesso por módulo
- [ ] Configurações do sistema (abas Visual, Campos Padrão, PDV, Geral)
- [ ] Dados do Emitente
- [ ] Testes de instalação em máquina limpa
- [ ] Testes unitários e de integração
- [ ] Tratamento de erros (impressora desconectada, MySQL offline, etc.)
- [ ] Performance e otimização de queries
- [ ] Gerar `MenülyPDV_Setup_v1.0.0.exe` final

---

# 📦 Dependências Recomendadas (pubspec.yaml)

```yaml
name: menuly_pdv
description: Sistema PDV completo baseado no Facilite (Risko)
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # ===== BANCO DE DADOS (MySQL) =====
  mysql_client: ^0.0.27              # driver MySQL puro em Dart (sem dependência nativa)

  # ===== SERVIDOR HTTP LOCAL =====
  shelf: ^1.4.0                      # servidor HTTP embutido
  shelf_router: ^1.1.0               # roteamento de endpoints

  # ===== HTTP & AUTENTICAÇÃO =====
  http: ^1.1.0                       # cliente HTTP
  dio: ^5.3.0                        # requisições HTTP avançadas
  jwt_decoder: ^2.0.1                # decodificar tokens JWT
  bcrypt: ^1.1.0                     # hash de senhas

  # ===== IMPRESSORA TÉRMICA (ESC/POS) =====
  esc_pos_utils: ^1.1.0              # gera bytes ESC/POS (formatação do cupom)
  esc_pos_printer: ^4.1.0            # envia para impressora via rede TCP/IP
  flutter_libserialport: ^0.4.0      # comunicação USB/Serial no Windows

  # ===== STATE MANAGEMENT =====
  flutter_riverpod: ^2.4.0           # gerenciamento de estado reativo
  riverpod_annotation: ^2.3.0        # annotations para Riverpod

  # ===== NAVEGAÇÃO =====
  go_router: ^10.0.0                 # navegação entre telas

  # ===== UI WINDOWS NATIVA =====
  fluent_ui: ^4.8.0                  # componentes nativos Windows (Fluent Design)

  # ===== XML (Importação NF-e) =====
  xml: ^6.3.0                        # parse de XML para importação de NF-e

  # ===== UTILIDADES =====
  image: ^4.0.0                      # processamento/otimização de imagem
  intl: ^0.19.0                      # formatação de data/hora e moeda (R$)
  uuid: ^4.0.0                       # gerar IDs únicos
  path_provider: ^2.1.0              # acessar diretórios do sistema (AppData, etc.)
  shared_preferences: ^2.2.0         # armazenamento local (token, preferências)
  file_picker: ^6.0.0                # seletor de arquivos (imagens, XML, CSV)
  pdf: ^3.10.0                       # geração de PDF para relatórios
  printing: ^5.11.0                  # impressão de PDF
  csv: ^5.0.0                        # leitura de CSV (importação bancária)

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  riverpod_generator: ^2.3.0         # gerador de código Riverpod
  build_runner: ^2.4.0               # build runner para geração de código
  mockito: ^5.4.0                    # mocks para testes
```

---

## ✅ Resumo do Sistema

| Aspecto | Detalhe |
|---------|---------|
| **Nome** | Menuly PDV |
| **Base** | Facilite (Risko) |
| **Módulos** | 12 módulos completos |
| **Tabelas BD** | 26 tabelas MySQL/MariaDB |
| **Funcionalidades** | 100+ funcionalidades mapeadas |
| **Tecnologia Frontend** | Flutter Desktop (Windows) |
| **Tecnologia Backend** | Dart + Shelf (HTTP local) |
| **Banco de Dados** | MySQL 8.0+ / MariaDB 10.6+ |
| **Impressora** | ESC/POS (USB/Serial/Rede) |
| **Instalador** | Inno Setup (.exe Windows) |
| **Hardware** | Impressora, Gaveta, Balança, Leitor Barcode, NFC-e |
| **Sprints** | 15 sprints planejados |

<div align="center">⁂</div>

[^1]: facilite.pdf
