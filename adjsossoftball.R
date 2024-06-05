library(softballR)
library(dplyr)
library(tidyverse)
library(gt)
library(gtExtras)

# load all scores and filter

scores <- load_ncaa_softball_scoreboard(2024, "D1")

na_stuff <- scores %>% filter(if_any(everything(), is.na))

# manually change the na columns, and then remove all instances with NA for all home columns as that represents arlington baptist not in the ncaa system

scores$home_team_id[which(scores$game_id == 5245151)] <- 572054
scores$home_team_id[which(scores$game_id == 4518512)] <- 572428
scores$home_team_id[which(scores$game_id == 4510109)] <- 572034

scores$home_team_runs[which(scores$game_id == 4492922)] <- 10
scores$home_team_runs[which(scores$game_id == 4505920)] <- 4
scores$home_team_runs[which(scores$game_id == 4510109)] <- 2
scores$home_team_runs[which(scores$game_id == 5284724)] <- 3
scores$home_team_runs[which(scores$game_id == 5284723)] <- 6
scores$home_team_runs[which(scores$game_id == 5284977)] <- 1
scores$home_team_runs[which(scores$game_id == 5335779)] <- 3

scores$away_team <- gsub("&#39;", "'", scores$away_team)
scores$home_team <- gsub("&#39;", "'", scores$home_team)
scores$away_team <- gsub("&amp;", "&", scores$away_team)
scores$home_team <- gsub("&amp;", "&", scores$home_team)

scores <- scores %>% filter(if_all(everything(), ~ !is.na(.)))

# load stats by game and then filter the scores db so it only has games with indiv stats recorded

stats_bygame <- load_ncaa_softball_playerbox(2024, "Hitting", "D1")

conferences <- ncaa_softball_teams(2024, "D1") %>% select(team = team_name, conf = conference)

teams <- stats_bygame %>% distinct(team)

teams <- left_join(teams, conferences, by = "team")

teams$conf[which(teams$team == "Saint Joseph's")] <- "Atlantic 10"
teams$conf[which(teams$team == "Texas A&M")] <- "SEC"
teams$conf[which(teams$team == "St. John's (NY)")] <- "Big East"
teams$conf[which(teams$team == "Florida A&M")] <- "SWAC"
teams$conf[which(teams$team == "Saint Mary's (CA)")] <- "WCC"
teams$conf[which(teams$team == "Tex. A&M-Commerce")] <- "Southland"
teams$conf[which(teams$team == "N.C. A&T")] <- "CAA"
teams$conf[which(teams$team == "A&M-Corpus Christi")] <- "Southland"
teams$conf[which(teams$team == "Alabama A&M")] <- "SWAC"
teams$conf[which(teams$team == "Saint Peter's")] <- "MAAC"
teams$conf[which(teams$team == "Mount St. Mary's")] <- "MAAC"

teams <- teams %>% distinct(team, .keep_all = TRUE) %>% filter(!is.na(conf))

# games must be between d1 teams and have individual stats recorded with it

scores <- scores %>% filter(game_id %in% stats_bygame$game_id, away_team %in% teams$team, home_team %in% teams$team)

stats_bygame <- stats_bygame %>% filter(team %in% teams$team, opponent %in% teams$team)

away_scores <- scores[,c(1:4, 10)] %>% select(game_id, everything())

names(away_scores) <- gsub("^away_", "", names(away_scores))

home_scores <- scores[,c(5:8, 10)] %>% select(game_id, everything())

names(home_scores) <- gsub("^home_", "", names(home_scores))

scores_long <- rbind(away_scores, home_scores) %>% group_by(game_id)

game_ids <- scores %>% select(game_id)

scores_long <- left_join(game_ids, scores_long, by = "game_id")

# generating the running ratings based on what occurred in the previous games for that team in the season

scores_long <- scores_long %>% group_by(team_id) %>% mutate(games_before = row_number() - 1, avg_team_runs = (cumsum(team_runs) - team_runs)/games_before)

opp_scores <- left_join(scores, scores_long, by = "game_id") %>%
  mutate(opp_team_runs = ifelse(away_team == team, home_team_runs, away_team_runs)) %>%
  select(game_id, team, team_id, team_logo, opp_team_runs) %>%
  group_by(team_id) %>% 
  mutate(games_before = row_number() - 1, avg_opp_team_runs = (cumsum(opp_team_runs) - opp_team_runs)/games_before)

# opponent offensive ratings based on their running totals of runs scored

