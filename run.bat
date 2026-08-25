@echo off
title StockPredictor
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
if errorlevel 1 (
  echo.
  echo StockPredictor did not start. Review the error above.
  pause
)
