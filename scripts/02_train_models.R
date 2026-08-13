source("config/model_config.R")
source("R/preprocessing.R")
source("R/metrics.R")
source("R/modeling.R")

dir.create("artifacts", showWarnings = FALSE, recursive = TRUE)
dir.create("outputs", showWarnings = FALSE, recursive = TRUE)

student_data <- read.csv(
  "data/synthetic_student_success.csv",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
student_data$grade_band <- factor(
  student_data$grade_band,
  levels = c("K-2", "3-5", "6-8", "9-12")
)

splits <- temporal_split(student_data)
bundle <- make_model_bundle(
  splits$train,
  splits$validation,
  model_config$intervention_capacity_rate
)

saveRDS(bundle, "artifacts/model_bundle.rds")
write.csv(
  bundle$validation_comparison,
  "outputs/validation_model_comparison.csv",
  row.names = FALSE
)

cat(sprintf("Selected model: %s\n", bundle$selected_model))
cat(sprintf("Validation threshold: %.4f\n", bundle$threshold))
