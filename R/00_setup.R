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
YEARS <- 2021:2025

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
#
# Central time is UTC-5 in daylight time (CDT) and UTC-6 in standard time (CST).
# For each hour, try the CDT conversion; keep it if it maps back to the same clock
# time during daylight time, otherwise use CST. The repeated November hour is the
# only time both work: the first copy is CDT, the flagged second copy is CST.
ercot_hour_start_utc <- function(date, hour_ending, repeated_flag = "N") {
  clock <- as_datetime(date) + hours(as.integer(hour_ending) - 1)  # local clock time, stored as if UTC
  as_cdt <- clock + hours(5)
  as_cst <- clock + hours(6)
  local_cdt <- with_tz(as_cdt, LOCAL_TZ)
  cdt_valid <- force_tz(local_cdt, "UTC") == clock & dst(local_cdt)
  second_copy <- toupper(coalesce(as.character(repeated_flag), "N")) == "Y"
  if_else(cdt_valid & !second_copy, as_cdt, as_cst)
}
