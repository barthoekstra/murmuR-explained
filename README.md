# ibm-ml-explained

## Data and plots

Install Git LFS, then run `git lfs install` and `git lfs pull` after cloning.
Files under `data/` and `plots/` use LFS: Git stores small pointers, while the
file contents live in LFS storage. LFS storage still grows with new versions,
so avoid staging unchanged/generated copies or bundling data into one archive.

The minimal tracked dataset is `data/raw/`: the Parquet model inputs, selected
features, and model parameters. Parquet files are losslessly compressed with
Zstandard where it makes them smaller; filenames, values, column types, and
metadata are preserved. See [Arrow's Parquet writer documentation](https://arrow.apache.org/docs/python/generated/pyarrow.parquet.write_table.html)
for compression options. Keep future inputs compressed and split into individual
files so only changed files need uploading.

Yearly `data/processed/sv_{spring,autumn}_20YY.RDS` outputs are ignored to avoid
versioning generated SHAP results. Existing local files are retained. The notebook
contains their generation code, but regeneration has not been tested end to end.
The four older files (`sv_spring.RDS`, `sv_autumn.RDS`, `sv_all.RDS`, and
`sv_all_ranked.RDS`) are also ignored: no current code loads these files.
The current final-figure export blocks use the yearly SHAP files. Later
exploratory chunks reference similarly named in-memory objects, but do not
load the older RDS snapshots. Their full regeneration remains unverified.
To recreate the yearly SHAP files, install the analysis dependencies, create
`data/processed/`, and explicitly
run the `for (year_held_out in 2017:2024)` calculation block in
`explaining-migration-peaks.qmd` (currently marked `eval: false`). Later analysis
chunks read these files, so rendering alone does not recreate them.

Final figures in `plots/` are stored in LFS. `plots/temp/` is ignored.
Stage intended inputs and final figures with:

```sh
git add .gitattributes .gitignore README.md data/raw plots
```
