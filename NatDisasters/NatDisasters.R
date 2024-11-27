setwd("C:/Users/jhanc/Box/Investigacion/Investigaciones/Side projects/Diversity_lab/CivilUnrest/Natural Disasters")

library(stars)
library(sf)
library(units)

# List of the files
files <- c("gdcyc", "gdcycpro", "gddrg", "gddrggdp", "gddrgpro", 
           "gdfld", "gdfldgdp", "gdfldmrt", "gdfldpro", "gdlnd", 
           "gdlndgdp", "gdlndmrt", "gdmhz", "gdmhzgdp", "gdmhzmrt",
           "gdpgagdp", "gdpgapro", "gdvol", "gdvolgdp", "gdvolmrt",
           "gdvolpro")

for (file in files) {
  # Define file paths
  asc_file <- paste0(file, ".asc")  # Input .asc file
  tif_file <- paste0(file, "1.tif") # Temporary .tif file
  final_tif <- paste0(file, "2.tif") # Reprojected .tif file
  
  # Read .asc file
  raster <- read_stars(asc_file)
  
  # Write as intermediate .tif
  write_stars(raster, dsn = tif_file, overwrite = TRUE)
  
  # Reload the .tif
  raster <- read_stars(tif_file)
  
  # Create grid with a resolution of 0.1 x 0.1
  grid <- st_as_stars(st_bbox(raster), dx = 0.1, dy = 0.1)
  
  # Warp (reproject) the raster to the new grid
  raster_reprojected <- st_warp(raster, grid, method = "bilinear", 
                                use_gdal = TRUE, no_data_value = -9999)

  # Save the final reprojected raster
  write_stars(raster_reprojected, dsn = final_tif, overwrite = TRUE)
  
  # Detect the driver
  detect.driver(final_tif)
  
  cat("Processed:", file, "\n")  # Check Progress
}
