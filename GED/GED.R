library(here)
library(terra)
library(pbapply)

#Download the dataset
download.file("https://ucdp.uu.se/downloads/ged/ged231-csv.zip", 
              destfile = here("ged231-csv.zip"))
unzip(here("ged231-csv.zip"))

#Read-in the dataset
dataset <- read.csv(here("GEDEvent_v23_1.csv"))

#Create sequence of years
year_l <- unique(dataset$year)

#Create a list of events per year
yr <- lapply(year_l, function(x) {
  dataset[dataset$year == x, ]
})
names(yr) <- year_l

#Create raster
r <- raster(
  xmn = -180,
  xmx = 180,
  ymn = -90,
  ymx = 90,
  res = 0.1
)
values(r) <- NA

#Rasterize and export year-based rasters

dir.create(here("rasters"))

pblapply(seq_along(yr), function(x) {
  PA_raster <- terra::rasterize(yr[[x]][, c("longitude", "latitude")],
                                r, field = 1, background = NA)
  PA_name <- names(yr)[x]
  writeRaster(PA_raster, 
              here("rasters", paste0(PA_name, "_GEDEventv23", ".tif")), 
              filetype = "GTiff",
              overwrite = TRUE)
})

