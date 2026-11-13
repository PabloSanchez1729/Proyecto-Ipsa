#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
Rscript R/ingesta.R
Rscript R/exportar.R
Rscript R/sanidad.R
