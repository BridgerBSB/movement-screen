# Loading Necessary Libraries
library(tidyr)
library(dplyr)

# Reading in the CSV Data
transfer_pitch <- read.csv("pitching_transfers_data.csv")
transfer_pos <- read.csv("position_transfers_data.csv")


# Creating a wRAA / 100 At Bats to Standardize Everyone
transfer_pos <- transfer_pos %>%
  filter(AB >= 30)
transfer_pos$wRAA_100 <- (transfer_pos$wRAA / (ifelse(transfer_pos$AB == 0, epsilon, transfer_pos$AB))) * 100

# Creating New Data Frames to Calculate Easier
## Stats Before Transferring
transfer_pitch_before <- transfer_pitch %>%
  filter(row_number() %% 2 == 1)
transfer_pos_before <- transfer_pos %>%
  filter(row_number() %% 2 == 1)
## Stats After Transferring
transfer_pitch_after <- transfer_pitch %>%
  filter(row_number() %% 2 == 0)
transfer_pos_after <- transfer_pos %>%
  filter(row_number() %% 2 == 0)
## Combined Stats 
transfer_pitch_new <- left_join(transfer_pitch_before, transfer_pitch_after,
                                by = c("First.Name", 
                                       "Last.Name",
                                       "TransferYear",
                                       "Previous.School",
                                       "New.School"
                                       ))
transfer_pos_new <- left_join(transfer_pos_before, transfer_pos_after,
                                by = c("First.Name", 
                                       "Last.Name",
                                       "TransferYear",
                                       "Previous.School",
                                       "New.School"
                                ))
## Combined Needed Stats
transfer_pitch_complete <- transfer_pitch_new %>%
  select(First.Name, Last.Name, TransferYear, Previous.School, Previous.Division.ID.x, Previous.Division.x, 
         New.School, New.Division.ID.x, New.Division.x, Pos.x, Pos.y, GP.x, GP.y, GS_6.x, GS_6.y, 
         GS_8.x, GS_8.y, App.x, App.y, IP.x, IP.y, FIP.x, FIP.y)
transfer_pos_complete <- transfer_pos_new %>%
  select(First.Name, Last.Name, TransferYear, Previous.School, Previous.Division.ID.x, Previous.Division.x, 
         New.School, New.Division.ID.x, New.Division.x, Pos.x, Pos.y, GP.x, GP.y, GS.x, GS.y, 
         AB.x, AB.y, wRAA.x, wRAA.y, wRAA_100.x, wRAA_100.y)
### Rename Columns
new_colnames_pitch <- c("first_name", "last_name", "transfer_year", "prev_school", "prev_division_id",
                  "prev_division", "new_school", "new_division_id", "new_division", "prev_pos", "new_pos",
                  "prev_gp", "new_gp", "prev_gs_6", "new_gs_6", "prev_gs_8", "new_gs_8", "prev_app", "new_app",
                  "prev_ip", "new_ip", "prev_fip", "new_fip")
new_colnames_pos <- c("first_name", "last_name", "transfer_year", "prev_school", "prev_division_id",
                  "prev_division", "new_school", "new_division_id", "new_division", "prev_pos", "new_pos",
                  "prev_gp", "new_gp", "prev_gs", "new_gs", "prev_ab", "new_ab", "prev_wRAA", "new_wRAA",
                  "prev_wRAA_100", "new_wRAA_100")

colnames(transfer_pitch_complete) <- new_colnames_pitch
colnames(transfer_pos_complete) <- new_colnames_pos

# Parsing Data Frames into Categories
## Starting at Power 5
transfer_pitch_p5_p5 <- transfer_pitch_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 1)
transfer_pos_p5_p5 <- transfer_pos_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 1)

transfer_pitch_p5_midmaj <- transfer_pitch_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 2)
transfer_pos_p5_midmaj <- transfer_pos_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 2)

transfer_pitch_p5_d2 <- transfer_pitch_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 3)
transfer_pos_p5_d2 <- transfer_pos_complete %>%
  filter(prev_division_id == 1,
         new_division_id == 3)
## Starting at Mid Major
transfer_pitch_midmaj_p5 <- transfer_pitch_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 1)
transfer_pos_midmaj_p5 <- transfer_pos_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 1)

transfer_pitch_midmaj_midmaj <- transfer_pitch_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 2)
transfer_pos_midmaj_midmaj <- transfer_pos_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 2)

transfer_pitch_midmaj_d2 <- transfer_pitch_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 3)
transfer_pos_midmaj_d2 <- transfer_pos_complete %>%
  filter(prev_division_id == 2,
         new_division_id == 3)