opp_offense_ratings <- scores_long %>%
  ungroup() %>% 
  mutate(opp_off_rating = case_when(row_number() %% 2 == 0 ~ lag(avg_team_runs), row_number() %% 2 == 1 ~ lead(avg_team_runs))) %>%
  select(game_id, team, games_before, opp_off_rating)

# opponent defensive ratings based on their running totals of runs scored

opp_defense_ratings <- opp_scores %>%
  ungroup() %>% 
  mutate(opp_def_rating = case_when(row_number() %% 2 == 0 ~ lag(avg_opp_team_runs), row_number() %% 2 == 1 ~ lead(avg_opp_team_runs))) %>%
  select(game_id, team, games_before, opp_def_rating)

# generating wOBA manually

wOBA_scale = 0.8294/0.6533

hitting_stats <- stats_bygame %>%
  replace_na(list(h = 0, x2b = 0, x3b = 0, hr = 0, bb = 0, ibb = 0, hbp = 0, ab = 0, sf = 0)) %>%
  mutate(woba_num = 0.7883 * (bb - ibb) + 0.8078 * hbp + 0.8294 * (h - x2b - x3b - hr) + 1.425 * x2b + 1.7174 * x3b + 2.3785 * hr, woba_denom = ab + bb - ibb + sf + hbp, pa = ab + bb + sf + hbp) %>%
  filter(woba_denom != 0) %>%
  select(player, pos, team, opponent, game_id, woba_num, woba_denom, ab, pa)

hitting_stats <- left_join(hitting_stats, opp_defense_ratings, by = c("game_id", "team")) %>%
  left_join(teams, by = "team") %>%
  left_join(teams, by = c("opponent"="team")) %>%
  rename(team_conf = conf.x, opp_conf = conf.y) %>%
  distinct(player, game_id, .keep_all = TRUE)

hitting_stats$team_conf <- as.factor(hitting_stats$team_conf)
hitting_stats$opp_conf <- as.factor(hitting_stats$opp_conf)
hitting_stats$opp_def_rating <- scale(hitting_stats$opp_def_rating)

reg_hitting_data <- hitting_stats %>% filter(!is.nan(opp_def_rating)) 

# including the conferences of the team and the opponent team as factors

woba_model <- lm(woba_num ~ opp_def_rating + team_conf + opp_conf, data = reg_hitting_data)

woba_coefs <- data.frame(coef(woba_model))

# generating scaled coefficients for conferences whether they are the team of the player at hand or opponent team

conf_woba_coefs <- woba_coefs 
conf_woba_coefs$var <- row.names(woba_coefs) 
conf_woba_coefs <- conf_woba_coefs %>% filter(grepl('team_conf', var))
colnames(conf_woba_coefs)[1] <- "team_conf_coef"
conf_woba_coefs <- rbind(conf_woba_coefs, data.frame(team_conf_coef = 0, var = "team_confAAC"))
conf_woba_coefs[,1] <- scale(conf_woba_coefs[,1])
conf_woba_coefs$var <- gsub("team_conf", "", conf_woba_coefs$var)

opp_conf_woba_coefs <- woba_coefs 
opp_conf_woba_coefs$var <- row.names(woba_coefs) 
opp_conf_woba_coefs <- opp_conf_woba_coefs %>% filter(grepl('opp_conf', var))
colnames(opp_conf_woba_coefs)[1] <- "opp_conf_coef"
opp_conf_woba_coefs <- rbind(opp_conf_woba_coefs, data.frame(opp_conf_coef = 0, var = "opp_confAAC"))
opp_conf_woba_coefs[,1] <- scale(opp_conf_woba_coefs[,1])
opp_conf_woba_coefs$var <- gsub("opp_conf", "", opp_conf_woba_coefs$var)

# higher team_conf_coef means better team, lower opp_team_conf_coef means better opponent team, best adjustment should be when worse team plays better team which is why the coefficients are added then subtracted from the wraa along with rating adjustment

hitting_stats_final <- left_join(hitting_stats, conf_woba_coefs, by = c("team_conf"="var")) %>%
  left_join(opp_conf_woba_coefs, by = c("opp_conf"="var")) %>%
  mutate(rating_adjustment = ifelse(!is.na(opp_def_rating), coef(woba_model)[2] * opp_def_rating, 0), conf_diff = team_conf_coef + opp_conf_coef) %>%
  group_by(player) %>%
  summarize(pos = pos[which.max(tabulate(match(pos, unique(pos))))], team = last(team), team_conf = last(team_conf), woba_num = sum(woba_num), woba_denom = sum(woba_denom), wOBA = woba_num/woba_denom, rating_adjustment = sum(rating_adjustment), conf_diff = mean(conf_diff), adj_woba_num = sum(woba_num - rating_adjustment - conf_diff), adj_wOBA = adj_woba_num/woba_denom, pa = sum(pa), ab = sum(ab)) %>%
  filter(ab >= 50) %>%
  arrange(-adj_wOBA)

