create_task <- function(radar, season, sampling = "dynamic", dataset = "hourly") {
  # Load parquet files
  usesims <- if (sampling %in% c("static_stopover", "static_stopover_enroute")) "_nosims" else ""
  basepath <- paste0("data/raw/model_data/", radar, "/", radar, "_*_", season, usesims, "_3km")
  if (dataset == "hourly") {
    parquet_files <- Sys.glob(paste0(basepath, "_noninterpolated.parquet"))
  } else {
    parquet_files <- Sys.glob(paste0(basepath, ".parquet"))
  }

  # Prepare data backend
  tictoc::tic("Preparing data backend")
  duckdb_reconnector = function(parquet_files) {
    force(parquet_files)
    function() {
      con <- DBI::dbConnect(duckdb::duckdb())
      query <- "CREATE OR REPLACE VIEW 'mlr3db_view' AS SELECT *, row_number() OVER () AS mlr3_row_id"
      query <- sprintf("%s FROM parquet_scan(['%s'])", query, paste0(parquet_files, collapse = "','"))
      DBI::dbExecute(con, query)
      return(con)
    }
  }
  data_backend <- as_duckdb_backend(parquet_files)
  data_backend$connector <- duckdb_reconnector(parquet_files)

  # Prepare task
  task_id <- paste0("migpred_", sampling)
  task <- as_task_regr(data_backend,
                       target = "dens",
                       id = task_id,
                       label = paste0("Migration Prediction (", sampling, " sampling)"))
  tictoc::toc()

  # Set year column to grouping variable for cross-validation
  # i.e. cross-validation always takes a full year as a fold
  task$set_col_roles(cols = c("year"), roles = c("group"))

  non_prediction_features <- c("datetime", "tidx", "tidx_orig",
                               "vid", "mt", "mtr",
                               "period_mtr", "period_rank_mtr", "prop_mtr",
                               "period_vid", "period_rank_vid", "prop_vid",
                               "day_num", "night_num", "interpolated")

  phenology_features <- c("yday", "solar_elev", "solar_elevation_change",
                          "solar_azim", "height")
  dropped_features <- c("rdr_wa_distance_to_opt", "rdr_wind_assist", "rdr_theta",
                        "rdr_wind_dir", "rdr_wind_speed", "rdr_wind_to", "rdr_opt_alt",
                        "fl_inst_gh", "fl_inst_z")

  if (sampling %in% c("dynamic", "static_stopover_enroute")) {
    train_features <- setdiff(task$feature_names, c(non_prediction_features, dropped_features))
  } else if (sampling == "static_stopover") {
    train_features <- task$feature_names[str_starts(task$feature_names, "rdr_") |
                                           str_starts(task$feature_names, "stp_")]
    train_features <- setdiff(train_features, dropped_features)
    train_features <- c(phenology_features, train_features)
  } else {
    train_features <- task$feature_names[str_starts(task$feature_names, "rdr_")]
    train_features <- setdiff(train_features, dropped_features)
    train_features <- c(phenology_features, train_features)
  }

  task$select(train_features)

  print("Initial selected features:")
  print(task$feature_names)

  return(task)
}