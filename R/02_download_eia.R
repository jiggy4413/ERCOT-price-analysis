# Downloads hourly ERCOT generation by fuel and system demand from the U.S. Energy
# Information Administration (EIA-930 data, API v2).
#
# Needs a free API key: https://www.eia.gov/opendata/register.php
# Put it in a file named .Renviron in the project folder (it is git-ignored):
#   EIA_API_KEY=your_key_here
# then restart R.
#
# Output:
#   data/processed/gen_load_hourly.rds
#   columns: hour_start_utc, demand_mw, wind_mw, solar_mw, gas_mw, coal_mw, nuclear_mw,
#            storage_mw, other_mw  (MWh in the hour = average MW)

source("R/00_setup.R")

api_key <- Sys.getenv("EIA_API_KEY")
if (api_key == "") stop("Set EIA_API_KEY in .Renviron first (see the top of this script).")

# Fetch every page of an EIA v2 query (the API returns at most 5,000 rows per call).
eia_fetch <- function(route, facets, start, end) {
  page_size <- 5000
  offset <- 0
  out <- list()
  repeat {
    req <- request(paste0("https://api.eia.gov/v2/", route, "/data/")) |>
      req_url_query(
        api_key = api_key, frequency = "hourly", `data[0]` = "value",
        start = start, end = end, offset = offset, length = page_size,
        `sort[0][column]` = "period", `sort[0][direction]` = "asc"
      ) |>
      req_url_query(!!!facets, .multi = "explode") |>
      req_retry(max_tries = 5) |>
      req_throttle(rate = 2)
    resp <- req_perform(req) |> resp_body_json(simplifyVector = TRUE)
    rows <- as_tibble(resp$response$data)
    out[[length(out) + 1]] <- rows
    offset <- offset + nrow(rows)
    message(route, ": ", offset, " / ", resp$response$total, " rows")
    if (nrow(rows) < page_size || offset >= as.numeric(resp$response$total)) break
  }
  bind_rows(out)
}

# EIA hourly periods are UTC and mark the END of the hour ("2024-01-01T01" = 00:00-01:00 UTC).
# Check this in analysis/01-explore.qmd: solar output should peak around 1 p.m. Central.
eia_hour_start <- function(period) ymd_h(period, tz = "UTC") - hours(1)

download_year <- function(y) {
  start <- paste0(y, "-01-01T00")
  end   <- paste0(y + 1, "-01-01T06")   # small overlap so no UTC hour is cut off

  fuel <- eia_fetch("electricity/rto/fuel-type-data",
                    list(`facets[respondent][]` = "ERCO"), start, end)
  demand <- eia_fetch("electricity/rto/region-data",
                      list(`facets[respondent][]` = "ERCO", `facets[type][]` = "D"), start, end)
  list(fuel = fuel, demand = demand)
}

raw <- map(YEARS, download_year)
fuel_raw   <- map_dfr(raw, "fuel")
demand_raw <- map_dfr(raw, "demand")
write_rds(list(fuel = fuel_raw, demand = demand_raw), path(RAW_DIR, "eia_raw.rds"))

fuel_map <- c(WND = "wind_mw", SUN = "solar_mw", NG = "gas_mw", COL = "coal_mw",
              NUC = "nuclear_mw", BAT = "storage_mw")

fuel <- fuel_raw |>
  mutate(hour_start_utc = eia_hour_start(period),
         value = as.numeric(value),
         col = coalesce(fuel_map[fueltype], "other_mw")) |>
  group_by(hour_start_utc, col) |>
  summarise(value = sum(value, na.rm = TRUE), .groups = "drop") |>
  pivot_wider(names_from = col, values_from = value)

demand <- demand_raw |>
  transmute(hour_start_utc = eia_hour_start(period), demand_mw = as.numeric(value))

gen_load <- demand |>
  full_join(fuel, by = "hour_start_utc") |>
  filter(year(with_tz(hour_start_utc, LOCAL_TZ)) %in% YEARS) |>
  distinct(hour_start_utc, .keep_all = TRUE) |>
  arrange(hour_start_utc)

cat("Fuel codes seen:", paste(sort(unique(fuel_raw$fueltype)), collapse = ", "), "\n")
cat("Rows:", nrow(gen_load), " Missing demand hours:", sum(is.na(gen_load$demand_mw)), "\n")

write_rds(gen_load, path(PROCESSED_DIR, "gen_load_hourly.rds"), compress = "gz")
