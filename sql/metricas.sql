-- Todo el cálculo analítico vive aquí.
-- Convención: no usar punto y coma dentro de comentarios, porque exportar.R separa por ese carácter.

-- 1) Métricas diarias por activo.
--    retorno    = retorno logarítmico sobre precio (comparable con el IPSA)
--    retorno_aj = retorno logarítmico sobre precio ajustado por dividendos
--    vol30      = volatilidad anualizada en ventana de 30 observaciones (solo si la ventana está completa)
CREATE OR REPLACE VIEW metricas AS
WITH ret AS (
    SELECT fecha, ticker, cierre, ajustado,
           LN(cierre   / LAG(cierre)   OVER (PARTITION BY ticker ORDER BY fecha)) AS retorno,
           LN(ajustado / LAG(ajustado) OVER (PARTITION BY ticker ORDER BY fecha)) AS retorno_aj
    FROM precios
),
base AS (
    SELECT *,
        CASE WHEN COUNT(retorno) OVER w30 = 30
             THEN STDDEV_SAMP(retorno) OVER w30 * SQRT(252) END               AS vol30,
        EXP(SUM(retorno)    OVER (PARTITION BY ticker ORDER BY fecha))        AS acum,
        EXP(SUM(retorno_aj) OVER (PARTITION BY ticker ORDER BY fecha))        AS acum_aj
    FROM ret
    WHERE retorno IS NOT NULL
    WINDOW w30 AS (PARTITION BY ticker ORDER BY fecha
                   ROWS BETWEEN 29 PRECEDING AND CURRENT ROW)
)
SELECT *,
    acum / MAX(acum) OVER (PARTITION BY ticker ORDER BY fecha) - 1 AS drawdown
FROM base;

-- 2) Fechas en que TODOS los activos tienen dato (evita correlaciones sobre periodos distintos).
CREATE OR REPLACE VIEW fechas_comunes AS
SELECT fecha FROM metricas
GROUP BY fecha
HAVING COUNT(*) = (SELECT COUNT(DISTINCT ticker) FROM metricas);

-- 3) Matriz de correlación en formato largo (ideal para una matriz en Power BI).
CREATE OR REPLACE VIEW correlaciones AS
SELECT a.ticker AS ticker_a, b.ticker AS ticker_b,
       CORR(a.retorno, b.retorno) AS correlacion
FROM metricas a
JOIN metricas b ON a.fecha = b.fecha
WHERE a.fecha IN (SELECT fecha FROM fechas_comunes)
GROUP BY a.ticker, b.ticker;

-- 4) Resumen por activo (una fila por ticker). Sharpe con tasa libre de riesgo = 0.
CREATE OR REPLACE VIEW resumen AS
SELECT m.ticker,
       AVG(m.retorno)    * 252                                        AS retorno_anual,
       AVG(m.retorno_aj) * 252                                        AS retorno_anual_total,
       STDDEV_SAMP(m.retorno) * SQRT(252)                             AS vol_anual,
       AVG(m.retorno) * 252 / (STDDEV_SAMP(m.retorno) * SQRT(252))    AS sharpe_rf0,
       MIN(m.drawdown)                                                AS max_drawdown,
       COVAR_SAMP(m.retorno, i.retorno) / VAR_SAMP(i.retorno)         AS beta_ipsa
FROM metricas m
JOIN metricas i ON m.fecha = i.fecha AND i.ticker = '^IPSA'
GROUP BY m.ticker
