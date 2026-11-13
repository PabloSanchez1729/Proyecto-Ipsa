# Modelo y medidas DAX

## Modelo de datos

| Tabla | Origen | Relación |
|---|---|---|
| `metricas` | `output/metricas.csv` | tabla de hechos (una fila por fecha y ticker) |
| `Calendario` | DAX | `Calendario[Fecha]` 1:N `metricas[fecha]` |
| `Tickers` | manual (ticker, nombre, sector) | `Tickers[ticker]` 1:N `metricas[ticker]` |
| `correlaciones` | `output/correlaciones.csv` | sin relaciones (tabla de consulta) |
| `resumen` | `output/resumen.csv` | sin relaciones (tabla de consulta) |

```dax
Calendario = CALENDAR(MIN(metricas[fecha]), MAX(metricas[fecha]))
```

## Medidas

Estas medidas **respetan los filtros de fecha** del dashboard. La tabla `resumen` no: siempre usa todo el historial.

```dax
Volatilidad Anual = STDEV.S(metricas[retorno]) * SQRT(252)

Retorno Anual = AVERAGE(metricas[retorno]) * 252

Max Drawdown = MIN(metricas[drawdown])

Tasa Libre de Riesgo = 0   -- reemplazar por un parámetro what-if o la TPM del Banco Central

Sharpe = DIVIDE([Retorno Anual] - [Tasa Libre de Riesgo], [Volatilidad Anual])

Retorno Acumulado =
VAR ultimaFecha = MAX(metricas[fecha])
RETURN CALCULATE(MAX(metricas[acum]), metricas[fecha] = ultimaFecha)
```

Nota: `Retorno Acumulado` parte de base 1 desde el inicio de los datos, no desde el inicio del filtro de fechas. Para rebasar a 100 en la fecha inicial del filtro, divide por el valor de `acum` en esa fecha.

## Páginas sugeridas

1. **Rendimiento:** línea de `acum` por ticker contra `^IPSA`.
2. **Riesgo:** `vol30` y `drawdown` en el tiempo, con segmentación por ticker.
3. **Relaciones:** matriz de `correlaciones` con formato condicional, y tabla `resumen`.
