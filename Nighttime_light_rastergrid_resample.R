setwd("/Users/hdg1/Documents/Nighttime_satellite_data")

library(stars)
library(sf)
library(units)

#file being read is different for every year 
F152000N <- read_stars("/Users/hdg1/Documents/Nighttime_satellite_data/F152002.v4/F152002.v4b_web.stable_lights.avg_vis.tif")
F152000N

#plot(F152000N, downsample = F)

grid <- st_as_stars(st_bbox(F152000N), dx = 0.1, dy = 0.1)
grid

#plot(grid, breaks = "equal", key.pos = 4)

F152000N2 <- st_warp(F152000N, grid, method = "bilinear", 
                  use_gdal = TRUE, no_data_value = -9999)
plot(F152000N2)
F152000N2

#file being created/written has to be renamed depending on original file read
write_stars(F152000N, dsn = "/Users/hdg1/Documents/Nighttime_satellite_data/F152002N2.tif")
detect.driver("F1520002N2.tif")
