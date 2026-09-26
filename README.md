<a href="https://doi.org/10.5281/zenodo.22972199"><img src="https://zenodo.org/badge/DOI/10.5281/zenodo.22972199.svg" alt="DOI"></a>

# murmuR-explained - Explaining bird migration peaks

Code and data for explaining migration peaks with SHAP values from seasonal
migration models. The figure workflow uses Herwijnen (`nlhrw`) observations from
2017–2024. Model inputs for Den Helder (`nldhl`) are also retained in the repository,
but are not used by these figures.

## Source data and processing

The source data and processing workflows underlying this analysis are documented
in the following repositories:

- [murmuR-paper](https://github.com/barthoekstra/murmuR-paper): analysis and figure
  scripts accompanying the paper. Zenodo DOI:
  [10.5281/zenodo.19823028](https://doi.org/10.5281/zenodo.19823028).
- [murmuR](https://github.com/barthoekstra/murmuR): the R package implementing the
  migration simulation, data processing, and modelling pipeline. Zenodo DOI:
  [10.5281/zenodo.19823042](https://doi.org/10.5281/zenodo.19823042).

## Reproduce the figures

Install Git LFS, R 4.5.0, and Quarto 1.6.42. Clone the repository and retrieve
the binary data and figures:

```sh
git lfs install
git clone https://github.com/barthoekstra/murmuR-explained.git
cd murmuR-explained
git lfs pull
```

For an existing clone, run `git lfs pull` from its repository root. All remaining
commands run from that root, regardless of the local folder name. You can also
open `murmuR-explained.Rproj` in RStudio.

Restore the R packages pinned in [renv.lock](renv.lock) (internet access is required):

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
```

The project `.Rprofile` bootstraps `renv` and activates an isolated package
library. R and Quarto must be installed separately; some R packages may also
require system libraries or compilers. A complete clean restore has not yet
been verified. Only run `renv::snapshot()` after deliberately changing and
validating the project library.

The repository includes all model inputs and the 16 yearly SHAP files needed
for the figures. The notebook reads these files from `data/`, checks that SHAP
rows match the model inputs, and renders the figures without retraining models:

```sh
quarto render explaining-migration-peaks.qmd
```

Rendering writes a self-contained HTML document and overwrites the 20 figure files in `plots/`.
To preserve reference figures, render a copy of the project with its own `plots/`
directory. The notebook needs substantial RAM: it loads all 16 SHAP files and
expands their contributions into long tables. The committed PNG and PDF files
in `plots/` can be viewed without running the notebook.

## Contents and interpretation

| Path | Contents |
| --- | --- |
| `explaining-migration-peaks.qmd` | Figure workflow and brief methods |
| `R/functions_training.R` | Reads Parquet inputs and constructs model tasks |
| `R/prepare_shap.R` | Optional, expensive model training and SHAP generation |
| `data/raw/model_data/{radar}/` | Year/season Parquet model inputs; these are analysis inputs, not original radar measurements |
| `data/raw/model_features/` | Selected predictor names in RDS format |
| `data/raw/model_params/` | Tuned model parameter lists in RDS format |
| `data/processed/sv_{season}_{year}.RDS` | Existing yearly `shapviz` objects required for plotting |
| `plots/` | Ten figure pairs, each in PNG and PDF format |
| `data/README.md` | Data coverage, object structure, row alignment, and field descriptions |
| `renv.lock` | Pinned R package versions and installation sources |
| `.Rprofile`, `renv/` | Project-library activation, renv bootstrap, and settings |
| `murmuR-explained.Rproj` | RStudio project settings |
| `.gitattributes`, `.gitignore` | Git LFS rules and exclusions for generated files |
| `LICENSE` | GNU GPL v3 license text |

The stability panels compare eight models, each trained without one year. Each
model's SHAP file explains **all** input rows, not just its held-out year.
Predictor ranks, wind, and non-wind effects use the model trained without 2017.
The nightly heatmaps average all eight models. They are therefore not exclusively
out-of-sample explanations. SHAP contributions describe model predictions;
they do not establish causal environmental effects.

## Included figures

Each name below has both a `.png` and a `.pdf` file in `plots/`.

| Figure name | Contents |
| --- | --- |
| `shap_stability_spring`, `shap_stability_autumn` | Predictor importance across the eight models for each season |
| `shap_stability` | Spring and autumn stability panels combined |
| `predictor_ranks` | Predictor importance ranks overall, on peak nights (ranks 1–10), and on low-traffic nights (ranks greater than 111) |
| `shap_wind` | Joint SHAP contributions of radar-level wind components and their distributions |
| `shap_nonwind` | SHAP contributions for boundary layer height, en-route precipitation, and stopover temperature |
| `mt_shap_ranked`, `mt_shap_chronological` | Nightly migration traffic and SHAP contributions by environment and location, in ranked or calendar order |
| `mt_shap_envirs_ranked`, `mt_shap_envirs_chronological` | Nightly migration traffic and SHAP contributions grouped by environment, in ranked or calendar order |

## Optional preprocessing

`R/prepare_shap.R` trains the Herwijnen seasonal models and generates the 16
yearly SHAP files using the included model inputs, selected predictors, and tuned
parameters. It requires LightGBM and its mlr3 learner integration, which are
included in `renv.lock`. This optional workflow has not been verified end to end.
An explicit opt-in is required because it is slow and overwrites yearly SHAP files:

```sh
REBUILD_SHAP=true Rscript R/prepare_shap.R
```

To reproduce the figures, use the committed processed files in `data/processed/`.

## License

Copyright (c) 2025 Bart Hoekstra.

This project is licensed under the [GNU General Public License v3.0](LICENSE).
