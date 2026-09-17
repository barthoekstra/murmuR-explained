# Data used by the figure workflow

## Source data and processing

The source data and processing workflows underlying this analysis are documented
in the following repositories:

- [murmuR-paper](https://github.com/barthoekstra/murmuR-paper): analysis and figure
  scripts accompanying the paper. Zenodo DOI:
  [10.5281/zenodo.19823028](https://doi.org/10.5281/zenodo.19823028).
- [murmuR](https://github.com/barthoekstra/murmuR): the R package implementing the
  migration simulation, data processing, and modelling pipeline. Zenodo DOI:
  [10.5281/zenodo.19823042](https://doi.org/10.5281/zenodo.19823042).

## Files and relationships

`raw/model_data/{radar}/{radar}_{year}_{season}_3km_noninterpolated.parquet`
contains tabular model inputs, read in filename order by `create_task()` in
`R/functions_training.R`. The current figures use the 16 `nlhrw` files spanning
spring/autumn 2017–2024. The `nldhl` files are retained but unused by this notebook.
Parquet preserves column types and is readable outside R.

`raw/model_features/fs_selected_top_features_{radar}_{season}_dynamic.RDS`
contains selected predictor names. The corresponding `raw/model_params/` RDS
contains tuned learner parameters. Read these R-specific objects with `readRDS()`.

`processed/sv_{season}_{year}.RDS` is a `shapviz` object. Its `S` matrix contains
SHAP contributions, `X` contains corresponding predictor values, and `baseline`
is the model baseline. The filename year is the **training exclusion**, not an
observation-year filter. Each file explains all observations for that season.
The plotting code verifies predictor values and row counts against the model
inputs before combining them by row position. Do not sort or filter one side of
this relationship independently.

The 16 yearly processed files (spring/autumn 2017–2024) are required for the
figures and tracked with Git LFS. Run `git lfs pull` from the repository root
to retrieve them.

## Fields used directly in figures

The descriptions below record usage in this repository; they are not a complete
upstream data dictionary.

| Field | Meaning or treatment in the notebook |
| --- | --- |
| `datetime` | Observation timestamp; the stored time zone is preserved |
| `year` | Observation year; used for training exclusion and seasonal ranking |
| `height` | Observation height, labelled in metres in the original analysis |
| `dens` | Bird density; model response and weight for wind marginal densities |
| `mtr` | Hourly migration traffic rate; one value per timestamp is summed within a night |
| `period_rank_mtr` | Existing night/group identifier used to aggregate timestamps |
| `nightly_mt` | Derived sum of hourly `mtr`, labelled birds/km in the figures |
| `nightly_mt_rank` | Derived descending rank of `nightly_mt` within year/season, with minimum ranks for ties |
| `rdr_u`, `rdr_v` | Wind components at radar level, labelled m/s |
| `rdr_blh` | Boundary layer height at radar level, labelled metres |
| `fl_inst_lsrr` | En-route precipitation; multiplied by 3600 for the plotted mm/hour values |
| `stp_t2m_168hrs_sum` | Stopover temperature accumulation; divided by 168 and reduced by 273.15 for a plotted seven-day average in °C |
| `yday`, `solar_*` | Day-of-year and solar predictors, grouped as phenology |
| `nr_birds` | Simulated migrant count, grouped at radar level |
| `rdr_*`, `fl_*`, `stp_*` | Predictor prefixes grouped as radar-level, en-route, and stopover |

Environmental categories are defined by `classify_var_envir()` in the notebook.
Grouped SHAP values sum contributions before averaging; height is excluded from
the displayed importance and environmental summaries.
