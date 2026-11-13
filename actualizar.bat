@echo off
cd /d "%~dp0"
Rscript R\ingesta.R
Rscript R\exportar.R
Rscript R\sanidad.R
pause