## Starting at D2
transfer_pitch_d2_p5 <- transfer_pitch_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 1)
transfer_pos_d2_p5 <- transfer_pos_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 1)

transfer_pitch_d2_midmaj <- transfer_pitch_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 2)
transfer_pos_d2_midmaj <- transfer_pos_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 2)

transfer_pitch_d2_d2 <- transfer_pitch_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 3)
transfer_pos_d2_d2 <- transfer_pos_complete %>%
  filter(prev_division_id == 3,
         new_division_id == 3)

# Getting Out the NA Rows
## Starting at Power 5
transfer_pitch_p5_p5 <- transfer_pitch_p5_p5[!is.na(transfer_pitch_p5_p5$prev_fip), ]
transfer_pitch_p5_p5 <- transfer_pitch_p5_p5[!is.na(transfer_pitch_p5_p5$new_fip), ]
transfer_pos_p5_p5 <- transfer_pos_p5_p5[!is.na(transfer_pos_p5_p5$prev_wRAA_100), ]
transfer_pos_p5_p5 <- transfer_pos_p5_p5[!is.na(transfer_pos_p5_p5$new_wRAA_100), ]

transfer_pitch_p5_midmaj <- transfer_pitch_p5_midmaj[!is.na(transfer_pitch_p5_midmaj$prev_fip), ]
transfer_pitch_p5_midmaj <- transfer_pitch_p5_midmaj[!is.na(transfer_pitch_p5_midmaj$new_fip), ]
transfer_pos_p5_midmaj <- transfer_pos_p5_midmaj[!is.na(transfer_pos_p5_midmaj$prev_wRAA_100), ]
transfer_pos_p5_midmaj <- transfer_pos_p5_midmaj[!is.na(transfer_pos_p5_midmaj$new_wRAA_100), ]

transfer_pitch_p5_d2 <- transfer_pitch_p5_d2[!is.na(transfer_pitch_p5_d2$prev_fip), ]
transfer_pitch_p5_d2 <- transfer_pitch_p5_d2[!is.na(transfer_pitch_p5_d2$new_fip), ]
transfer_pos_p5_d2 <- transfer_pos_p5_d2[!is.na(transfer_pos_p5_d2$prev_wRAA_100), ]
transfer_pos_p5_d2 <- transfer_pos_p5_d2[!is.na(transfer_pos_p5_d2$new_wRAA_100), ]
## Starting at Mid Major
transfer_pitch_midmaj_p5 <- transfer_pitch_midmaj_p5[!is.na(transfer_pitch_midmaj_p5$prev_fip), ]
transfer_pitch_midmaj_p5 <- transfer_pitch_midmaj_p5[!is.na(transfer_pitch_midmaj_p5$new_fip), ]
transfer_pos_midmaj_p5 <- transfer_pos_midmaj_p5[!is.na(transfer_pos_midmaj_p5$prev_wRAA_100), ]
transfer_pos_midmaj_p5 <- transfer_pos_midmaj_p5[!is.na(transfer_pos_midmaj_p5$new_wRAA_100), ]

transfer_pitch_midmaj_midmaj <- transfer_pitch_midmaj_midmaj[!is.na(transfer_pitch_midmaj_midmaj$prev_fip), ]
transfer_pitch_midmaj_midmaj <- transfer_pitch_midmaj_midmaj[!is.na(transfer_pitch_midmaj_midmaj$new_fip), ]
transfer_pos_midmaj_midmaj <- transfer_pos_midmaj_midmaj[!is.na(transfer_pos_midmaj_midmaj$prev_wRAA_100), ]
transfer_pos_midmaj_midmaj <- transfer_pos_midmaj_midmaj[!is.na(transfer_pos_midmaj_midmaj$new_wRAA_100), ]

transfer_pitch_midmaj_d2 <- transfer_pitch_midmaj_d2[!is.na(transfer_pitch_midmaj_d2$prev_fip), ]
transfer_pitch_midmaj_d2 <- transfer_pitch_midmaj_d2[!is.na(transfer_pitch_midmaj_d2$new_fip), ]
transfer_pos_midmaj_d2 <- transfer_pos_midmaj_d2[!is.na(transfer_pos_midmaj_d2$prev_wRAA_100), ]
transfer_pos_midmaj_d2 <- transfer_pos_midmaj_d2[!is.na(transfer_pos_midmaj_d2$new_wRAA_100), ]
## Starting at D2
transfer_pitch_d2_p5 <- transfer_pitch_d2_p5[!is.na(transfer_pitch_d2_p5$prev_fip), ]
transfer_pitch_d2_p5 <- transfer_pitch_d2_p5[!is.na(transfer_pitch_d2_p5$new_fip), ]
transfer_pos_d2_p5 <- transfer_pos_d2_p5[!is.na(transfer_pos_d2_p5$prev_wRAA_100), ]
transfer_pos_d2_p5 <- transfer_pos_d2_p5[!is.na(transfer_pos_d2_p5$new_wRAA_100), ]

