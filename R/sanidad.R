# Chequeos de calidad. Si algo se ve raro aquí, no confíes en el dashboard.

suppressPackageStartupMessages(library(DBI))
source("R/config.R")

con <- dbConnect(duckdb::duckdb(), DB_PATH, read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

cat("\n1) Resumen (el beta de ^IPSA contra sí mismo debe ser 1):\n")
print(dbGetQuery(con, "SELECT * FROM resumen ORDER BY ticker"))

cat("\n2) Mayor retorno diario absoluto por ticker (>0.3 es casi seguro error de datos o evento corporativo):\n")
print(dbGetQuery(con, "
  SELECT ticker, MAX(ABS(retorno)) AS max_retorno
  FROM metricas GROUP BY ticker ORDER BY max_retorno DESC"))

cat("\n3) Diagonal de la matriz de correlación (todo debe ser 1):\n")
print(dbGetQuery(con, "SELECT * FROM correlaciones WHERE ticker_a = ticker_b"))

cat("\n4) Retornos exactamente 0 (muchos = acción poco líquida, subestima la volatilidad):\n")
print(dbGetQuery(con, "
  SELECT ticker,
         SUM(CASE WHEN retorno = 0 THEN 1 ELSE 0 END) AS dias_cero,
         COUNT(*) AS dias,
         ROUND(100.0 * SUM(CASE WHEN retorno = 0 THEN 1 ELSE 0 END) / COUNT(*), 1) AS pct
  FROM metricas GROUP BY ticker ORDER BY pct DESC"))
