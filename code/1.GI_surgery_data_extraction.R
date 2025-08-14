
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

# First and last dates of procedures to include
first_admission_date = ymd("2017-01-01")
last_admission_date = ymd("2024-12-31")


gi_code_list <- unlist(procedure_list)



# 3. Load Data ---------------------------------------------------------------

# Get data ----  ## SQL query ammended from FOI2021-000798/IR2021-00575 to include additional variables for use in IR2023-00303
#

sql_query = glue("SELECT
                      LINK_NO, ADMISSION_DATE, HBTREAT_CURRENTDATE,
                      MAIN_CONDITION, OTHER_CONDITION_1, OTHER_CONDITION_2,
                      OTHER_CONDITION_3, OTHER_CONDITION_4, OTHER_CONDITION_5,
                      MAIN_OPERATION, OTHER_OPERATION_1, OTHER_OPERATION_2,
                      OTHER_OPERATION_3,
                      DATE_OF_MAIN_OPERATION, DATE_OF_OTHER_OPERATION_1,
                      DATE_OF_OTHER_OPERATION_2, DATE_OF_OTHER_OPERATION_3,
                      DISCHARGE_DATE, ADMISSION_TYPE, SIGNIFICANT_FACILITY, 
                      HBTREAT_CURRENTDATE, HBRES_CURRENTDATE,
                      AGE_IN_YEARS, SEX, POSTCODE, CIS_MARKER, CI_CHI_NUMBER
                  FROM
                      ANALYSIS.SMR01_PI
                  WHERE
                      (ADMISSION_DATE >=
                          TO_DATE('{first_admission_date}', 'yyyy-mm-dd') AND
                      ADMISSION_DATE <=
                          TO_DATE('{last_admission_date}', 'yyyy-mm-dd') AND
                      AGE_IN_YEARS >= 18)")

channel = dbConnect(odbc(), dsn = "SMRA",
                    uid = .rs.askForPassword("SMRA Username:"),
                    pwd = .rs.askForPassword("SMRA Password:"))

smr1_return = dbGetQuery(channel, statement = as.character(sql_query))

dbDisconnect(channel)

