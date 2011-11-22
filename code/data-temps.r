library(bigmemory)
options(bigmemory.allow.dimnames=TRUE)

# binary path
binary.path <- "../Binaries/"

if (!file.exists(paste(binary.path, "tavg.bin", sep = ""))){
  temps <- read.big.matrix("../Data/data.txt", skip = 111,
    backingpath = binary.path, backingfile = 'tavg.bin', 
    descriptorfile = 'tavg.desc', 
    sep = "\t", 
    type = "double",
    col.names =  c("StationID", "SeriesNumber", "Date", "Temperature",
    "Uncertainty", "Observations", "TimeofObservation")
    )
} else {
  temps <- attach.big.matrix(dget(paste(binary.path, "tavg.desc", sep = "")), 
    path = binary.path)
}