league_avg_woba = mean(hitting_stats_final$wOBA)

# generating wRAA and adjusted wRAA from the wOBA and adjusted wOBA respectively

hitting_stats_final <- hitting_stats_final %>%
  mutate(wRAA = (wOBA - league_avg_woba)/wOBA_scale * pa, adj_wRAA = (adj_wOBA - league_avg_woba)/wOBA_scale * pa) %>%
  arrange(-adj_wRAA)

write_csv(hitting_stats_final, "hitting_stats_final.csv")

# now moving on to the adjusted FIP calculation

fip_constant <- 2.66132462685197

# using the numerator of the FIP equation for the adjustments (due to the large variance based on how many innings you play)

pitching_stats <- load_ncaa_softball_playerbox(2024, "Pitching", "D1") %>%
  mutate(fip_num = 13 * hr_a + 3 * (bb + hb) - 2 * so) %>%
  select(player, team, opponent, game_id, ip, fip_num)

# same code format as the hitting aspect

pitching_stats <- left_join(pitching_stats, opp_offense_ratings, by = c("game_id", "team")) %>%
  left_join(teams, by = "team") %>%
  left_join(teams, by = c("opponent"="team")) %>%
  rename(team_conf = conf.x, opp_conf = conf.y) %>%
  distinct(player, game_id, .keep_all = TRUE)

pitching_stats$team_conf <- as.factor(pitching_stats$team_conf)
pitching_stats$opp_conf <- as.factor(pitching_stats$opp_conf)
pitching_stats$opp_off_rating <- scale(pitching_stats$opp_off_rating)

reg_pitching_data <- pitching_stats %>% filter(!is.nan(opp_off_rating)) 

fip_model <- lm(fip_num ~ opp_off_rating + team_conf + opp_conf, data = reg_pitching_data)

fip_coefs <- data.frame(coef(fip_model))

# generating scaled coefficients for conferences whether they are the team of the player at hand or opponent team

conf_fip_coefs <- fip_coefs 
conf_fip_coefs$var <- row.names(fip_coefs) 
conf_fip_coefs <- conf_fip_coefs %>% filter(grepl('team_conf', var))
colnames(conf_fip_coefs)[1] <- "team_conf_coef"
conf_fip_coefs <- rbind(conf_fip_coefs, data.frame(team_conf_coef = 0, var = "team_confAAC"))
conf_fip_coefs[,1] <- scale(conf_fip_coefs[,1])
conf_fip_coefs$var <- gsub("team_conf", "", conf_fip_coefs$var)

opp_conf_fip_coefs <- fip_coefs 
opp_conf_fip_coefs$var <- row.names(fip_coefs) 
opp_conf_fip_coefs <- opp_conf_fip_coefs %>% filter(grepl('opp_conf', var))
colnames(opp_conf_fip_coefs)[1] <- "opp_conf_coef"
opp_conf_fip_coefs <- rbind(opp_conf_fip_coefs, data.frame(opp_conf_coef = 0, var = "opp_confAAC"))
opp_conf_fip_coefs[,1] <- scale(opp_conf_fip_coefs[,1])
opp_conf_fip_coefs$var <- gsub("opp_conf", "", opp_conf_fip_coefs$var)

# lower team_conf_coef means better team, higher opp_team_conf_coef means better opponent team, best adjustment should be when worse team plays better team which is why the coefficients are added then added to fip along with rating adjustment which is subtracted

pitching_stats_final <- left_join(pitching_stats, conf_fip_coefs, by = c("team_conf"="var")) %>%
  left_join(opp_conf_fip_coefs, by = c("opp_conf"="var")) %>%
  mutate(rating_adjustment = ifelse(!is.na(opp_off_rating) & ip >= 1.0, coef(fip_model)[2] * opp_off_rating, 0), conf_diff = team_conf_coef + opp_conf_coef) %>%
  group_by(player) %>%
  summarize(team = last(team), team_conf = last(team), fip_num = sum(fip_num), rating_adjustment = sum(rating_adjustment), conf_diff = mean(conf_diff), adj_fip_num = sum(fip_num - rating_adjustment + conf_diff), IP = sum(ip), FIP = fip_num/IP + fip_constant, adj_FIP = adj_fip_num/IP + fip_constant) %>%
  filter(IP >= 100) %>%
  arrange(adj_FIP)

