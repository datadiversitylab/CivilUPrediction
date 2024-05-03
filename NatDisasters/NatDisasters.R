setwd("C:/Users/jhanc/Downloads/rasters_data")

library(stars)
library(sf)
library(units)

## Resampling the map for Global Volcano Proportional Economic Loss Risk Deciles (gdvolpro)

gdvolpro1 <- read_stars("C:/Users/jhanc/Downloads/rasters_data/gdvolpro.asc") # Here, we're reading the raster in .ASC format
gdvolpro1

write_stars(gdvolpro1, dsn = "C:/Users/jhanc/Downloads/rasters_data/gdvolpro1.tif", overwrite = T) ## Here, we're changing the format to .TIF and saving it, so it's easier to manage
detect.driver("gddrgpro1.tif")

gdvolpro1 <- read_stars("C:/Users/jhanc/Downloads/rasters_data/gdvolpro1.tif") ## Here we're reading the file we just created
gdvolpro1

plot(gdvolpro1, downsample = F)

grid <- st_as_stars(st_bbox(gdvolpro1), dx = 0.1, dy = 0.1) ## Now we're changing the scale from 0.04° to 0.1°.
grid
#plot(grid, breaks = "equal", key.pos = 4)


gdvolpro2 <- st_warp(gdvolpro1, grid, method = "bilinear", 
                     use_gdal = TRUE, no_data_value = -9999) ## resample the values of the gdvolpro1 raster into the new raster grid
plot(gdvolpro2)
gdvolpro2 ## Checking that it actually changed the scale

write_stars(gdvolpro2, dsn = "C:/Users/jhanc/Downloads/rasters_data/gdvolpro2.tif", overwrite = T) ## Here, we're saving our new raster with the new resampling
detect.driver("gdvolpro2.tif")
