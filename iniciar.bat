@echo off
title Menuly PDV
color 0B

echo ====================================
echo  MENULY PDV - Inicializacao
echo ====================================
echo.

echo [1/2] Abrindo Backend...
start "" "%~dp0iniciar_backend.bat"

echo Aguardando backend iniciar (5s)...
timeout /t 5 /nobreak >nul

echo [2/2] Abrindo Frontend...
start "" "%~dp0iniciar_frontend.bat"

echo.
echo ====================================
echo  Pronto! Duas janelas foram abertas.
echo  Backend: http://127.0.0.1:8080
echo ====================================
echo.
timeout /t 3 /nobreak >nul
