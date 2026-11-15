# Joins prices with generation and demand into the one table every analysis uses.
#
# Output:
#   data/processed/ercot_hourly.rds  (one row per hub per hour)
#   Adds local time fields and renewable share so the analysis files can start right away.

source("R/00_setup.R")

prices   <- read_rds(path(PROCESSED_DIR, "prices_hourly.rds"))
gen_load <- read_rds(path(PROCESSED_DIR, "gen_load_hourly.rds"))

ercot <- prices |>
  left_join(gen_load, by = "hour_start_utc") |>
  mutate(
    time_local      = with_tz(hour_start_utc, LOCAL_TZ),
    date_local      = as_date(time_local),
    hour_local      = hour(time_local),
    weekday         = wday(time_local, label = TRUE, week_start = 1),
    month           = month(time_local, label = TRUE),
    year            = year(time_local),
    renewable_mw    = wind_mw + solar_mw,
    renewable_share = renewable_mw / demand_mw,
    net_load_mw     = demand_mw - renewable_mw,   # demand left for gas, coal, nuclear, storage
    da_rt_spread    = da_price - rt_price
  )

cat("Rows:", nrow(ercot), "\n")
cat("Hours with prices but no grid data:", sum(is.na(ercot$demand_mw)), "\n")

write_rds(ercot, path(PROCESSED_DIR, "ercot_hourly.rds"), compress = "gz")
