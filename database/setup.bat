@echo off
echo ====================================
echo  MENULY PDV - Setup do Banco de Dados
echo ====================================
echo.

set /p MYSQL_PATH="Caminho do mysql.exe (Enter para 'mysql'): "
if "%MYSQL_PATH%"=="" set MYSQL_PATH=mysql

set /p MYSQL_USER="Usuario MySQL (Enter para 'root'): "
if "%MYSQL_USER%"=="" set MYSQL_USER=root

echo.
echo [1/3] Criando schema (26 tabelas)...
"%MYSQL_PATH%" -u %MYSQL_USER% -p --default-character-set=utf8mb4 < schema.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERRO ao criar schema!
    pause
    exit /b 1
)
echo      Schema criado com sucesso!

echo.
echo [2/3] Inserindo dados iniciais (seed)...
"%MYSQL_PATH%" -u %MYSQL_USER% -p menuly_pdv --default-character-set=utf8mb4 < seed.sql
if %ERRORLEVEL% NEQ 0 (
    echo ERRO ao inserir seed!
    pause
    exit /b 1
)
echo      Seed inserido com sucesso!

echo.
set /p IMPORT_NCM="[3/3] Importar tabela NCM (13.737 registros)? (S/N): "
if /i "%IMPORT_NCM%"=="S" (
    echo      Importando NCM...
    "%MYSQL_PATH%" --local-infile=1 -u %MYSQL_USER% -p menuly_pdv --default-character-set=utf8mb4 < import_ncm.sql
    if %ERRORLEVEL% NEQ 0 (
        echo ERRO ao importar NCM! Verifique se o arquivo NCM.csv esta acessivel.
    ) else (
        echo      NCM importado com sucesso!
    )
)

echo.
echo ====================================
echo  Setup concluido!
echo  Banco: menuly_pdv
echo  Usuario: pdv_user
echo  Tabelas: 26
echo ====================================
pause
