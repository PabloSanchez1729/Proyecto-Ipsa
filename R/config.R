# Configuración central del proyecto.
# Todos los scripts se ejecutan desde la raíz (abrir proyecto-ipsa.Rproj en RStudio).

TICKERS <- c(
  "^IPSA",         # índice de referencia (precio, sin dividendos)
  "SQM-B.SN", "FALABELLA.SN", "COPEC.SN",
  "BCI.SN", "CHILE.SN", "CENCOSUD.SN", "CMPC.SN"
)

FECHA_INICIO <- "2018-01-01"
DB_PATH      <- "data/bolsa.duckdb"
OUTPUT_DIR   <- "output"
SQL_PATH     <- "sql/metricas.sql"
VISTAS_CSV   <- c("metricas", "correlaciones", "resumen")
