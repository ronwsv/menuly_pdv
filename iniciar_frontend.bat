@echo off
title Menuly PDV - Frontend
color 0B
set PATH=C:\tools\flutter\bin;C:\tools\dart-sdk\bin;%PATH%

echo ====================================
echo  MENULY PDV - Frontend Flutter
echo ====================================
echo.

cd /d "%~dp0frontend"
flutter run -d windows

echo.
echo Frontend encerrado.
pause
