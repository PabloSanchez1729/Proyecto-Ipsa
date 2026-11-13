# Crea las vistas SQL y exporta los resultados a CSV para Power BI.

suppressPackageStartupMessages(library(DBI))
source("R/config.R")

dir.create(OUTPUT_DIR, showWarnings = FALSE, recursive = TRUE)

con <- dbConnect(duckdb::duckdb(), DB_PATH)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

# Leer el SQL, quitar comentarios de línea y ejecutar sentencia por sentencia
lineas <- readLines(SQL_PATH, encoding = "UTF-8")
lineas <- lineas[!grepl("^\\s*--", lineas)]
sentencias <- strsplit(paste(lineas, collapse = "\n"), ";")[[1]]
for (s in sentencias) if (nzchar(trimws(s))) dbExecute(con, s)

for (v in VISTAS_CSV) {
  ruta <- file.path(OUTPUT_DIR, paste0(v, ".csv"))
  dbExecute(con, sprintf("COPY (SELECT * FROM %s) TO '%s' (HEADER, DELIMITER ',')", v, ruta))
  cat("Exportado:", ruta, "\n")
}
