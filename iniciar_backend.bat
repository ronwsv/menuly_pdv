@echo off
title Menuly PDV - Backend
color 0A
set PATH=C:\tools\dart-sdk\bin;%PATH%

echo ====================================
echo  MENULY PDV - Backend Server
echo ====================================
echo.

cd /d "%~dp0backend"
dart run bin/server.dart

echo.
echo Backend encerrado.
pause
