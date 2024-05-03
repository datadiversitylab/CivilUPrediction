import rasterio
import numpy as np
import itertools

years = np.arange(1900,1902)
datasets = ['night', 'crop', 'fight']
width = 64
height = 64
count = 1

for y,d in itertools.product(years,datasets):
    print(y,d)
    fname = f'sample_data/{y}_{d}.tif'
    if d == 'fight':
        vmax = 2
    else:
        vmax = 100
    data = np.random.randint(0, vmax, size=(count,width,height), dtype=np.uint16)
    with rasterio.open(fname, 'w', width=width, height=height, count=count,dtype=np.uint16) as f:
        f.write(data)

