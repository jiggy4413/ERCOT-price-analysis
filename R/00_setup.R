# Packages and shared settings used by every script in R/.
# Run once to install anything missing:
#   install.packages(c("tidyverse", "readxl", "janitor", "lubridate", "httr2", "fs", "here"))

suppressPackageStartupMessages({
  library(tidyverse)
  library(readxl)
  library(janitor)
  library(lubridate)
  library(httr2)
  library(fs)
})

# Study window (inclusive years). Change these to widen or narrow the study.
YEARS <- 2019:2025

# Trading hubs to keep. ERCOT also publishes load zones (LZ_*) if you want them later.
HUBS <- c("HB_HOUSTON", "HB_NORTH", "HB_SOUTH", "HB_WEST", "HB_BUSAVG")

# ERCOT settles in Central Prevailing Time; everything is stored in UTC and
# converted for display, so daylight-saving changes don't create gaps or duplicates.
LOCAL_TZ <- "America/Chicago"

RAW_DIR       <- "data/raw"
PROCESSED_DIR <- "data/processed"
dir_create(PROCESSED_DIR)

# Turn an ERCOT local date + hour-ending (1-24) into the UTC start of that hour.
# During the November fall-back, hour-ending 2 occurs twice; ERCOT marks the
# second one with a repeated-hour flag of "Y".
ercot_hour_start_utc <- function(date, hour_ending, repeated_flag = "N") {
  naive <- as_datetime(date) + hours(as.integer(hour_ending) - 1)
  first  <- force_tz(naive, LOCAL_TZ, roll_dst = c("post", "xfirst"))
  second <- force_tz(naive, LOCAL_TZ, roll_dst = c("post", "xlast"))
  with_tz(if_else(toupper(repeated_flag) == "Y", second, first), "UTC")
}
