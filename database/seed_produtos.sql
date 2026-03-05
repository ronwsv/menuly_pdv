-- Menuly PDV - Seed de Categorias e Produtos do Prototipo
-- 5 categorias + 18 produtos

-- Categorias
INSERT INTO categorias (nome, descricao) VALUES
  ('Camisetas', 'Camisetas e blusas'),
  ('Calcas', 'Calcas jeans, sociais e casuais'),
  ('Vestidos', 'Vestidos femininos'),
  ('Acessorios', 'Bolsas, cintos, relogios, oculos'),
  ('Calcados', 'Tenis, sandalias, botas')
ON DUPLICATE KEY UPDATE descricao = VALUES(descricao);

-- Pegar IDs das categorias
SET @cat_camisetas = (SELECT id FROM categorias WHERE nome = 'Camisetas' LIMIT 1);
SET @cat_calcas = (SELECT id FROM categorias WHERE nome = 'Calcas' LIMIT 1);
SET @cat_vestidos = (SELECT id FROM categorias WHERE nome = 'Vestidos' LIMIT 1);
SET @cat_acessorios = (SELECT id FROM categorias WHERE nome = 'Acessorios' LIMIT 1);
SET @cat_calcados = (SELECT id FROM categorias WHERE nome = 'Calcados' LIMIT 1);

-- Produtos (usando INSERT IGNORE para nao duplicar se ja existir pelo codigo_barras)
INSERT IGNORE INTO produtos (codigo_barras, descricao, categoria_id, preco_custo, preco_venda, margem_lucro, unidade, estoque_atual, estoque_minimo, ativo) VALUES
('7891000100103', 'Camiseta Basica Algodao Preta', @cat_camisetas, 22.00, 49.90, ROUND(((49.90-22.00)/22.00)*100, 2), 'un', 35, 10, 1),
('7891000200207', 'Camiseta Polo Masculina Azul', @cat_camisetas, 38.00, 89.90, ROUND(((89.90-38.00)/38.00)*100, 2), 'un', 18, 8, 1),
('7891000300301', 'Camiseta Estampada Floral', @cat_camisetas, 28.00, 59.90, ROUND(((59.90-28.00)/28.00)*100, 2), 'un', 12, 5, 1),
('7891000400405', 'Camiseta Manga Longa Branca', @cat_camisetas, 32.00, 69.90, ROUND(((69.90-32.00)/32.00)*100, 2), 'un', 3, 8, 1),
('7891000500509', 'Calca Jeans Skinny Escura', @cat_calcas, 55.00, 129.90, ROUND(((129.90-55.00)/55.00)*100, 2), 'un', 22, 8, 1),
('7891000600603', 'Calca Jeans Reta Classica', @cat_calcas, 50.00, 119.90, ROUND(((119.90-50.00)/50.00)*100, 2), 'un', 15, 6, 1),
('7891000700707', 'Calca Moletom Jogger Cinza', @cat_calcas, 40.00, 89.90, ROUND(((89.90-40.00)/40.00)*100, 2), 'un', 28, 10, 1),
('7891000800801', 'Calca Social Slim Preta', @cat_calcas, 60.00, 149.90, ROUND(((149.90-60.00)/60.00)*100, 2), 'un', 2, 5, 1),
('7891000900905', 'Vestido Midi Floral Verao', @cat_vestidos, 65.00, 159.90, ROUND(((159.90-65.00)/65.00)*100, 2), 'un', 10, 4, 1),
('7891001000109', 'Vestido Longo Festa Preto', @cat_vestidos, 90.00, 219.90, ROUND(((219.90-90.00)/90.00)*100, 2), 'un', 6, 3, 1),
('7891001100203', 'Vestido Curto Casual Jeans', @cat_vestidos, 55.00, 139.90, ROUND(((139.90-55.00)/55.00)*100, 2), 'un', 8, 4, 1),
('7891001200307', 'Bolsa Tote Couro Sintetico', @cat_acessorios, 45.00, 99.90, ROUND(((99.90-45.00)/45.00)*100, 2), 'un', 20, 5, 1),
('7891001300401', 'Cinto Couro Masculino Marrom', @cat_acessorios, 25.00, 59.90, ROUND(((59.90-25.00)/25.00)*100, 2), 'un', 30, 10, 1),
('7891001400505', 'Oculos de Sol Aviador', @cat_acessorios, 35.00, 79.90, ROUND(((79.90-35.00)/35.00)*100, 2), 'un', 1, 5, 1),
('7891001500609', 'Relogio Analogico Classico', @cat_acessorios, 80.00, 189.90, ROUND(((189.90-80.00)/80.00)*100, 2), 'un', 7, 3, 1),
('7891001600703', 'Tenis Casual Branco', @cat_calcados, 70.00, 169.90, ROUND(((169.90-70.00)/70.00)*100, 2), 'par', 14, 5, 1),
('7891001700807', 'Sandalia Rasteira Dourada', @cat_calcados, 30.00, 69.90, ROUND(((69.90-30.00)/30.00)*100, 2), 'par', 4, 5, 1),
('7891001800901', 'Bota Chelsea Preta Couro', @cat_calcados, 95.00, 229.90, ROUND(((229.90-95.00)/95.00)*100, 2), 'par', 9, 3, 1);

SELECT CONCAT('Importados: ', COUNT(*), ' produtos') AS resultado FROM produtos WHERE ativo = 1;
