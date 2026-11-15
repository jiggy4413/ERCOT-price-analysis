# Reads ERCOT's yearly historical price files and saves one tidy hourly table.
#
# Input (download by hand first, see data/README.md):
#   data/raw/ercot-rtm/  yearly files from "Historical RTM Load Zone and Hub Prices" (NP6-785-ER)
#   data/raw/ercot-dam/  yearly files from "Historical DAM Load Zone and Hub Prices" (NP4-180-ER)
#   Each download is a .zip holding one .xlsx with one sheet per month. Zips are unpacked here.
#
# Output:
#   data/processed/prices_hourly.rds
#   columns: hour_start_utc, hub, rt_price, da_price   ($/MWh)

source("R/00_setup.R")

unzip_all <- function(dir) {
  for (z in dir_ls(dir, glob = "*.zip")) unzip(z, exdir = dir, overwrite = FALSE)
  dir_ls(dir, regexp = "\\.xlsx?$")
}

# Read every sheet of every workbook into one data frame with clean column names.
read_workbooks <- function(files) {
  map_dfr(files, function(f) {
    map_dfr(excel_sheets(f), function(s) {
      read_excel(f, sheet = s, col_types = "text") |> clean_names()
    })
  })
}

# Pick the first column whose cleaned name matches a pattern; fail loudly otherwise,
# so a format change at ERCOT shows up as a clear error instead of bad data.
pick <- function(df, pattern) {
  hit <- str_subset(names(df), pattern)
  if (length(hit) == 0) {
    stop("No column matching '", pattern, "'. Columns found: ",
         paste(names(df), collapse = ", "))
  }
  hit[1]
}

parse_ercot_date <- function(x) as_date(parse_date_time(x, orders = c("mdy", "ymd")))

# ---- Real-time market: 15-minute intervals, averaged to hourly ----
rtm_raw <- read_workbooks(unzip_all(path(RAW_DIR, "ercot-rtm")))

rtm <- rtm_raw |>
  transmute(
    date          = parse_ercot_date(.data[[pick(rtm_raw, "^delivery_date")]]),
    hour_ending   = as.integer(.data[[pick(rtm_raw, "^delivery_hour")]]),
    repeated_flag = .data[[pick(rtm_raw, "repeated_hour|dst")]],
    hub           = .data[[pick(rtm_raw, "^settlement_point_name$|^settlement_point$")]],
    price         = as.numeric(.data[[pick(rtm_raw, "settlement_point_price")]])
  ) |>
  filter(hub %in% HUBS, year(date) %in% YEARS) |>
  mutate(hour_start_utc = ercot_hour_start_utc(date, hour_ending, repeated_flag)) |>
  group_by(hour_start_utc, hub) |>
  summarise(rt_price = mean(price, na.rm = TRUE), n_intervals = n(), .groups = "drop")

# ---- Day-ahead market: already hourly; hour ending is text like "01:00" ----
dam_raw <- read_workbooks(unzip_all(path(RAW_DIR, "ercot-dam")))

dam <- dam_raw |>
  transmute(
    date          = parse_ercot_date(.data[[pick(dam_raw, "^delivery_date")]]),
    hour_ending   = as.integer(str_extract(.data[[pick(dam_raw, "^hour_ending")]], "^\\d+")),
    repeated_flag = .data[[pick(dam_raw, "repeated_hour|dst")]],
    hub           = .data[[pick(dam_raw, "^settlement_point")]],
    da_price      = as.numeric(.data[[pick(dam_raw, "settlement_point_price")]])
  ) |>
  filter(hub %in% HUBS, year(date) %in% YEARS) |>
  mutate(hour_start_utc = ercot_hour_start_utc(date, hour_ending, repeated_flag)) |>
  select(hour_start_utc, hub, da_price)

prices <- full_join(rtm, dam, by = c("hour_start_utc", "hub")) |>
  arrange(hub, hour_start_utc)

# Quick checks: each real-time hour should have 4 intervals, and no hour should repeat.
cat("Hours with != 4 real-time intervals:", sum(prices$n_intervals != 4, na.rm = TRUE), "\n")
cat("Duplicate hub-hours:", sum(duplicated(prices[c("hub", "hour_start_utc")])), "\n")
cat("Rows:", nrow(prices), " Range:", format(range(prices$hour_start_utc)), "\n")

write_rds(select(prices, -n_intervals), path(PROCESSED_DIR, "prices_hourly.rds"), compress = "gz")
