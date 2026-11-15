# ERCOT Power Prices and Renewables

How do wind and solar shape electricity prices on the Texas grid, and what is that worth to a battery?

<!-- Put your headline finding and best chart here once the analysis is done. Recruiters read this part first. -->

## Questions

1. **Do wind and solar lower prices?** How much does the hourly price fall as the renewable share of demand rises, and has that changed from 2019 to 2025?
2. **What drives price spikes?** When do the most expensive hours happen, including Winter Storm Uri (February 2021), and what do they have in common?
3. **Would a battery have made money?** Backtest a battery that charges in cheap hours and discharges in expensive ones, at each trading hub.
4. **Can day-ahead prices be forecast?** Build a model and test it honestly against simple baselines.

## Findings

_Coming soon._

## Data

| Source | What | Frequency |
|---|---|---|
| ERCOT, Historical RTM and DAM Load Zone and Hub Prices | Real-time and day-ahead prices at the Houston, North, South, West and bus-average hubs | 15-minute (real-time), hourly (day-ahead) |
| U.S. EIA, Hourly Electric Grid Monitor (EIA-930) | ERCOT demand and generation by fuel (wind, solar, gas, coal, nuclear, storage) | Hourly |

Study window: 2019–2025. All times are stored in UTC and shown in Central time.

## How to run it

1. Install R packages: `install.packages(c("tidyverse", "readxl", "janitor", "lubridate", "httr2", "fs", "here"))`
2. Download the ERCOT price files and set up an EIA API key, following [`data/README.md`](data/README.md).
3. Open `ERCOT-price-analysis.Rproj` and run `source("run_all.R")`. This builds `data/processed/ercot_hourly.rds`.
4. Render the analysis: `quarto render analysis/`

## Project structure

```
R/
  00_setup.R               packages, study window, time-zone helper
  01_read_ercot_prices.R   ERCOT yearly price files -> hourly prices by hub
  02_download_eia.R        EIA API -> hourly demand and generation by fuel
  03_build_dataset.R       joins everything into data/processed/ercot_hourly.rds
analysis/
  01-explore.qmd           data checks and first look
  02-renewables-and-price.qmd
  03-price-spikes.qmd
  04-battery-backtest.qmd
  05-forecast.qmd
run_all.R                  rebuilds the processed data
```

## Tools

R: tidyverse, lubridate, readxl, httr2 · Quarto
