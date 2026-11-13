# Descarga precios desde Yahoo Finance y los carga en DuckDB.
# Es idempotente: se puede correr cada semana sin duplicar filas.

suppressPackageStartupMessages({
  library(tidyverse)
  library(quantmod)
  library(DBI)
})
source("R/config.R")

dir.create(dirname(DB_PATH), showWarnings = FALSE, recursive = TRUE)

bajar <- function(tk) {
  tryCatch({
    x <- getSymbols(tk, src = "yahoo", from = FECHA_INICIO, auto.assign = FALSE)
    tibble(
      fecha    = as.Date(index(x)),
      ticker   = tk,
      cierre   = as.numeric(Cl(x)),  # precio: comparable con el IPSA
      ajustado = as.numeric(Ad(x))   # ajustado por dividendos y splits
    )
  }, error = function(e) {
    message("FALLÓ: ", tk, " -> ", conditionMessage(e))
    NULL
  })
}

precios <- map_dfr(TICKERS, bajar) |> drop_na()
if (nrow(precios) == 0) stop("No se descargó ningún dato. Revisa tu conexión o los tickers.")

con <- dbConnect(duckdb::duckdb(), DB_PATH)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

# Si existe una base con esquema antiguo (sin 'ajustado'), avisar en vez de fallar a medias
if (dbExistsTable(con, "precios") && !"ajustado" %in% dbListFields(con, "precios")) {
  stop("Esquema antiguo detectado. Borra ", DB_PATH, " y vuelve a correr la ingesta.")
}

dbExecute(con, "
  CREATE TABLE IF NOT EXISTS precios (
    fecha    DATE,
    ticker   VARCHAR,
    cierre   DOUBLE,
    ajustado DOUBLE,
    PRIMARY KEY (fecha, ticker)
  )")

dbWriteTable(con, "nuevos", precios, temporary = TRUE, overwrite = TRUE)
dbExecute(con, "INSERT OR REPLACE INTO precios
                SELECT fecha, ticker, cierre, ajustado FROM nuevos")

cat("\n--- Revisión de calidad ---\n")
print(dbGetQuery(con, "
  SELECT ticker, COUNT(*) AS dias, MIN(fecha) AS desde, MAX(fecha) AS hasta
  FROM precios GROUP BY ticker ORDER BY ticker"))