transfer_pitch_d2_midmaj <- transfer_pitch_d2_midmaj[!is.na(transfer_pitch_d2_midmaj$prev_fip), ]
transfer_pitch_d2_midmaj <- transfer_pitch_d2_midmaj[!is.na(transfer_pitch_d2_midmaj$new_fip), ]
transfer_pos_d2_midmaj <- transfer_pos_d2_midmaj[!is.na(transfer_pos_d2_midmaj$prev_wRAA_100), ]
transfer_pos_d2_midmaj <- transfer_pos_d2_midmaj[!is.na(transfer_pos_d2_midmaj$new_wRAA_100), ]

transfer_pitch_d2_d2 <- transfer_pitch_d2_d2[!is.na(transfer_pitch_d2_d2$prev_fip), ]
transfer_pitch_d2_d2 <- transfer_pitch_d2_d2[!is.na(transfer_pitch_d2_d2$new_fip), ]
transfer_pos_d2_d2 <- transfer_pos_d2_d2[!is.na(transfer_pos_d2_d2$prev_wRAA_100), ]
transfer_pos_d2_d2 <- transfer_pos_d2_d2[!is.na(transfer_pos_d2_d2$new_wRAA_100), ]

# Getting Out the NaN Rows
# Starting at Power 5
transfer_pitch_p5_p5 <- transfer_pitch_p5_p5[!is.nan(transfer_pitch_p5_p5$prev_fip), ]
transfer_pitch_p5_p5 <- transfer_pitch_p5_p5[!is.nan(transfer_pitch_p5_p5$new_fip), ]
transfer_pos_p5_p5 <- transfer_pos_p5_p5[!is.nan(transfer_pos_p5_p5$prev_wRAA_100), ]
transfer_pos_p5_p5 <- transfer_pos_p5_p5[!is.nan(transfer_pos_p5_p5$new_wRAA_100), ]

transfer_pitch_p5_midmaj <- transfer_pitch_p5_midmaj[!is.nan(transfer_pitch_p5_midmaj$prev_fip), ]
transfer_pitch_p5_midmaj <- transfer_pitch_p5_midmaj[!is.nan(transfer_pitch_p5_midmaj$new_fip), ]
transfer_pos_p5_midmaj <- transfer_pos_p5_midmaj[!is.nan(transfer_pos_p5_midmaj$prev_wRAA_100), ]
transfer_pos_p5_midmaj <- transfer_pos_p5_midmaj[!is.nan(transfer_pos_p5_midmaj$new_wRAA_100), ]

transfer_pitch_p5_d2 <- transfer_pitch_p5_d2[!is.nan(transfer_pitch_p5_d2$prev_fip), ]
transfer_pitch_p5_d2 <- transfer_pitch_p5_d2[!is.nan(transfer_pitch_p5_d2$new_fip), ]
transfer_pos_p5_d2 <- transfer_pos_p5_d2[!is.nan(transfer_pos_p5_d2$prev_wRAA_100), ]
transfer_pos_p5_d2 <- transfer_pos_p5_d2[!is.nan(transfer_pos_p5_d2$new_wRAA_100), ]
## Starting at Mid Major
transfer_pitch_midmaj_p5 <- transfer_pitch_midmaj_p5[!is.nan(transfer_pitch_midmaj_p5$prev_fip), ]
transfer_pitch_midmaj_p5 <- transfer_pitch_midmaj_p5[!is.nan(transfer_pitch_midmaj_p5$new_fip), ]
transfer_pos_midmaj_p5 <- transfer_pos_midmaj_p5[!is.nan(transfer_pos_midmaj_p5$prev_wRAA_100), ]
transfer_pos_midmaj_p5 <- transfer_pos_midmaj_p5[!is.nan(transfer_pos_midmaj_p5$new_wRAA_100), ]

