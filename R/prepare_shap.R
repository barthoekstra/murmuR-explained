if (!identical(Sys.getenv("REBUILD_SHAP"), "true")) {
  stop("Long-running preprocessing is opt-in: set REBUILD_SHAP=true to run this script.")
}

dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

library(tidyverse)
library(mlr3verse)
library(mlr3db)
library(tictoc)
library(shapviz)
source("R/functions_training.R")
train_model <- function(radar, season, year_held_out = NULL) {
  task <- create_task(radar, season = season)
  
  selected_features_file <- sprintf("data/raw/model_features/fs_selected_top_features_%s_%s_dynamic.RDS", radar, season)
  train_features <- readRDS(selected_features_file)
  task$select(train_features)
  
  learner <- lrn("regr.lightgbm", 
                 objective = "tweedie",
                 verbose = 2,
                 num_threads = 10)
  best_params <- readRDS(sprintf("data/raw/model_params/fs_twdie_%s_%s_dynamic_regr.rmse_best_params_regr.rmse.RDS", radar,
                                 season))
  best_params$num_threads <- parallel::detectCores()-1
  learner$param_set$values <- best_params
  
  if (!is.null(year_held_out)) {
    tic(paste0("Training model for ", radar, " ", season, " ", year_held_out))
    row_ids <- which(task$groups$group != year_held_out)
    learner$train(task, row_ids = row_ids)
    toc()
    return(list(learner = learner, task = task, year_held_out = year_held_out, 
                row_ids = row_ids))
  } else {
    tic(paste0("Training model for ", radar, " ", season))
    learner$train(task)
    toc()
    return(list(learner = learner, task = task))
  }
}
additional_cols <- c("year", "datetime", "period_rank_mtr", "night_num", "mt")
selected_features_autumn <- sprintf("data/raw/model_features/fs_selected_top_features_%s_%s_dynamic.RDS", "nlhrw", "autumn")
selected_features_spring <- sprintf("data/raw/model_features/fs_selected_top_features_%s_%s_dynamic.RDS", "nlhrw", "spring")
train_features_autumn <- readRDS(selected_features_autumn)
train_features_spring <- readRDS(selected_features_spring)

data_autumn <- create_task("nlhrw", "autumn")$data(cols = c(train_features_autumn, additional_cols)) %>%
  mutate(row_id = row_number())

data_spring <- create_task("nlhrw", "spring")$data(cols = c(train_features_spring, additional_cols)) %>%
      mutate(row_id = row_number())

for (year_held_out in 2017:2024) {
    print(paste0("Year held out: ", year_held_out))
    
    tic("Calculating autumn SHAP values")
    model_autumn <- train_model("nlhrw", "autumn", year_held_out = year_held_out)
    sv_autumn <- shapviz(model_autumn$learner$model, 
                         data_autumn %>% select(all_of(model_autumn$task$feature_names)) %>% as.matrix())
    toc()
    saveRDS(sv_autumn, file = paste0("data/processed/sv_autumn_", year_held_out, ".RDS"))
    
    tic("Calculating spring SHAP values")
    model_spring <- train_model("nlhrw", "spring", year_held_out = year_held_out)
    sv_spring <- shapviz(model_spring$learner$model, 
                         data_spring %>% select(all_of(model_spring$task$feature_names)) %>% as.matrix())
    toc()
    saveRDS(sv_spring, file = paste0("data/processed/sv_spring_", year_held_out, ".RDS"))
}
