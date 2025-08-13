
# ─────────────────────────────────────────────────────────────
# Title: Extract Gastrointestinal Surgeries from SMRs Data
# Author: Maite de Haro Moro
# Date: 2025-08-13
# Description: This script loads SMRs data and filters for GI surgeries
# ─────────────────────────────────────────────────────────────



# 0. Load libraries ------------------------------------------------------------

library("tidyverse") # Includes dplyr, ggplot2, readr, etc.
library("odbc")
library("lubridate")
library("janitor")
library("glue")
library("phsmethods")
library(openxlsx)
library(readxl)
library(gdata)
library(dplyr)
library(haven)
library(stringr)    # For string operations


# 2. Set Paths ---------------------------------------------------------------

# data_path <- "data/smrs_data.csv"
# output_path <- "output/gi_surgeries.csv"

# 3. Define codes for GI surgery

gi_codes_upper <- read_excel("data/20250312 OPCS4 GI CODES.xlsx", 
                             sheet = "UPPER DIGESTIVE TRACT") %>% 
  rename(opcs_codes = Code)



# 3. Load Data ---------------------------------------------------------------