transfer_pitch_midmaj_midmaj <- transfer_pitch_midmaj_midmaj[!is.nan(transfer_pitch_midmaj_midmaj$prev_fip), ]
transfer_pitch_midmaj_midmaj <- transfer_pitch_midmaj_midmaj[!is.nan(transfer_pitch_midmaj_midmaj$new_fip), ]
transfer_pos_midmaj_midmaj <- transfer_pos_midmaj_midmaj[!is.nan(transfer_pos_midmaj_midmaj$prev_wRAA_100), ]
transfer_pos_midmaj_midmaj <- transfer_pos_midmaj_midmaj[!is.nan(transfer_pos_midmaj_midmaj$new_wRAA_100), ]

transfer_pitch_midmaj_d2 <- transfer_pitch_midmaj_d2[!is.nan(transfer_pitch_midmaj_d2$prev_fip), ]
transfer_pitch_midmaj_d2 <- transfer_pitch_midmaj_d2[!is.nan(transfer_pitch_midmaj_d2$new_fip), ]
transfer_pos_midmaj_d2 <- transfer_pos_midmaj_d2[!is.nan(transfer_pos_midmaj_d2$prev_wRAA_100), ]
transfer_pos_midmaj_d2 <- transfer_pos_midmaj_d2[!is.nan(transfer_pos_midmaj_d2$new_wRAA_100), ]
## Starting at D2
transfer_pitch_d2_p5 <- transfer_pitch_d2_p5[!is.nan(transfer_pitch_d2_p5$prev_fip), ]
transfer_pitch_d2_p5 <- transfer_pitch_d2_p5[!is.nan(transfer_pitch_d2_p5$new_fip), ]
transfer_pos_d2_p5 <- transfer_pos_d2_p5[!is.nan(transfer_pos_d2_p5$prev_wRAA_100), ]
transfer_pos_d2_p5 <- transfer_pos_d2_p5[!is.nan(transfer_pos_d2_p5$new_wRAA_100), ]

transfer_pitch_d2_midmaj <- transfer_pitch_d2_midmaj[!is.nan(transfer_pitch_d2_midmaj$prev_fip), ]
transfer_pitch_d2_midmaj <- transfer_pitch_d2_midmaj[!is.nan(transfer_pitch_d2_midmaj$new_fip), ]
transfer_pos_d2_midmaj <- transfer_pos_d2_midmaj[!is.nan(transfer_pos_d2_midmaj$prev_wRAA_100), ]
transfer_pos_d2_midmaj <- transfer_pos_d2_midmaj[!is.nan(transfer_pos_d2_midmaj$new_wRAA_100), ]

transfer_pitch_d2_d2 <- transfer_pitch_d2_d2[!is.nan(transfer_pitch_d2_d2$prev_fip), ]
transfer_pitch_d2_d2 <- transfer_pitch_d2_d2[!is.nan(transfer_pitch_d2_d2$new_fip), ]
transfer_pos_d2_d2 <- transfer_pos_d2_d2[!is.nan(transfer_pos_d2_d2$prev_wRAA_100), ]
transfer_pos_d2_d2 <- transfer_pos_d2_d2[!is.nan(transfer_pos_d2_d2$new_wRAA_100), ]


# Finding Out the Regression %
epsilon <- 0.000001
## Starting at Power 5
fip_p5_p5 <- round(mean((transfer_pitch_p5_p5$new_fip - transfer_pitch_p5_p5$prev_fip) / (ifelse(transfer_pitch_p5_p5$prev_fip == 0, epsilon, transfer_pitch_p5_p5$prev_fip))), 4)
wRAA_p5_p5 <- round(mean((transfer_pos_p5_p5$new_wRAA_100 - transfer_pos_p5_p5$prev_wRAA_100) / (ifelse(transfer_pos_p5_p5$prev_wRAA_100 == 0, epsilon, transfer_pos_p5_p5$prev_wRAA_100))), 4)

fip_p5_midmaj <- round(mean((transfer_pitch_p5_midmaj$new_fip - transfer_pitch_p5_midmaj$prev_fip) / (ifelse(transfer_pitch_p5_midmaj$prev_fip == 0, epsilon, transfer_pitch_p5_midmaj$prev_fip))), 4)
wRAA_p5_midmaj <- round(mean((transfer_pos_p5_midmaj$new_wRAA_100 - transfer_pos_p5_midmaj$prev_wRAA_100) / (ifelse(transfer_pos_p5_midmaj$prev_wRAA_100 == 0, epsilon, transfer_pos_p5_midmaj$prev_wRAA_100))), 4)

