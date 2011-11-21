# install.packages(c("bigmemory", "bigtabulate", "ggplot2", "plyr"))
source("data-sites.r")
head(sites) 
nrow(sites) 

library(ggplot2)

# where are the stations? 
qplot(Longitude, Latitude, data = sites, size = I(0.5), alpha = I(0.5)) 
ggsave("../images/locations.png", width = 10, height = 6)

source("data-temps.r")

# look at some raw records
# cities I've lived in or near
cities_ids <- c(112592, 126036, 142944, 123993)  
subset(sites, StationID %in% cities_ids)

temps_cities <- data.frame(temps[mwhich(temps, rep("StationID", length(cities_ids)), 
  vals = as.list(cities_ids), comp = "eq", op = "OR"), ])
temps_cities <- join(temps_cities, subset(sites, StationID %in% cities_ids))

qplot(Date, Temperature, data = temps_cities, geom = "line") + 
  facet_wrap( ~ StationName, ncol = 1) + geom_smooth()
ggsave("../images/cities.png", width = 10, height = 10, dpi = 300)

# beware the data breaks
# no flag checking

library(bigtabulate)
site_indices <- bigsplit(temps, 'StationID')

summarise_temp <- function(site_record){
  avg_temp = median(site_record[, "Temperature"], na.rm = TRUE)
  spread_temp = mad(site_record[, "Temperature"], na.rm = TRUE)
  n_months = length(unique(site_record[, "Date"]))
  first_year = floor(min(site_record[, "Date"]))
  last_year = floor(max(site_record[, "Date"]))  
  data.frame(avg_temp, spread_temp, n_months, first_year, last_year)
}

site_summaries <- do.call(rbind, lapply(site_indices,
  function(i) summarise_temp(temps[i, c('Date','Temperature'), drop=FALSE])))
site_summaries$StationID <- rownames(site_summaries)

# merge summary and site location information
site_summaries <- join(site_summaries, sites, type = "inner")

# plot the avg_temp at sites with atleast 60 months
qplot(Longitude, Latitude, data = subset(site_summaries, n_months > 60), 
  alpha = I(0.5), colour = avg_temp) 
ggsave("../images/avg_temp.png", width = 10, height = 5, dpi = 300)

qplot(Longitude, Latitude, data = subset(site_summaries, n_months > 60), 
  alpha = I(0.5), colour = spread_temp) 
ggsave("../images/var_temp.png", width = 10, height = 5, dpi = 300)