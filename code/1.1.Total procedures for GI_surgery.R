# ─────────────────────────────────────────────────────────────
# Title: Extract Gastrointestinal Surgeries from SMRs Data
# Author: Maite de Haro Moro
# Date: 2025-08-18
# Description: This script produces the total number of procedures for GI surgeries
# ─────────────────────────────────────────────────────────────


# 0. Libraries ------------------------------------------------------------


# 1. Run code 1 surgery data extraction  ----------------------------------


# 2. Procedures -----------------------------------------------------------


# Total procedures per type and Scotland ----------------------------------

data_filtered_check <- data_filtered %>%
  arrange(ci_chi_number, admission_date) %>%
  relocate(cis_marker, .after = admission_date) %>%
  relocate(discharge_date, .after = admission_date) %>%
  relocate(ci_chi_number, .after = link_no)


total_px_scotland <- data_filtered_check %>%
  mutate(year = year(op_date)) %>%
  distinct(link_no, op_date, cis_marker, .keep_all = TRUE) %>%  # Keep only one row per patient-marker-date
  group_by(year) %>%
  summarise(total_procedures = n(), .groups = "drop")



write.xlsx(total_px_scotland, "output/total_procedures_gi_upper_tracks_cotland_180825.xlsx")

# Total procedures per type and NHS Board ---------------------------------

total_px_nhs_board <- data_filtered_check %>%
  mutate(year = year(op_date)) %>%
  distinct(link_no, op_date, cis_marker, .keep_all = TRUE) %>%  # Keep only one row per patient-marker-date
  group_by(year, location) %>%
  summarise(total_procedures = n(), .groups = "drop")

trwwkth


write.xlsx(total_px_nhs_board, "output/total_procedures_nhs_board_18082025.xlsx")

