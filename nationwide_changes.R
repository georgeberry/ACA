library(dplyr)
library(stringr)

pop_df = read.csv("cc-est2015-alldata.csv")
uninsured_df = read.csv("County_Data_2016.csv") %>%
  mutate(county_fips = as.character(county_fips))

# This is a back-of-the-envelope estimate, so we make simplifying assumptions

# The most important assumption is how many people have to receive Medicaid
# for one life to be saved. A NEJM article estimates that 176 insured people
# saves one life per year. However, two experts in the area put this number
# at 455 in a recent WaPo article (even though they cite the NEJM article).
# To be safe, we will use both and produce two numbers here.

# The other main assumption is that private insurance saves lives at roughly
# the rate of Medicaid. This may or may not be justified. For simplicity, we
# will make this assumption here.

# Reserch article: http://www.nejm.org/doi/full/10.1056/NEJMsa1202099
# WaPo article: https://www.washingtonpost.com/posteverything/wp/2017/01/23/repealing-the-affordable-care-act-will-kill-more-than-43000-people-annually/

# Select NY state, 2013 estimate, all ages, only counties in 23rd
pop_df = pop_df %>%
  select(STATE, COUNTY, STNAME, CTYNAME, YEAR, TOT_POP, AGEGRP) %>%
  filter(YEAR==6, AGEGRP==0) %>%
  mutate(STATE = as.character(STATE),
         COUNTY = str_pad(COUNTY, 3, pad="0"),
         FIPS = paste(STATE, COUNTY, sep=""))


# Join on county name and compute basic statistics
agg_df = pop_df %>%
  left_join(uninsured_df, by=c("FIPS" = "county_fips")) %>%
  mutate(num_covered = -0.01 * decrease.from.2013.to.2016 * TOT_POP,
         lives_saved_lower = num_covered / 455 / TOT_POP * 100000,
         lives_saved_upper = num_covered / 176 / TOT_POP * 100000)

# Map stuff here

data(county.fips)
color_mapping = colorRamp(c("white", "blue"))

counties = county.fips %>%
  mutate(fips = as.character(fips)) %>%
  left_join(agg_df, by=c("fips"="FIPS")) %>%
  select(fips, polyname, lives_saved_lower) %>%
  .[complete.cases(.),] %>%
  filter(lives_saved_lower >= 0) %>%
  mutate(color = rgb(color_mapping(lives_saved_lower / max(lives_saved_lower))/255))

map('county', fill=T, col=counties$color)
