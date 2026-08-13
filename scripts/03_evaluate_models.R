source("config/model_config.R")
source("R/preprocessing.R")
source("R/metrics.R")
source("R/modeling.R")
source("R/reporting.R")

student_data <- read.csv(
  "data/synthetic_student_success.csv",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
student_data$grade_band <- factor(
  student_data$grade_band,
  levels = c("K-2", "3-5", "6-8", "9-12")
)

bundle <- readRDS("artifacts/model_bundle.rds")
test_data <- temporal_split(student_data)$test
probability <- predict_bundle(bundle, test_data)

test_metrics <- probability_metrics(
  test_data$chronic_absence,
  probability,
  bundle$threshold
)
test_metrics <- data.frame(
  model = bundle$selected_model,
  split = "2025-26 temporal holdout",
  t(test_metrics),
  expected_calibration_error = expected_calibration_error(
    test_data$chronic_absence,
    probability
  ),
  row.names = NULL,
  check.names = FALSE
)

subgroups <- all_subgroup_metrics(
  test_data,
  probability,
  bundle$threshold
)
thresholds <- threshold_analysis(test_data$chronic_absence, probability)

write.csv(test_metrics, "outputs/test_metrics.csv", row.names = FALSE)
write.csv(subgroups, "outputs/subgroup_metrics.csv", row.names = FALSE)
write.csv(thresholds, "outputs/threshold_analysis.csv", row.names = FALSE)

cat(sprintf(
  "Test ROC AUC: %.3f | PR AUC: %.3f | Brier: %.3f\n",
  test_metrics$roc_auc,
  test_metrics$pr_auc,
  test_metrics$brier_score
))
