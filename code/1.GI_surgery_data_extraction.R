
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
  rename(opcs_codes = Code) %>% 
  mutate(opcs_codes = toupper(opcs_codes)) #ensure codes are uppercase



# First and last dates of procedures to include
first_admission_date = ymd("2024-01-01")
last_admission_date = ymd("2024-12-31")


#gi_code_list <- unlist(procedure_list)



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



# Select the cases with GI surgery ----------------------------------------

# Check that there are not duplicated columns

names(smr1_return[duplicated(names(smr1_return))])

#If there are any duplicated columns that no needed remove

library(dplyr)

# Get unique column names
unique_names <- names(smr1_return)[!duplicated(names(smr1_return))]

# Select only those columns
smr1_return <- smr1_return %>%
  select(all_of(unique_names))

## Select the cases with GI surgery


gi_surgery_cases <- smr1_return %>%
  filter(
    MAIN_OPERATION %in% gi_codes_upper$opcs_codes |
      OTHER_OPERATION_1 %in% gi_codes_upper$opcs_codes |
      OTHER_OPERATION_2 %in% gi_codes_upper$opcs_codes |
      OTHER_OPERATION_3 %in% gi_codes_upper$opcs_codes
  )

## Number of surgeries accross all the operations:
### Combine all operation columns into one long column:

gi_surgery_long <- gi_surgery_cases %>% 
  select(MAIN_OPERATION, OTHER_OPERATION_1, OTHER_OPERATION_2, OTHER_OPERATION_3) %>% 
  pivot_longer(cols = everything(), names_to = "operation_type", values_to = "opcs_code") %>% 
  filter(!is.na(opcs_code))

#Count frequency of each code:
gi_surgery_summary2 <- gi_surgery_long %>% 
  filter(opcs_code %in% gi_codes_upper$opcs_codes) %>% 
  count(opcs_code, sort = TRUE)



# Create a Pivot table specification --------------------------------------

# Need to pivot longer to filter each operation by its date later
# But we need to pivot in matching pairs of columns (main_operation with
# date_of_main_operation etc), so manually set a pivot spec
df_spec = data.frame(
  # Which columns are we taking data from?
  .name = c("main_operation", "other_operation_1",
            "other_operation_2",  "other_operation_3",
            "date_of_main_operation", "date_of_other_operation_1",
            "date_of_other_operation_2", "date_of_other_operation_3"),
  # Which columns does the data go into?
  .value = c("op_code", "op_code",
             "op_code", "op_code",
             "op_date", "op_date",
             "op_date", "op_date"),
  # New column that labels each row (here is used to identify which col the
  # data originally came from)
  op_type = c("main_operation", "other_operation_1",
              "other_operation_2",  "other_operation_3"),
  # Will get odd errors about mis-matching types without this
  stringsAsFactors = FALSE)

data = pivot_longer_spec(smr1_return, df_spec, values_drop_na = TRUE)

data["op_year"] = year(data[["op_date"]]) # Calendar year required for this IR

data = left_join(data, loc_def, by = c("hbtreat_currentdate" = "loc_code"))

test 2
