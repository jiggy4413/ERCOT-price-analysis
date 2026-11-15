# Data

Nothing in `data/` is committed to GitHub. Follow these steps to rebuild it.

## 1. ERCOT prices (manual download)

ERCOT posts one file per year for each market. Download the years in your study window (2019–2025 by default) from:

| Market | ERCOT report | Save the .zip files to |
|---|---|---|
| Real-time | [Historical RTM Load Zone and Hub Prices (NP6-785-ER)](https://www.ercot.com/mp/data-products/data-product-details?id=NP6-785-ER) | `data/raw/ercot-rtm/` |
| Day-ahead | [Historical DAM Load Zone and Hub Prices (NP4-180-ER)](https://www.ercot.com/mp/data-products/data-product-details?id=NP4-180-ER) | `data/raw/ercot-dam/` |

Both are also linked from ERCOT's [Market Prices page](https://www.ercot.com/mktinfo/prices). Leave the files zipped; `R/01_read_ercot_prices.R` unzips them.

## 2. Generation and demand (automatic)

`R/02_download_eia.R` downloads hourly ERCOT generation by fuel and demand from the [EIA Open Data API](https://www.eia.gov/opendata/) (EIA-930). It needs a free API key in `.Renviron`; see `.Renviron.example`.

## Files produced

| File | Contents |
|---|---|
| `data/processed/prices_hourly.rds` | Hourly real-time (averaged from 15-minute) and day-ahead prices by hub |
| `data/processed/gen_load_hourly.rds` | Hourly demand and generation by fuel |
| `data/processed/ercot_hourly.rds` | The two joined, plus local time fields, renewable share and net load |

All times are stored in UTC (`hour_start_utc`) and converted to Central time in `time_local`.
