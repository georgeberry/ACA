library(stringr)
library(ggplot2)
library(dtplyr)
library(knitr)

twenty_twelve_county_results = read.csv("/Users/g/Desktop/2012_0_0_2.csv") %>%
  select(fips, vote1, vote2, totalvote)
twenty_sixteen_county_results = read.csv("/Users/g/Desktop/2016_0_0_2.csv") %>%
  select(fips, vote1, vote2, totalvote)
twenty_twelve_state_results = read.csv("/Users/g/Desktop/2012_0_0_1.csv") %>%
  select(name, vote1, vote2, totalvote)
twenty_sixteen_state_results = read.csv("/Users/g/Desktop/2016_0_0_1.csv") %>%
  select(name, vote1, vote2, totalvote)

pop_df = read.csv("/Users/g/Desktop/cc-est2015-alldata.csv")
uninsured_df = read.csv("/Users/g/Desktop/County_Data_2016.csv") %>%
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

# County election results
# vote1 is Democrat, vote2 is Republican
county_election_results = twenty_twelve_county_results %>%
  left_join(twenty_sixteen_county_results, by='fips') %>%
  mutate(fips=as.character(fips))
colnames(county_election_results) = c('fips',
                                      'dem2012',
                                      'rep2012',
                                      'total2012',
                                      'dem2016',
                                      'rep2016',
                                      'total2016')
county_election_results = county_election_results %>%
  mutate(rep_margin_change = (rep2016 / total2016 - dem2016 / total2016) - (rep2012 / total2012 - dem2012 / total2012))

# Select NY state, 2013 estimate, all ages
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
         lives_saved_lower = num_covered / 1022 / TOT_POP * 100000,
         lives_saved_mid = num_covered / 455 / TOT_POP * 100000,
         lives_saved_upper = num_covered / 176 / TOT_POP * 100000) %>%
  .[complete.cases(.),] %>%
  select(state_abbrev,
         CTYNAME,
         STNAME,
         TOT_POP,
         FIPS,
         decrease.from.2013.to.2016,
         lives_saved_lower,
         lives_saved_mid,
         lives_saved_upper) %>%
  arrange(-lives_saved_mid) %>%
  left_join(county_election_results, by=c("FIPS"="fips"))

# Find top 10

top_ten = head(agg_df, n=10)

# County correlation

ggplot(agg_df, aes(x=lives_saved_mid, y=rep_margin_change)) +
  geom_point() +
  geom_smooth(method="lm", se=FALSE)

summary(lm(rep_margin_change ~ lives_saved_mid, data=agg_df))

# State level

# State election results
state_election_results = twenty_twelve_state_results %>%
  left_join(twenty_sixteen_state_results, by='name')
colnames(state_election_results) = c('name',
                                     'dem2012',
                                     'rep2012',
                                     'total2012',
                                     'dem2016',
                                     'rep2016',
                                     'total2016')
state_election_results = state_election_results %>%
  mutate(rep_share = rep2016 / total2016,
         rep_margin_change = (rep2016 / total2016 - dem2016 / total2016) - (rep2012 / total2012 - dem2012 / total2012))

state_df = agg_df %>%
  group_by(STNAME) %>%
  mutate(state_pop = sum(TOT_POP),
         state_frac = TOT_POP / state_pop,
         state_frac_lives_saved_lower = state_frac * lives_saved_lower,
         state_frac_lives_saved_mid = state_frac * lives_saved_mid,
         state_frac_lives_saved_upper = state_frac * lives_saved_upper
         ) %>%
  summarize(state_lives_saved_lower = sum(state_frac_lives_saved_lower),
            state_lives_saved_mid = sum(state_frac_lives_saved_mid),
            state_lives_saved_upper = sum(state_frac_lives_saved_upper)) %>%
  arrange(-state_lives_saved_mid) %>%
  left_join(state_election_results, by=c("STNAME" = "name"))

ggplot(state_df, aes(x=state_lives_saved_mid, y=rep_margin_change)) +
  geom_point()

summary(lm(rep_share ~ state_lives_saved_mid, data=state_df))

# Summarize

kable(head(state_df[,c('STNAME',
                       'state_lives_saved_lower',
                       'state_lives_saved_mid',
                       'state_lives_saved_upper',
                       'rep_margin_change')], n=10))

# Map stuff here

county_map = data.table(map_data('county'))
setkey(county_map, region, subregion)

ggplot(county_map, aes(x=long, y=lat, group=group)) + geom_polygon() + coord_map()
