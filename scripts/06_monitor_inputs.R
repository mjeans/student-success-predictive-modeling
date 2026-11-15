source("R/preprocessing.R")
source("R/modeling.R")

data <- read.csv("data/synthetic_student_success.csv", stringsAsFactors = FALSE)
bundle <- readRDS("artifacts/model_bundle.rds")
current <- temporal_split(data)$test
reference <- bundle$preprocessor$monitoring_reference
if (is.null(reference)) stop("Rebuild the training bundle to create its monitoring reference.")
monitor <- monitor_scoring_inputs(current, reference)
write.csv(monitor$numeric, "outputs/input-drift.csv", row.names = FALSE, na = "")
write.csv(monitor$grades, "outputs/grade-drift.csv", row.names = FALSE, na = "")

stress <- current
stress$lms_days_active[seq_len(floor(nrow(stress) * .5))] <- NA_real_
stress_report <- monitor_scoring_inputs(stress, reference)
bad_units <- current
bad_units$first_30d_attendance_rate <- 100 * bad_units$first_30d_attendance_rate
unit_error <- tryCatch({ validate_scoring_inputs(bad_units); "not_blocked" }, error = function(e) "blocked")
stopifnot(unit_error == "blocked", stress_report$disposition == "human_review")

md_table <- function(x) {
  formatted <- lapply(x, function(v) if (is.numeric(v)) format(round(v, 3), trim = TRUE) else v)
  c(paste0("| ", paste(names(x), collapse = " | "), " |"),
    paste0("|", paste(rep("---", ncol(x)), collapse = "|"), "|"),
    apply(as.data.frame(formatted), 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
}
report <- c("# Scoring-input monitoring: executed synthetic example", "",
  "The reference is fitted on 2023-24 training data only. These checks inspect new inputs before outcome labels are available; they do not establish continued model accuracy.", "",
  paste0("**2025-26 input disposition:** `", monitor$disposition, "`."), "",
  "The illustrative thresholds flag an absolute mean shift above 0.5 training SD, missingness increasing by more than 10 percentage points, or a grade share changing by more than 10 percentage points. These are review triggers, not validated universal cutoffs.", "",
  md_table(monitor$numeric[c("feature", "current_observed", "standardized_mean_shift", "current_missing_rate", "status", "reasons")]), "",
  md_table(monitor$grades), "", "## Controlled failure drills", "",
  "| Scenario | Observed response |", "|---|---|",
  paste0("| Attendance sent as 95 instead of 0.95 | ", unit_error, " before scoring |"),
  paste0("| Half the LMS values removed | ", stress_report$disposition, " |"), "",
  "The drills change copies of synthetic inputs only. They do not retrain the model, change the validation threshold, alter test outcomes, or regenerate the dashboard graphics.", "",
  "## Operational response", "",
  "A schema/range failure blocks scoring; correct the upstream extract and rerun. A drift alert calls for source and population review, not automatic retraining. Hold any outreach release until a responsible team reviews material alerts. Later, when outcome labels mature, assess discrimination, calibration, subgroup error and workload separately. A passed input check is not deployment approval.", "",
  "[Monitoring policy](../docs/input-monitoring.md) · [Model card](../docs/model-card.md)")
writeLines(report, "outputs/input-monitoring-report.md", useBytes = TRUE)
cat("Published input monitoring and controlled failure drills.\n")
