model_numeric_features <- c(
  "baseline_score",
  "prior_attendance_rate",
  "first_30d_attendance_rate",
  "lms_days_active",
  "assignments_completed_rate",
  "support_contacts",
  "mobility_event",
  "prior_behavior_incidents"
)

model_categorical_features <- c("grade_band")

audit_features <- c(
  "gender",
  "race_ethnicity",
  "economically_disadvantaged",
  "multilingual_learner",
  "disability_status"
)

source("R/input_monitoring.R")

fit_preprocessor <- function(training_data) {
  validate_scoring_inputs(training_data)
  medians <- vapply(
    training_data[model_numeric_features],
    median,
    numeric(1),
    na.rm = TRUE
  )

  if (any(!is.finite(medians))) stop("A training predictor has no finite median; review its source.")
  list(
    medians = medians,
    grade_levels = c("K-2", "3-5", "6-8", "9-12"),
    monitoring_reference = fit_monitoring_reference(training_data)
  )
}

apply_preprocessor <- function(data, preprocessor) {
  validate_scoring_inputs(data)
  prepared <- data

  for (feature in model_numeric_features) {
    missing <- is.na(prepared[[feature]])
    prepared[[paste0(feature, "_missing")]] <- as.integer(missing)
    prepared[[feature]][missing] <- preprocessor$medians[[feature]]
  }

  prepared$grade_band <- factor(
    prepared$grade_band,
    levels = preprocessor$grade_levels
  )

  if (anyNA(prepared$grade_band)) {
    stop("Scoring data contain an unseen grade_band level.")
  }

  prepared
}

temporal_split <- function(data) {
  list(
    train = data[data$academic_year == "2023-24", , drop = FALSE],
    validation = data[data$academic_year == "2024-25", , drop = FALSE],
    test = data[data$academic_year == "2025-26", , drop = FALSE]
  )
}
