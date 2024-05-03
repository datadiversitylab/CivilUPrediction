import rasterio
import sklearn
import barmpy
import argparse
import numpy as np
from pathlib import Path
import os
import tqdm
from collections import defaultdict
from sklearn.model_selection import train_test_split
import sklearn.ensemble
import sklearn.metrics
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
plt.ion()

import warnings
warnings.filterwarnings('ignore')

if __name__ == '__main__':
    parser = argparse.ArgumentParser('make_comb')
    parser.add_argument('-f', '--files', default=[], action='extend', nargs='*')
    parser.add_argument('-o', '--output', default='results')
    parser.add_argument('-t', '--target', default='fight', help='Suffix name of target dataset')
    parser.add_argument('-s', '--seed', default=42, type=int)

    args = parser.parse_args()
    files = sorted(args.files)
    output = args.output
    target = args.target
    seed = args.seed

    os.makedirs(output, exist_ok=True)

    year_data = defaultdict(list)
    years = set()
    # TODO: check that all years have the same datasets available
    for f in files:
        # TODO: if no year, mark as used for all years
        year = int(os.path.basename(f)[:4])
        year_data[year].append(f)
        years.add(year)

    years = sorted(years)

    all_summary = []
    target_rasts = dict()
    pred_rasts = dict()
    models = dict()
    x_save_test = dict()
    y_save_test = dict()

    for year in years:
        dfiles = year_data[year]
        x = None
        for d in dfiles:
            with rasterio.open(d) as f:
                data = f.read()
                crs = f.crs
            if target in d:
                y = data
                dtype = y.dtype
                target_rasts[year] = y
            else:
                if x is None:
                    x = data
                else:
                    x = np.concatenate((x, data))
        # reshape into list of multivariate data points
        width, height = x.shape[1:]
        y = y.reshape(-1)
        x = x.reshape([-1,x.shape[0]])
        # TODO: be careful here, really want the same split every year
        xtrain, xtest, ytrain, ytest = train_test_split(x, y, random_state=seed)

        x_save_test[year] = xtest
        y_save_test[year] = ytest

        np.random.seed(seed)
        #model = sklearn.ensemble.RandomForestRegressor() # TODO: vary model types
        model = sklearn.ensemble.RandomForestClassifier() # TODO: vary model types
        model.fit(xtrain, ytrain)
        models[year] = model

        pred_train = model.predict(xtrain)
        r2_train = sklearn.metrics.r2_score(ytrain, pred_train)
        rmse_train = np.sqrt(sklearn.metrics.mean_squared_error(ytrain, pred_train))
        acc_train = sklearn.metrics.accuracy_score(ytrain, np.round(pred_train))
        auc_roc_train = sklearn.metrics.roc_auc_score(ytrain, np.round(pred_train))
        

        pred_test = model.predict(xtest)
        r2_test = sklearn.metrics.r2_score(ytest, pred_test)
        rmse_test = np.sqrt(sklearn.metrics.mean_squared_error(ytest, pred_test))
        acc_test = sklearn.metrics.accuracy_score(ytest, np.round(pred_test))
        auc_roc_test = sklearn.metrics.roc_auc_score(ytest, np.round(pred_test))

        res = [year, 'RF', r2_train, r2_test, rmse_train, rmse_test, acc_train, acc_test, auc_roc_train, auc_roc_test]
        print(res)
        all_summary.append(res)
        pred_all_raster = np.array(model.predict(x).reshape([1,width,height]), dtype=np.float32)
        pred_rasts[year] = pred_all_raster

        with rasterio.open(f'{output}/{year}_pred.tif', 'w', width=width, height=height, count=1,dtype=np.float32, crs=crs) as f2:
            f2.write(pred_all_raster)

    summary = pd.DataFrame(all_summary, columns=['Year', 'Model', 'R2_train', 'R2_test', 'RMSE_train', 'RMSE_test', 'Acc_train', 'Acc_test', 'ROC_AUC_train', 'ROC_AUC_test'])
    summary.to_csv(f'{output}/summary.csv', index=False)

    # plot the preds and target by year

    # compare year i to j
    r2_offyear = np.zeros((len(years), len(years)), dtype=np.float32)
    rmse_offyear = np.zeros((len(years), len(years)), dtype=np.float32)
    acc_offyear = np.zeros((len(years), len(years)), dtype=np.float32)
    auc_roc_offyear = np.zeros((len(years), len(years)), dtype=np.float32)
    for i,iyear in enumerate(years):
        for j,jyear in enumerate(years):
            pred = models[iyear].predict(x_save_test[jyear])
            r2_offyear[i,j] = sklearn.metrics.r2_score(y_save_test[jyear], pred)
            rmse_offyear[i,j] = np.sqrt(sklearn.metrics.mean_squared_error(y_save_test[jyear], pred))
            acc_offyear[i,j] = sklearn.metrics.accuracy_score(y_save_test[jyear], pred)
            auc_roc_offyear[i,j] = sklearn.metrics.roc_auc_score(y_save_test[jyear], np.round(pred))

    sns.heatmap(auc_roc_offyear, cbar=True, xticklabels=years, yticklabels=years)
    #sns.heatmap(auc_roc_offyear, vmin=0, vmax=1, cbar=True, xticklabels=years, yticklabels=years)
    plt.title('ROC-AUC for predictions across years')
    plt.savefig(f'{output}/auc_roc_years.png')
    plt.close()
