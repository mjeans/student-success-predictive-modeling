source("config/model_config.R")
source("R/data_generation.R")
source("R/preprocessing.R")
source("R/metrics.R")
source("R/modeling.R")
source("R/reporting.R")

data_one <- generate_student_success_data(250L)
data_two <- generate_student_success_data(250L)

stopifnot(identical(data_one, data_two))
stopifnot(nrow(data_one) == 750L)
stopifnot(length(unique(data_one$academic_year)) == 3L)
stopifnot(all(data_one$chronic_absence %in% c(0L, 1L)))
stopifnot(all(
  data_one$first_30d_attendance_rate >= 0.45 &
    data_one$first_30d_attendance_rate <= 1
))

splits <- temporal_split(data_one)
stopifnot(nrow(splits$train) == 250L)
stopifnot(nrow(splits$validation) == 250L)
stopifnot(nrow(splits$test) == 250L)
stopifnot(length(intersect(splits$train$student_id, splits$test$student_id)) == 0L)

bundle <- make_model_bundle(splits$train, splits$validation, 0.15)
probability <- predict_bundle(bundle, splits$test)

stopifnot(length(probability) == nrow(splits$test))
stopifnot(all(is.finite(probability)))
stopifnot(all(probability >= 0 & probability <= 1))
stopifnot(bundle$selected_model %in% c("logistic_regression", "decision_tree"))
stopifnot(bundle$threshold > 0 && bundle$threshold < 1)

metrics <- probability_metrics(
  splits$test$chronic_absence,
  probability,
  bundle$threshold
)
stopifnot(metrics[["roc_auc"]] >= 0.5)
stopifnot(metrics[["brier_score"]] >= 0 && metrics[["brier_score"]] <= 1)

stopifnot(!any(audit_features %in% bundle$feature_policy$predictors))

cat("All predictive-modeling pipeline checks passed.\n")