fip_p5_d2 <- round(mean((transfer_pitch_p5_d2$new_fip - transfer_pitch_p5_d2$prev_fip) / (ifelse(transfer_pitch_p5_d2$prev_fip == 0, epsilon, transfer_pitch_p5_d2$prev_fip))), 4)
wRAA_p5_d2 <- round(mean((transfer_pos_p5_d2$new_wRAA_100 - transfer_pos_p5_d2$prev_wRAA_100) / (ifelse(transfer_pos_p5_d2$prev_wRAA_100 == 0, epsilon, transfer_pos_p5_d2$prev_wRAA_100))), 4)
## Starting at Mid Major
fip_midmaj_p5 <- round(mean((transfer_pitch_midmaj_p5$new_fip - transfer_pitch_midmaj_p5$prev_fip) / (ifelse(transfer_pitch_midmaj_p5$prev_fip == 0, epsilon, transfer_pitch_midmaj_p5$prev_fip))), 4)
wRAA_midmaj_p5 <- round(mean((transfer_pos_midmaj_p5$new_wRAA_100 - transfer_pos_midmaj_p5$prev_wRAA_100) / (ifelse(transfer_pos_midmaj_p5$prev_wRAA_100 == 0, epsilon, transfer_pos_midmaj_p5$prev_wRAA_100))), 4)

fip_midmaj_midmaj <- round(mean((transfer_pitch_midmaj_midmaj$new_fip - transfer_pitch_midmaj_midmaj$prev_fip) / (ifelse(transfer_pitch_midmaj_midmaj$prev_fip == 0, epsilon, transfer_pitch_midmaj_midmaj$prev_fip))), 4)
wRAA_midmaj_midmaj <- round(mean((transfer_pos_midmaj_midmaj$new_wRAA_100 - transfer_pos_midmaj_midmaj$prev_wRAA_100) / (ifelse(transfer_pos_midmaj_midmaj$prev_wRAA_100 == 0, epsilon, transfer_pos_midmaj_midmaj$prev_wRAA_100))), 4)

fip_midmaj_d2 <- round(mean((transfer_pitch_midmaj_d2$new_fip - transfer_pitch_midmaj_d2$prev_fip) / (ifelse(transfer_pitch_midmaj_d2$prev_fip == 0, epsilon, transfer_pitch_midmaj_d2$prev_fip))), 4)
wRAA_midmaj_d2 <- round(mean((transfer_pos_midmaj_d2$new_wRAA_100 - transfer_pos_midmaj_d2$prev_wRAA_100) / (ifelse(transfer_pos_midmaj_d2$prev_wRAA_100 == 0, epsilon, transfer_pos_midmaj_d2$prev_wRAA_100))), 4)
## Starting at D2
fip_d2_p5 <- round(mean((transfer_pitch_d2_p5$new_fip - transfer_pitch_d2_p5$prev_fip) / (ifelse(transfer_pitch_d2_p5$prev_fip == 0, epsilon, transfer_pitch_d2_p5$prev_fip))), 4)
wRAA_d2_p5 <- round(mean((transfer_pos_d2_p5$new_wRAA_100 - transfer_pos_d2_p5$prev_wRAA_100) / (ifelse(transfer_pos_d2_p5$prev_wRAA_100 == 0, epsilon, transfer_pos_d2_p5$prev_wRAA_100))), 4)

fip_d2_midmaj <- round(mean((transfer_pitch_d2_midmaj$new_fip - transfer_pitch_d2_midmaj$prev_fip) / (ifelse(transfer_pitch_d2_midmaj$prev_fip == 0, epsilon, transfer_pitch_d2_midmaj$prev_fip))), 4)
wRAA_d2_midmaj <- round(mean((transfer_pos_d2_midmaj$new_wRAA_100 - transfer_pos_d2_midmaj$prev_wRAA_100) / (ifelse(transfer_pos_d2_midmaj$prev_wRAA_100 == 0, epsilon, transfer_pos_d2_midmaj$prev_wRAA_100))), 4)

fip_d2_d2 <- round(mean((transfer_pitch_d2_d2$new_fip - transfer_pitch_d2_d2$prev_fip) / (ifelse(transfer_pitch_d2_d2$prev_fip == 0, epsilon, transfer_pitch_d2_d2$prev_fip))), 4)
wRAA_d2_d2 <- round(mean((transfer_pos_d2_d2$new_wRAA_100 - transfer_pos_d2_d2$prev_wRAA_100) / (ifelse(transfer_pos_d2_d2$prev_wRAA_100 == 0, epsilon, transfer_pos_d2_d2$prev_wRAA_100))), 4)