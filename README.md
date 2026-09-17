# Explaining migration peaks

Code and data for explaining migration peaks with SHAP values from seasonal
migration models. The figure workflow uses Herwijnen (`nlhrw`) observations from
2017–2024. Model inputs for Den Helder (`nldhl`) are also retained in the repository,
but are not used by these figures.

## Reproduce the figures

Run commands from the repository root. R 4.5.0 was used for validation; exact
Quarto 1.6.42 was used for rendering. Installed package versions, including dependencies, are in
[software-versions.csv](software-versions.csv). This inventory is not an automated
lockfile. Quarto and the packages below must be installed before rendering:

```r
install.packages(c(
  "data.table", "tidyverse", "mlr3verse", "mlr3db", "tictoc", "duckdb",
  "patchwork", "shapviz", "khroma", "ggh4x", "ggside", "tidytext",
  "ggstats", "knitr", "rmarkdown"
))
```

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
| `software-versions.csv` | Installed R package versions used during validation |
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

For exact figure reproduction, use the archived processed files. Re-running
training with different software, threading, or random state has not been shown
to reproduce those files exactly.

## Preparing a Zenodo release

The project is not yet a complete FAIR deposit. Before release:

- Include actual Parquet/RDS/figure contents, not Git LFS pointers, and explicitly
  include the 16 ignored yearly SHAP files. Exclude `.git/`, session histories,
  temporary outputs, and the four unused older SHAP snapshots.
- Complete the data dictionary and upstream provenance described in
  [data/README.md](data/README.md), including source dataset identifiers, processing
  versions, units, time conventions, and missing-value meanings.
- Confirm data redistribution rights and specify the data license. The existing
  [MIT license](LICENSE) covers the software; it does not document upstream data
  permissions. Zenodo supports describing files with different licenses.
- Add release metadata: agreed title, creators and ORCIDs, affiliations, description,
  keywords, version, related paper/data identifiers, and funding. Reserve the DOI
  and add it to citation metadata such as `CITATION.cff` before publication.
- Create a dependency lockfile and test restoration in a clean environment. Retain
  the tested software inventory and figure comparison report with the release.
- Include SHA-256 checksums of deposited files. Test reproduction from an extracted
  release package, without access to local caches or untracked files.

These steps support findability, accessibility, interoperability and reuse through
persistent identifiers, rich metadata, documented formats, licensing and provenance;
see the [GO FAIR principles](https://www.go-fair.org/fair-principles/) and
[Zenodo licensing guidance](https://help.zenodo.org/docs/deposit/describe-records/licenses/).
No deposit has been created or published by this cleanup.
