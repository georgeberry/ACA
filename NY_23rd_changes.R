library(dplyr)

pop_df = read.csv("census_data.csv")
uninsured_df = read.csv("uninsured_data.csv")

counties = c("Allegany County",
             "Cattaraugus County",
             "Chautauqua County",
             "Chemung County",
             "Schuyler County",
             "Seneca County",
             "Tompkins County",
             "Yates County")

# Select NY state, 2013 estimate, all ages, only counties in 23rd
pop_df = pop_df %>%
  select(STATE, COUNTY, STNAME, CTYNAME, YEAR, TOT_POP, AGEGRP) %>%
  filter(STNAME=="New York", YEAR==6, AGEGRP==0, CTYNAME %in% counties)

# Select NY state only
uninsured_df = uninsured_df %>%
  filter(state_abbrev=="NY")

# Join on county name and compute basic statistics
agg_df = pop_df %>%
  left_join(uninsured_df, by=c("CTYNAME" = "county_name")) %>%
  mutate(num_covered = -0.01 * decrease.from.2013.to.2016 * TOT_POP,
         pop_frac = TOT_POP / sum(TOT_POP),
         rate_share_before = pop_frac * X2013.uninsured.rate,
         rate_share_after = pop_frac * X2016.uninsured.rate
         )

# Total covered since 2013 in NY's 23rd
sum(agg_df$num_covered)

# Uninsured rate 2013 in the 23rd
sum(agg_df$rate_share_before)

# Uninsured rate 2016 in the 23rd
sum(agg_df$rate_share_after)

# Number of lives saved each year
sum(agg_df$num_covered) / 176
