-- ====================================================================
-- MENULY PDV - Importação da Tabela NCM
-- 13.737 registros do CSV oficial do governo
-- ====================================================================
-- IMPORTANTE: O arquivo NCM.csv deve estar acessível pelo MySQL.
-- Se usar LOAD DATA LOCAL, habilite com: --local-infile=1
--
-- Uso via linha de comando:
--   mysql --local-infile=1 -u pdv_user -p menuly_pdv < import_ncm.sql
--
-- Ou copie o NCM.csv para o diretório seguro do MySQL:
--   SHOW VARIABLES LIKE 'secure_file_priv';
-- ====================================================================

USE menuly_pdv;

-- Limpar tabela antes de reimportar (caso necessário)
-- TRUNCATE TABLE ncm;

LOAD DATA LOCAL INFILE 'c:/Users/ron/Documents/other/projects_other/menuly_pdv/NCM.csv'
INTO TABLE ncm
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ';'
ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(co_ncm, co_unid, co_sh6, co_ppe, co_ppi, co_fat_agreg,
 co_cuci_item, co_cgce_n3, co_siit, co_isic_classe,
 co_exp_subset, no_ncm_por, no_ncm_esp, no_ncm_ing);

-- Verificar importação
SELECT COUNT(*) AS total_ncm_importados FROM ncm;
SELECT co_ncm, no_ncm_por FROM ncm LIMIT 5;
