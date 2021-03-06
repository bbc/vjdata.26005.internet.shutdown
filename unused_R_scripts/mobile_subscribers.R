pacman::p_load('tidyverse','dplyr', 'bbplot2', 'bbmap', 'zoo', 'ggimage')

# load in datasets
data <- read.csv('~/BBC/Projects/blackouts/source/mobile_subscriptions_2000-2018.csv')
WB_population <- read.csv('~/BBC/Projects/blackouts/source/WB_world_population.csv')
UN_population <- read.csv('~/BBC/Projects/blackouts/source/UN_world_population.csv')



# filter internet users dataset to each country's percentage by year
number_subscribers <- data %>%
  gather(year, value, 2:20) %>%
  arrange(Country, year, value) %>%
  filter(Country != "American Samoa")

number_subscribers[1, 3] = 0 # replaces Afghanistan 2000 with 0.0 so locf will run

# replace all NAs with the nearest value for the same country [could be year previous or 10, depending]
number_subscribers <- number_subscribers %>%
  mutate(latest = na.locf(value)) %>%
  select(-value) %>%
  spread(year, latest)


# load in world population datasets and join to include ISO codes
# filter out countries with no data, select 2018 UN data only
population <- WB_population %>%
  select(Country.Name, Country.Code)

population <- left_join(UN_population, population, by = c('Country' = 'Country.Name')) %>%
  select(Country, Country.Code, X2018) %>%
  filter(Country.Code != is.na(Country.Code))


# join population data to internet users dataset
mobile_subscribers <- left_join(number_subscribers, population, by = c('Country' = 'Country')) %>%
  filter(Country.Code != is.na(Country.Code)) %>%
  select(Country, Country.Code, X2018.x, X2018.y) %>%
  mutate(Population = X2018.y*1000) %>%
  select(Country, Country.Code, X2018.x, Population)

mobile_subscribers$Country.Code <- as.character(mobile_subscribers$Country.Code)
names(mobile_subscribers) = c('Country', 'Code', 'Mobile', 'Population')

mobile_subscribers$Pct_subscribed <- c(mobile_subscribers$Mobile/mobile_subscribers$Population*100)

# save out data
write.csv(mobile_subscribers, '~/BBC/Projects/blackouts/source/mobile_subscribers.csv')  

