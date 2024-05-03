library(ncdf4)
library(raster)
library(xml2)
library(rvest)
library(here)
library(R.utils)
library(pbapply)
library(terra)


options(timeout=300)

#Scrape CRU for links for cru_ts_4.07
URL <- "https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_4.07/cruts.2304141047.v4.07/prc/"
pg <- read_html(URL)
links <- html_attr(html_nodes(pg, "a"), "href")
targetLinks <- links[grep(".prc.dat.nc.gz", links)]
c_targetLinks <- lapply(targetLinks, function(x){
  paste0("https://crudata.uea.ac.uk/cru/data/hrg/cru_ts_4.07/cruts.2304141047.v4.07/prc/", x)
})

#download all the dat.nc files locally
dir.create(here("CRU_prc", "nc"))

pblapply(seq_along(targetLinks), function(x){
  download.file(c_targetLinks[[x]], 
                destfile = here("CRU_prc", "nc", targetLinks[x]), 
                overwrite = TRUE)
  gunzip(here("CRU_prc", "nc", targetLinks[x]), overwrite = TRUE)
})

#Rear in all files
targetncs <- list.files(here("CRU_prc", "nc"), full.names = TRUE)

dir.create(here("CRU_prc", "rasters"))

pblapply(seq_along(targetncs), function(x){
  raw_monthly <- brick(targetncs[x])
  nyears <- dim(raw_monthly)[3]/12
  tyears <- matrix(names(raw_monthly), 12)
  year <- sub("X", "", tyears[1,])
  year <- sub("\\..*", "", year)
  
  mean_yearly <- pblapply(1:ncol(tyears), function(y){
    mean_yearly_00 <- mean(raw_monthly[[ tyears[,y] ]])
    mean_yearly_01 <- disagg(rast(mean_yearly_00), fact = 5) 
    writeRaster(mean_yearly_01, 
                here("CRU_prc", "rasters", paste0(year[y], "_prc_CRU", ".tif")), 
                filetype = "GTiff",
                overwrite = TRUE)
  })
})

