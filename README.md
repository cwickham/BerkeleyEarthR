## QuickStart
If you are pretty familiar with R and just want to get playing:

*   `code/data-sites.r` and `code/data-temps.r` read in the Berkeley Earth text data files, `site_summary.txt` and `data.txt`, and produce R objects `temps` and `sites`.
*  The file `code/temps.r` shows examples of using the loaded data. If you are new to the `bigmemory` package play close attention to the subsetting of `temps` using `mwhich`.  

If that is too brief for you, read on.

## Introduction

The code provided here will help you read in the Berkeley Earth text data into R and perform some simple exploration.  It is not designed to reproduce the Berkeley Earth averaging procedure, or to do any meaningful climate analysis.  It's sole goal is to reduce some of the initial burden for people interested in using the Berkeley Earth dataset in R.  This comes in the form of two pieces of R code `code/data-sites.r` and `code/data-temps.r` which read the raw text files `site_detail.txt` and `data.txt` respectively. 

The complete set of station records is large.  With a modern machine it is possible to store it entirely in memory, however performing simple subsetting and summary calculations soon become too burdensome.  For that reason here I will use the [bigmemory](http://www.bigmemory.org/) to store the temperature records as a `big.matrix`, which reduces the memory burden substantially.  There is some initial overhead in creating the big.matrix (about 10 minutes on my laptop) but this is worthwhile in the long run.

This readme will guide you through the steps required to load the data into R and perform some basic actions.  The R code in this readme is also in the file `code/temps.r`.  

Currently this has been tested on a MacBook Pro, 2.66 GHz Intel Core 2 Duo, 8GB RAM, running R version 2.13.0 64-bit.

## Preliminaries

Make sure you have a recent version of R.  If it is less than 2.12 I suggest updating.  You can download the latest version at [http://cran.at.r-project.org/](http://cran.at.r-project.org/).  

You will also need the bigmemory, bigtabulate, ggplot2 and plyr packages.  You can get them in R by running:

    install.packages(c("bigmemory", "bigtabulate", "ggplot2", "plyr"))

This document assumes you have downloaded this README and the accompanying code (i.e. Downloads -> Download as zip on [github](/raw/master/BerkeleyEarthR)) and extracted them somewhere you like to work (i.e.  ~/Documents/BerkeleyEarthR).  Once you have done this the  folder will contain three directories: code, data and binaries. The directories data and binaries will be empty.  Our first step is to populate "data" with the text formatted data from BerkeleyEarth.

## Download the data

The text dataset is available from [Berkeley Earth](http://berkeleyearth.org/data.php).  Download it, unzip it and move the files into the data directory.  

The contents of the BerkeleyEarthR directory should now look like:

    readme.html	

    ./binaries:
    

    ./code:
    data-temps.r	temps.r
    data-sites.r	

    ./data:
    README.txt			site_flag_definitions.txt
    data.txt			site_summary.txt
    data_flag_definitions.txt	source_flag_definitions.txt
    flags.txt			sources.txt
    site_detail.txt

## Read in the site records
Open R and set the working directory to BerkeleyEarthR/Code

    setwd("~/Documents/BerkeleyEarthR/Code")

Source in the code to read the site_detail.txt file
    
    source("data-sites.r")

This may take a second to run but once it's finished you will have an R data.frame called `sites`.  It contains basic information for all 39028 sites in the Berkeley Earth merged dataset.  Let's take a quick look at `sites`:

    head(sites) 
    nrow(sites)    
Where are the sites? Let's plot their locations: 

    library(ggplot2)
    qplot(Longitude, Latitude, data = sites, size = I(0.5), alpha = I(0.5)) 

![plot](/raw/master/locations.png)

The resulting plot highlights the incredibly high density of stations in USA.  
You will have seen this warning message:

    Warning message:
    Removed 651 rows containing missing values (geom_point). 
This warning indicates 651 sites were not plotted because some or all of their location data is missing.
    
## Reading in temperature records

Let's read in the temperature records.

    source("data-temps.r")
This may take awhile to complete the first time you run it.  It populates the binaries folder with a binary file-backing for the data so that subsequent R sessions can attach the data instantly.

    head(temps)
    nrow(temps)

Two common tasks with temperature records are: selecting a much smaller set of site records for a closer look, and  performing some kind of summary on all sites.  I'll give an example of these two tasks are achieved with the records in the big.matrix.

### A subset of sites
I've lived in four cities in my adult life, I want a quick look at how their temperature records vary.  

The site ids for stations near these four cities are

    cities_ids <- c(112592, 126036, 142944, 123993)  
    subset(sites, StationID %in% cities_ids)

I obtained the ids by statements like:

    subset(sites, grepl("Auckland", StationName, ignore.case = TRUE))
and pulling the appropriate StationID by hand.

If `sites` was a regular matrix I could pull out the records pertaining to the stations of interest with `temps[which(temps$StationID %in% cities_ids), ]`. With a big.matrix, the same operation is achieved with `mwhich`, a bigmemory function that performs similar operations to `which` but with quite different syntax.

    temps_cities <- data.frame(temps[mwhich(temps, cols = rep("StationID", length(cities_ids)), 
      vals = as.list(cities_ids), comp = "eq", op = "OR"), ])
For each column in `cols` I test for equality (`comp = "eq"`) with the corresponding entry in `vals` and combine the results with a logical OR (`op = "OR"`) so the result of the mwhich statement is a logical equivalent to (StationID == 112592 or StationID == 126036 or ...).  This subsetting should only take a second or two (not bad for 14 million rows of data!).

Let's join the temperature records up with their site data and plot their temperatures:

    temps_cities <- join(temps_cities, subset(sites, StationID %in% cities_ids))
    qplot(Date, Temperature, data = temps_cities, geom = "line") + 
      facet_wrap( ~ StationName, ncol = 1) + geom_smooth()
      
![plot](/raw/master/cities.png)

I'm surprised that Auckland looks warmer than Berkeley!  I'd want to investigate further where these stations are located, a station at Berkeley Marina would give a very different picture to one up at the LBL lab. Looks like I'm in for my coldest winter yet... 

Some things to note:

* Beware the data gaps! Here, subsequent time points are joined with a line, one should break the lines when a month is missing data.  
* I haven't read in the flags so I don't know if some of this data has been marked as bad/suspect.
* You might have noticed earlier (`subset(sites, StationID %in% cities_ids)`) that the Berkeley and Corvallis sites have relocations.  I should also break the data at these times. 

### Site by site summary
I want a rough summary of all of the sites. The following function takes a single site record and calculates a simple average temperature, a measure of the variability of temperature, the number of months I have data, and the first and last year I have data for the site.  I use the median and median absolute deviation (mad) as measure of center and spread because I haven't done any cleaning or filtering for known or suspected bad values and I don't want the occasional outlying value to influence the measures too much. 

    summarise_temp <- function(site_record){
      avg_temp = median(site_record[, "Temperature"], na.rm = TRUE)
      spread_temp = mad(site_record[, "Temperature"], na.rm = TRUE)
      n_months = length(unique(site_record[, "Date"]))
      first_year = floor(min(site_record[, "Date"]))
      last_year = floor(max(site_record[, "Date"]))  
      data.frame(avg_temp, spread_temp, n_months, first_year, last_year)
    }

The usual split-apply-combine strategy works with big.matrices.  The `bigsplit` function  (in package bigtabulate) produces a list of indices for the rows in `sites` that have the same StationID.

    library(bigtabulate)
    site_indices <- bigsplit(temps, 'StationID')

For each index we pull the records for a single site and apply the `summarise_temp` function, then combine the results (again this might take a couple of minutes):

    site_summaries <- do.call(rbind, lapply(site_indices,
      function(i) summarise_temp(temps[i, c('Date','Temperature'), drop=FALSE])))
    site_summaries$StationID <- rownames(site_summaries)
This summary is most useful when we combine it with the site information:

    site_summaries <- join(site_summaries, sites, type = "inner")

Then we can plot average temperature by location (for sites with atleast 5 years of monthly measurements):
    
    qplot(Longitude, Latitude, data = subset(site_summaries, n_months > 60), 
      alpha = I(0.5), colour = avg_temp) 
![plot](/raw/master/avg_temp.png)

Or temperature variability by location:

    qplot(Longitude, Latitude, data = subset(site_summaries, n_months > 60), 
      alpha = I(0.5), colour = spread_temp) 
![plot](/raw/master/var_temp.png)