write_csv(pitching_stats_final, "pitching_stats_final.csv")

# fix the position so that there are less categories 

fix_position <- function(df) {
  df %>% mutate(pos = if_else(str_detect(pos, "^PH/|^PR/|^DH/|^DP/"), str_extract(pos, "(?<=/).*"), str_extract(pos, "^[^/]*")))
}

# formatting name and position 

hitting_stats_final$player <- sub("(\\w+),\\s(\\w+)","\\2 \\1", hitting_stats_final$player)
hitting_stats_final$player[which(hitting_stats_final$player == "Karli SPAID")] <- "Karli Spaid"
hitting_stats_final <- fix_position(hitting_stats_final)
pitching_stats_final$player <- sub("(\\w+),\\s(\\w+)","\\2 \\1", pitching_stats_final$player)

# grouping into categories

mif <- hitting_stats_final %>% filter(pos %in% c("SS", "2B")) %>% select(player, team, adj_wRAA) %>% head(10) %>% mutate(adj_wRAA = round(adj_wRAA, 2))
cif <- hitting_stats_final %>% filter(pos %in% c("1B", "3B", "DP", "DH")) %>% select(player, team, adj_wRAA) %>% head(10) %>% mutate(adj_wRAA = round(adj_wRAA, 2))
of <- hitting_stats_final %>% filter(pos %in% c("LF", "CF", "RF")) %>% select(player, team, adj_wRAA) %>% head(10) %>% mutate(adj_wRAA = round(adj_wRAA, 2))
c <- hitting_stats_final %>% filter(pos == "C") %>% select(player, team, adj_wRAA) %>% head(10) %>% mutate(adj_wRAA = round(adj_wRAA, 2))
p <- pitching_stats_final %>% select(player, team, adj_FIP) %>% head(10) %>% mutate(adj_FIP = round(adj_FIP, 2))

gt_align_caption <- function(left, right) {
  caption <- paste0(
    '<span style="float: left;">', left, '</span>',
    '<span style="float: right;">', right, '</span>'
  )
  return(caption)
}

caption = gt_align_caption("Data from <b>NCAA & softballR</b>", "College Sports Evaluation | <b>@CS_Eval</b>")

# function generating table

gt_func <- function(df, measure, lead_str, pos_str, measure_str, reverse_bool) {
  measure <- ensym(measure)
  save_table <- df %>% gt() %>% 
    gt_theme_538() %>%
    cols_align(
      align = "center",
      columns = c(player, team, !!measure)
    ) %>%
    gt_hulk_col_numeric(!!measure, reverse = reverse_bool) %>%
    cols_label(
      player = md("**Player**"),
      team = md("**Team**"),
      !!measure := md(paste0("**a", measure_str, "**"))
    ) %>%
    tab_header(
      title = add_text_img(paste0("2024 D1 Fastpitch Run ", lead_str, " Leaders: ", pos_str), "https://www.zoomintojune.com/uploads/1/1/0/4/110471165/published/cse-logo-gold-blue-registered-trademark-002.png?1713901904"),
      subtitle = md(paste0("*Ranked by **Adjusted ", measure_str, "***"))
    ) %>%
    opt_align_table_header(align = "center") %>%
    tab_style(
      style = list(
        cell_text(weight = "bold")
      ),
      locations = cells_body(
        columns = c(player, team, !!measure)
      )
    ) %>%
    tab_style(
      style = cell_text(align = "center", style = "italic"),
      locations = cells_row_groups(everything())
    ) %>%
    tab_source_note(html(caption))
  
  return(save_table)
}

gtsave(gt_func(mif, "adj_wRAA", "Creation", "Middle Infielders", "wRAA", FALSE), "middle_infielders.png", vwidth = 1500, vheight = 1000)
gtsave(gt_func(cif, "adj_wRAA", "Creation", "Corner Infielders", "wRAA", FALSE), "corner_infielders.png", vwidth = 1500, vheight = 1000)
gtsave(gt_func(of, "adj_wRAA", "Creation", "Outfielders", "wRAA", FALSE), "outfielders.png", vwidth = 1500, vheight = 1000)
gtsave(gt_func(c, "adj_wRAA", "Creation", "Catchers", "wRAA", FALSE), "catchers.png", vwidth = 1500, vheight = 1000)
gtsave(gt_func(p, "adj_FIP", "Prevention", "Pitchers", "FIP", TRUE), "pitchers.png", vwidth = 1500, vheight = 1000)
