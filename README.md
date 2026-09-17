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

Run commands from the repository root. Install R 4.5.0 and Quarto 1.6.42,
the versions used for validation. Restore the R packages pinned in
[renv.lock](renv.lock) (internet access is required):

```sh
Rscript -e 'renv::restore(prompt = FALSE)'
```

The project `.Rprofile` bootstraps `renv` and activates an isolated package
library. R and Quarto must be installed separately; some R packages may also
require system libraries or compilers. A complete clean restore has not yet
been verified. Only run `renv::snapshot()` after deliberately changing and
validating the project library.

For a Git clone, install Git LFS and retrieve the actual binary files:

```sh
git lfs install
git lfs pull
```

Place the 16 existing `sv_spring_2017.RDS` through `sv_spring_2024.RDS` and
`sv_autumn_2017.RDS` through `sv_autumn_2024.RDS` files in `data/processed/`.
These files are currently ignored by Git and must accompany the archival data
package. Verify these inputs with `sha256sum -c processed-data.sha256`.
A clone alone is therefore not yet sufficient to reproduce the figures.
The notebook stops if any required file is absent; it never trains models or
regenerates processed data.

```sh
quarto render explaining-migration-peaks.qmd
```

Rendering writes a self-contained HTML document and overwrites the 20 figure files in `plots/`.
To preserve reference figures, render a copy of the project with its own `plots/`
directory. The notebook needs substantial RAM: it loads all 16 SHAP files and
expands their contributions into long tables. See [VALIDATION.md](VALIDATION.md)
for the tested run and comparison with committed figures.

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
| `data/README.md` | Data structure, row alignment, and provenance gaps |
| `renv.lock` | Pinned R package versions and installation sources |
| `.Rprofile`, `renv/` | Project-library activation, renv bootstrap, and settings |
| `processed-data.sha256` | SHA-256 checksums of the 16 required processed inputs |

The stability panels compare eight models, each trained without one year. Each
model's SHAP file explains **all** input rows, not just its held-out year.
Predictor ranks, wind, and non-wind effects use the model trained without 2017.
The nightly heatmaps average all eight models. They are therefore not exclusively
out-of-sample explanations. SHAP contributions describe model predictions;
they do not establish causal environmental effects.

The earlier combined `shap_stability` layout is retained alongside the separate
spring/autumn panels. Exploratory plots and unused calculations have been removed
from the notebook; they remain available in Git history. Existing untracked files
and older processed snapshots are not part of the figure workflow.

## Optional preprocessing

`R/prepare_shap.R` preserves the original model/SHAP generation workflow separately
from plotting. It requires LightGBM and its mlr3 learner integration in addition to
the plotting dependencies. It has not been run end to end during this cleanup.
An explicit opt-in is required because it is slow and overwrites yearly SHAP files:

```sh
REBUILD_SHAP=true Rscript R/prepare_shap.R
```

For exact figure reproduction, use the archived processed files.

## License

Copyright (c) 2025 Bart Hoekstra.

This project is licensed under the [GNU General Public License v3.0](LICENSE).
