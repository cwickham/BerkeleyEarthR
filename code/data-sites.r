library(plyr)
options(stringsAsFactors = FALSE)

sites <- read.table("../data/site_detail.txt", comment.char = "%", sep = "\t",
  quote = "", colClasses = c("character", "character", rep("numeric", 6), 
    rep("character", 3), "numeric", rep("character", 4), rep("numeric", 3),
    "character"),
  strip.white = TRUE
  )
names(sites) <- c("StationID", "StationName", "Latitude", "Longitude",
 "Elevation", "Lat.Uncertainty", "Long.Uncertainty", 
 "Elev.Uncertainty", "Country", "State.Province.Code", "County", 
 "TimeZone", "WMOID", "CoopID", "WBANID", "ICAOID", "NumRelocations", 
 "NumSuggestedRelocations", "NumofSources", "Hash")

# missings encoded differently for different variables (see site_detail.txt)
# just fix the numeric ones here
missing_values <-  data.frame(var = c("Latitude", "Longitude", "Elevation", 
  "Lat.Uncertainty", "Long.Uncertainty", "Elev.Uncertainty", 
  "TimeZone"), val = c(-999, -999, -999, -9.9999, -9.9999, -9.999, -99))

rm_missing <- function(var, val, df) {
  x <- df[[var]]
  ifelse(x == val, NA, x)
}

sites[, missing_values$var] <- data.frame(mlply(missing_values, 
  rm_missing, df = sites))




