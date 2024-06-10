# Loading Necessary Libraries
library(tidyr)
library(dplyr)

# Reading in the CSV Data
portal_pitch <- read.csv("portal_pitchers.csv")
portal_pos <- read.csv("portal_position.csv")
ncaa_university_link <- read.csv("ncaa_university_link.csv")

# Removing Players with 0 ABs
portal_pos <- portal_pos %>%
  filter(at_bats > 0)

# Left Joining University Link for Division ID (Position Only)
portal_pos <- left_join(portal_pos, ncaa_university_link[, c(5, 7)],
                        by = "ncaa_university_name")

# Taking Out Players Below D2
portal_pitch <- portal_pitch %>%
  filter(division_ID == 1 | division_ID == 2 | division_ID == 3)
portal_pos <- portal_pos %>%
  filter(division_ID == 1 | division_ID == 2 | division_ID == 3)

# Creating New Columns for Created FIP/wRAA
portal_pitch$p5_fip <- 0
portal_pitch$midmaj_fip <- 0
portal_pitch$d2_fip <- 0

portal_pos$p5_wRAA <- 0
portal_pos$midmaj_wRAA <- 0
portal_pos$d2_wRAA <- 0

# Calculating Data into New Columns
## Creating a FIP Variable
fip <- portal_pitch$fielding_independent_pitching
## Calculating & Inputting Data for FIP
portal_pitch$p5_fip <- as.numeric(ifelse(portal_pitch$division_ID == 1, 
                              (fip * fip_p5_p5) + fip,
                              ifelse(portal_pitch$division_ID == 2,
                                 (fip * fip_midmaj_p5) + fip,
                                 ifelse(portal_pitch$division_ID == 3,
                                        (fip * fip_d2_p5) + fip,
                                        "N/A"))))
portal_pitch$midmaj_fip <- as.numeric(ifelse(portal_pitch$division_ID == 1, 
                                  (fip * fip_p5_midmaj) + fip,
                                  ifelse(portal_pitch$division_ID == 2,
                                         (fip * fip_midmaj_midmaj) + fip,
                                         ifelse(portal_pitch$division_ID == 3,
                                                (fip * fip_d2_midmaj) + fip,
                                                "N/A"))))
portal_pitch$d2_fip <- as.numeric(ifelse(portal_pitch$division_ID == 1, 
                              (fip * fip_p5_d2) + fip,
                              ifelse(portal_pitch$division_ID == 2,
                                     (fip * fip_midmaj_d2) + fip,
                                     ifelse(portal_pitch$division_ID == 3,
                                            (fip * fip_d2_d2) + fip,
                                            "N/A"))))
## Creating a wRAA Variable
wRAA <- portal_pos$wRAA
## Calculating & Inputting Data for wRAA
portal_pos$p5_wRAA <- as.numeric(ifelse(portal_pos$division_ID == 1, 
                             (wRAA * wRAA_p5_p5) + wRAA,
                             ifelse(portal_pos$division_ID == 2,
                                    (wRAA * wRAA_midmaj_p5) + wRAA,
                                    ifelse(portal_pos$division_ID == 3,
                                           (wRAA * wRAA_d2_p5) + wRAA,
                                           "N/A"))))
portal_pos$midmaj_wRAA <- as.numeric(ifelse(portal_pos$division_ID == 1, 
                             (wRAA * wRAA_p5_midmaj) + wRAA,
                             ifelse(portal_pos$division_ID == 2,
                                    (wRAA * wRAA_midmaj_midmaj) + wRAA,
                                    ifelse(portal_pos$division_ID == 3,
                                           (wRAA * wRAA_d2_midmaj) + wRAA,
                                           "N/A"))))
portal_pos$d2_wRAA <- as.numeric(ifelse(portal_pos$division_ID == 1, 
                             (wRAA * wRAA_p5_d2) + wRAA,
                             ifelse(portal_pos$division_ID == 2,
                                    (wRAA * wRAA_midmaj_d2) + wRAA,
                                    ifelse(portal_pos$division_ID == 3,
                                           (wRAA * wRAA_d2_d2) + wRAA,
                                           "N/A"))))

# Creating New Rankings
p5_pitch_rank <- portal_pitch %>%
  arrange(p5_fip)

midmaj_pitch_rank <- portal_pitch %>%
  arrange(midmaj_fip)

d2_pitch_rank <- portal_pitch %>%
  arrange(d2_fip)

p5_pos_rank <- portal_pos %>%
  arrange(desc(p5_wRAA))

midmaj_pos_rank <- portal_pos %>%
  arrange(desc(midmaj_wRAA))

d2_pos_rank <- portal_pos %>%
  arrange(desc(d2_wRAA))

# Writing CSV Files
write.csv(p5_pitch_rank, "p5_pitch_rank.csv")
write.csv(p5_pos_rank, "p5_pos_rank.csv")
write.csv(midmaj_pitch_rank, "midmaj_pitch_rank.csv")
write.csv(midmaj_pos_rank, "midmaj_pos_rank.csv")
write.csv(d2_pitch_rank, "d2_pitch_rank.csv")
write.csv(d2_pos_rank, "d2_pos_rank.csv")
