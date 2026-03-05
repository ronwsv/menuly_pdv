-- ====================================================================
-- MENULY PDV - Dados Iniciais (Seed)
-- Executar após o schema.sql
-- ====================================================================

USE menuly_pdv;

-- ====================================================================
-- USUÁRIO ADMIN PADRÃO
-- Senha: admin123 (trocar no primeiro acesso)
-- Hash bcrypt gerado com cost 10
-- ====================================================================
INSERT INTO usuarios (login, senha_hash, nome, papel, max_desconto, perm_caixa, perm_crediario, perm_estoque, perm_contas, perm_tributacao, perm_fornecedores)
VALUES ('admin', '$2b$10$hash_do_bcrypt_aqui', 'Administrador', 'admin', 1.00, 1, 1, 1, 1, 1, 1)
ON DUPLICATE KEY UPDATE nome = nome;

-- ====================================================================
-- CATEGORIAS INICIAIS
-- ====================================================================
INSERT INTO categorias (nome, descricao) VALUES
  ('Camisetas', 'Camisetas e blusas'),
  ('Calcas', 'Calcas jeans, sociais e casuais'),
  ('Vestidos', 'Vestidos femininos'),
  ('Acessorios', 'Bolsas, cintos, relogios, oculos'),
  ('Calcados', 'Tenis, sandalias, botas'),
  ('Outros', 'Outros produtos')
ON DUPLICATE KEY UPDATE descricao = VALUES(descricao);

-- ====================================================================
-- CAIXA PADRÃO
-- ====================================================================
INSERT INTO caixas (nome, descricao) VALUES
  ('Caixa 01', 'Caixa principal do estabelecimento');

-- ====================================================================
-- CONFIGURAÇÃO PADRÃO DA IMPRESSORA
-- ====================================================================
INSERT INTO printer_config (printer_name, connection_type, port, paper_width, auto_cut)
VALUES ('Impressora PDV', 'usb', 'COM3', '80mm', 1);

-- ====================================================================
-- CONFIGURAÇÕES DO SISTEMA
-- ====================================================================
INSERT INTO configuracoes (chave, valor, grupo, descricao) VALUES
  -- Visual
  ('cor_fundo', '#1a1a2e', 'visual', 'Cor de fundo da aplicacao'),
  ('cor_primaria', '#0a4d8c', 'visual', 'Cor primaria do tema'),
  ('logo_recibo', '', 'visual', 'Caminho do logotipo para recibos'),

  -- Campos Padrão
  ('tipo_padrao_venda', 'Venda', 'campos_padrao', 'Tipo padrao: Venda ou Orcamento'),
  ('vendedor_padrao', '', 'campos_padrao', 'ID do vendedor padrao'),
  ('status_os_padrao', 'aberta', 'campos_padrao', 'Status padrao de novas OS'),
  ('pagamento_padrao', 'dinheiro', 'campos_padrao', 'Forma de pagamento padrao'),
  ('estado_padrao', '', 'campos_padrao', 'UF padrao para cadastros'),
  ('cidade_padrao', '', 'campos_padrao', 'Cidade padrao para cadastros'),
  ('bairro_padrao', '', 'campos_padrao', 'Bairro padrao para cadastros'),

  -- PDV
  ('nome_caixa_pdv', 'Caixa 01', 'pdv', 'Nome do caixa no PDV'),
  ('usar_codigo_interno', '0', 'pdv', 'Usar codigo interno no PDV'),
  ('confirmar_impressao', '1', 'pdv', 'Confirmar antes de imprimir'),
  ('confirmar_estoque', '1', 'pdv', 'Verificar estoque antes de vender'),
  ('integrar_nfce', '0', 'pdv', 'Integrar com NFC-e'),
  ('prazo_devolucao_dias', '30', 'pdv', 'Prazo maximo para devolucao em dias'),

  -- Geral
  ('modelo_nf', 'nfce', 'geral', 'Modelo de Nota Fiscal'),
  ('backup_automatico', '1', 'geral', 'Ativar backup automatico'),
  ('intervalo_backup_horas', '24', 'geral', 'Intervalo entre backups em horas'),
  ('otimizar_conexoes', '0', 'geral', 'Otimizar conexoes remotas')
ON DUPLICATE KEY UPDATE valor = VALUES(valor);

-- ====================================================================
-- DADOS DO EMITENTE (Exemplo - Preencher com dados reais)
-- ====================================================================
INSERT INTO emitente (razao_social, nome_fantasia, cnpj, regime_tributario)
VALUES ('Sua Empresa LTDA', 'Menuly PDV', '00.000.000/0001-00', 'simples')
ON DUPLICATE KEY UPDATE razao_social = razao_social;

-- ====================================================================
-- FIM DO SEED
-- ====================================================================
