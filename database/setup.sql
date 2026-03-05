-- ====================================================================
-- MENULY PDV - Setup Completo do Banco de Dados
-- Executa schema + seed na ordem correta
-- ====================================================================
-- Uso:
--   mysql -u root -p < setup.sql
-- ====================================================================

SOURCE schema.sql;
SOURCE seed.sql;

-- Verificação final
USE menuly_pdv;

SELECT '=== MENULY PDV - Setup Completo ===' AS info;

SELECT COUNT(*) AS total_tabelas
FROM information_schema.tables
WHERE table_schema = 'menuly_pdv';

SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'menuly_pdv'
ORDER BY table_name;

SELECT '=== Setup concluido com sucesso! ===' AS status;
