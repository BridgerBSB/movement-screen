# Loading Necessary Libraries
library(tidyr)
library(dplyr)
library(coach)

# Reading in the CSV Data - Part 1
ncaa_university_link <- read.csv("ncaa_university_link.csv")

# Getting in Data From the User
team <- readline(prompt = "Please Enter Your Team's NCAA Name: ")
# roster_csv <- readline(prompt = "Please Enter the File Path of Your Team's Roster: ")
# team_roster <- read.csv(roster_csv)

team_division_df <- ncaa_university_link %>%
  filter(ncaa_university_name == team) %>%
  select(ncaa_university_name, division_ID)
team_division <- team_division_df$division_ID

# Reading in the CSV Data - Part 2
if(team_division == 1) {
  pitch_rank <- read.csv("p5_pitch_rank.csv")
  pos_rank <- read.csv("p5_pos_rank.csv")
} else if (team_division == 2) {
  pitch_rank <- read.csv("midmaj_pitch_rank.csv")
  pos_rank <- read.csv("midmaj_pos_rank.csv")
} else if (team_division == 3) {
  pitch_rank <- read.csv("d2_pitch_rank.csv")
  pos_rank <- read.csv("d2_pos_rank.csv")
}

# Removing Those with NA & NaN wRAA/FIP
pitch_rank <- pitch_rank[!is.na(pitch_rank$p5_fip), ]
pitch_rank <- pitch_rank[!is.nan(pitch_rank$p5_fip), ]
pos_rank <- pos_rank[!is.na(pos_rank$p5_wRAA), ]
pos_rank <- pos_rank[!is.nan(pos_rank$p5_wRAA), ]

# Removing Those with 0 AB/IP
pitch_rank <- pitch_rank[(pitch_rank$innings_pitched > 0), ]
pos_rank <- pos_rank[(pos_rank$AB > 0), ]

# Calculating wRAA/100 AB & FIP/50 IP
pitch_rank$fip_50 <- round((pitch_rank$p5_fip / pitch_rank$innings_pitched) * 100, 3)
pos_rank$wRAA_100 <- round((pos_rank$p5_wRAA / pos_rank$AB) * 100, 3)

# Creating a Score Value to Optimize
pitch_rank$score <- 0
pos_rank$score <- 0

# Retrieving the Transferring Players
pitch_transfers <- pitch_rank %>%
  filter(ncaa_university_name == team)

pos_transfers <- pos_rank %>%
  filter(ncaa_university_name == team)

# Creating Constraints Based on Transferring Players
ab <- sum(pos_transfers$AB)
ip <- sum(pitch_transfers$innings_pitched)
pos_players <- nrow(pos_transfers)
pitch_players <- nrow(pitch_transfers)
catcher_constraint <- nrow(pos_transfers[pos_transfers$position_id == 1, ])
corner_constraint <- nrow(pos_transfers[pos_transfers$position_id == 2, ])
middle_constraint <- nrow(pos_transfers[pos_transfers$position_id == 3, ])
outfield_constraint <- nrow(pos_transfers[pos_transfers$position_id == 4, ])
pitcher_constraint <- nrow(pos_transfers[pos_transfers$position_id == 5, ])
pos_constraints <- list(
  "1" = catcher_constraint,
  "2" = corner_constraint,
  "3" = middle_constraint,
  "4" = outfield_constraint,
  "5" = pitcher_constraint
)
pitch_constraints <- list(
  "5" = pitch_players
)

# Prepping Data for Model
pos_rank_model_1 <- pos_rank %>%
  select(player_id = CSE_PlayerID,
         player_id_ncaa = ncaa_player_id,
         player = Name,
         team = ncaa_university_name,
         position = position_id,
         salary = AB,
         fpts_proj = wRAA_100) %>%
  mutate(row_id = row_number())

pitch_rank_model_1 <- pitch_rank %>%
  select(player_id = CSE_PlayerID,
         player_id_ncaa = ncaa_player_id,
         player = Name,
         team = ncaa_university_name,
         salary = innings_pitched,
         fpts_proj = fip_50) %>%
  mutate(row_id = row_number())

pos_rank_model <- pos_rank_model_1 %>%
  select(row_id, player_id, player_id_ncaa, player, team, position, salary, fpts_proj)
  

pos_rank_model$player_id <- as.character(pos_rank_model$player_id)
pos_rank_model$position <- as.character(pos_rank_model$position)
pos_rank_model <- pos_rank_model[complete.cases(pos_rank_model), ]

pitch_rank_model <- pitch_rank_model_1 %>%
  mutate(position = "5") %>%
  select(row_id, player_id, player_id_ncaa, player, team, position, salary, fpts_proj)

pitch_rank_model$player_id <- as.character(pitch_rank_model$player_id)
pitch_rank_model <- pitch_rank_model[complete.cases(pitch_rank_model), ]

# Creating the Model with Different Constraints
pitch_model <- model_generic(pitch_rank_model, total_salary = ip, roster_size = pitch_players)
pos_model <- model_generic(pos_rank_model, total_salary = ab, roster_size = pos_players)

pitch_model <- add_generic_positions_constraint(pitch_model, pitch_rank_model, pitch_constraints)
pos_model <- add_generic_positions_constraint(pos_model, pos_rank_model, pos_constraints)

pitch_results <- as.data.frame(optimize_generic(pitch_rank_model, pitch_model, L = 1))
pos_results <- as.data.frame(optimize_generic(pos_rank_model, pos_model, L = 1))
