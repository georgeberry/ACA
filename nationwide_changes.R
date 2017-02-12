library(stringr)
library(ggplot2)
library(dplyr)
library(data.table)
library(knitr)
library(rgdal)
library(scales)

medicaid_non_adopters = c("Alabama",
                          "Florida",
                          "Georgia",
                          "Idaho",
                          "Kansas",
                          "Maine",
                          "Mississippi",
                          "Missouri",
                          "Nebraska",
                          "North Carolina",
                          "Oklahoma",
                          "South Carolina",
                          "South Dakota",
                          "Tennessee",
                          "Texas",
                          "Utah",
                          "Virginia",
                          "Wisconsin",
                          "Wyoming")

twenty_twelve_county_results = read.csv("/Users/g/Desktop/2012_0_0_2.csv") %>%
  select(fips, vote1, vote2, totalvote)
twenty_sixteen_county_results = read.csv("/Users/g/Desktop/2016_0_0_2.csv") %>%
  select(fips, vote1, vote2, totalvote) %>%
  mutate(rep_win_county = ifelse(vote2 > vote1, 1, 0))
twenty_twelve_state_results = read.csv("/Users/g/Desktop/2012_0_0_1.csv") %>%
  select(name, vote1, vote2, totalvote)
twenty_sixteen_state_results = read.csv("/Users/g/Desktop/2016_0_0_1.csv") %>%
  select(name, vote1, vote2, totalvote) %>%
  mutate(rep_win_state = ifelse(vote2 > vote1, 1, 0))

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
                                      'total2016',
                                      'rep_win_county')
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
  left_join(county_election_results, by=c("FIPS"="fips")) %>%
  left_join(twenty_sixteen_state_results[,c("name", "rep_win_state")], by=c("STNAME"="name")) %>%
  mutate(non_expander = ifelse(STNAME %in% medicaid_non_adopters, 1, 0)) %>%
  .[complete.cases(.),]

agg_df$rep_margin_change = agg_df$rep_margin_change * 10

# County correlation

p1 = ggplot(agg_df) +
  geom_smooth(method="lm",
              se=F,
              aes(x=lives_saved_mid, y=rep_margin_change), color="black") +
  geom_point(aes(x=lives_saved_mid,
                 y=rep_margin_change,
                 color=factor(rep_win_county)),
             position=position_jitter(width=0.5),
             size=0.5,
             alpha=0.4) +
  scale_color_manual(values=c("blue", "red")) +
  lims(x = c(-50, 50), y=c(-5, 5)) +
  labs(x="Lives saved per 100k (moderate)",
       y="Red shift (percentage points) 2012-6") +
  guides(color = guide_legend(title = "Rep win")) +
  theme_bw()

ggsave("/Users/g/Desktop/p1.png", p1, device="png", width=8, height=4.5, dpi=800)

summary(lm(rep_margin_change ~ lives_saved_mid, data=agg_df))

summary(lm(rep_margin_change ~ lives_saved_mid + non_expander + lives_saved_mid * non_expander, data=agg_df))


# State election results
state_election_results = twenty_twelve_state_results %>%
  left_join(twenty_sixteen_state_results, by='name')
colnames(state_election_results) = c('name',
                                     'dem2012',
                                     'rep2012',
                                     'total2012',
                                     'dem2016',
                                     'rep2016',
                                     'total2016',
                                     'rep_win_state')
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

state_output_df = state_df[,c('STNAME',
                              'state_lives_saved_lower',
                              'state_lives_saved_mid',
                              'state_lives_saved_upper',
                              'rep_margin_change')]
colnames(state_output_df) = c('State name',
                              'Lives saved/100k (conservative)',
                              'Lives saved/100k (moderate)',
                              'Lives saved/100k (optimistic)',
                              '2016 red margin shift')

kable(head(state_output_df, n=10), digits=2)

# Full charts

kable(state_output_df, digits=2)

county_output_df = agg_df %>%
  select(STNAME, CTYNAME, TOT_POP, lives_saved_lower, lives_saved_mid, lives_saved_upper) %>%
  mutate(abs_lives_saved_lower = lives_saved_lower * TOT_POP / 100000,
         abs_lives_saved_mid =  lives_saved_mid * TOT_POP / 100000,
         abs_lives_saved_upper = lives_saved_upper * TOT_POP / 100000) %>%
  arrange(STNAME, CTYNAME)

# hacky for Dona Ana County, NM
county_output_df$CTYNAME = as.numeric(county_output_df$CTYNAME)
county_output_df$CTYNAME[1774] = 'Dona Ana County'

colnames(county_output_df) = c('State name',
                               'County name',
                               'County population',
                               'LS/100k (conservative)',
                               'LS/100k (moderate)',
                               'LS/100k (optimistic)',
                               'LS (conservative)',
                               'LS (moderate)',
                               'LS (optimistic)')


kable(county_output_df, digits=2)

# Map stuff here

us_counties = map_data("county")
us_states = map_data("state")

map_df = agg_df %>%
  select(STNAME, CTYNAME, lives_saved_mid) %>%
  mutate(STNAME = str_to_lower(STNAME),
         CTYNAME = str_replace(str_to_lower(CTYNAME), "( county)|( parish)", "")) %>%
  right_join(us_counties, by=c("STNAME"="region", "CTYNAME"="subregion"))

breaks = c(min(map_df$lives_saved_mid, na.rm=T), 0, max(map_df$lives_saved_mid, na.rm=T))


p2 = ggplot() +
  geom_polygon(data=map_df,
               aes(x=long, y=lat, group=group, fill=lives_saved_mid)) +
  geom_path(data=us_states,
            aes(x=long, y=lat, group=group),
            size=0.2,
            color="gray45") +
  scale_fill_gradientn(colors=c('red', 'white', 'deepskyblue4'),
                       values=rescale(breaks),
                       breaks=breaks,
                       labels=format(breaks)) +
  guides(fill = guide_colorbar(title = "Lives saved\n")) +
  theme_bw() +
  coord_map() +
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title.y=element_blank(),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.grid.major = element_blank(),
        panel.grid.minor = element_blank(),
        panel.border = element_blank(),
        panel.background = element_blank())
