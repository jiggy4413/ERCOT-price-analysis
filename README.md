# ERCOT Power Prices and Renewables

How do wind and solar shape electricity prices on the Texas grid, and what is that worth to a battery?

<!-- Put your headline finding and best chart here once the analysis is done. Recruiters read this part first. -->

## Questions

1. **Do wind and solar lower prices?** How much does the hourly price fall as the renewable share of demand rises, and has that changed from 2021 to 2025?
2. **Does net load help forecast prices?** Does knowing net load (demand minus wind and solar) make day-ahead price forecasts better than simple baselines?
3. **Would a battery have made money?** Backtest a battery that charges in cheap hours and discharges in expensive ones, using the earlier findings and the forecast to choose when.

## Findings

(https://jiggy4413.github.io/ERCOT-price-analysis/)

## Data

| Source | What | Frequency |
|---|---|---|
| ERCOT, Historical RTM and DAM Load Zone and Hub Prices | Real-time and day-ahead prices at the Houston, North, South, West and bus-average hubs | 15-minute (real-time), hourly (day-ahead) |
| U.S. EIA, Hourly Electric Grid Monitor (EIA-930) | ERCOT demand and generation by fuel (wind, solar, gas, coal, nuclear, storage) | Hourly |

Study window: 2021–2025. All times are stored in UTC and shown in Central time.

## Getting the data

The data is not stored in this repository: it is public and free to download, and the files are large. To rebuild it:

1. **ERCOT prices (manual download).** Download the 2021–2025 yearly files from each page and save them, still zipped or as `.xlsx`:

   | Market | ERCOT report | Save to |
   |---|---|---|
   | Real-time | [Historical RTM Load Zone and Hub Prices (NP6-785-ER)](https://www.ercot.com/mp/data-products/data-product-details?id=NP6-785-ER) | `data/raw/ercot-rtm/` |
   | Day-ahead | [Historical DAM Load Zone and Hub Prices (NP4-180-ER)](https://www.ercot.com/mp/data-products/data-product-details?id=NP4-180-ER) | `data/raw/ercot-dam/` |

2. **Grid data (automatic).** Register for a free [EIA API key](https://www.eia.gov/opendata/register.php), then copy `.Renviron.example` to `.Renviron` and add the key. The download script fetches the rest.

More detail is in [`data/README.md`](data/README.md).

## How to run it

1. Install R packages: `install.packages(c("tidyverse", "readxl", "janitor", "lubridate", "httr2", "fs", "here"))`
2. Get the data (see above).
3. Open `ERCOT-price-analysis.Rproj` and run `source("run_all.R")`. This builds `data/processed/ercot_hourly.rds`.
4. Preview the site with `quarto preview`, or render it with `quarto render`.

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
  03-forecast.qmd
  04-battery-backtest.qmd
run_all.R                  rebuilds the processed data
```

## Tools

R: tidyverse, lubridate, readxl, httr2 · Quarto
