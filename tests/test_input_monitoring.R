source("R/data_generation.R")
source("R/preprocessing.R")
source("R/metrics.R")
source("R/modeling.R")
expect_error <- function(expr) stopifnot(inherits(try(force(expr), silent = TRUE), "try-error"))
d <- generate_student_success_data(250L)
s <- temporal_split(d)
p <- fit_preprocessor(s$train)
stopifnot(monitor_scoring_inputs(s$train, p$monitoring_reference)$disposition == "within_monitoring_thresholds")

bad <- s$test; bad$prior_attendance_rate <- 95; expect_error(apply_preprocessor(bad, p))
bad <- s$test; bad$baseline_score <- as.character(bad$baseline_score); expect_error(apply_preprocessor(bad, p))
bad <- s$test; bad$grade_band <- "new"; expect_error(apply_preprocessor(bad, p))
bad <- s$test; bad$lms_days_active <- NULL; expect_error(apply_preprocessor(bad, p))
bad <- s$test; bad$support_contacts[1] <- Inf; expect_error(apply_preprocessor(bad, p))
bad <- s$test; bad$mobility_event[1] <- .5; expect_error(apply_preprocessor(bad, p))
bad <- s$train; bad$baseline_score <- NA_real_; expect_error(fit_preprocessor(bad))
expect_error(apply_preprocessor(s$test[0, ], p))

bad <- s$test; bad$lms_days_active <- NA_real_
m <- monitor_scoring_inputs(bad, p$monitoring_reference)
stopifnot(m$disposition == "human_review", grepl("all_missing", m$numeric$reasons[m$numeric$feature == "lms_days_active"]))
stopifnot(all(is.finite(apply_preprocessor(bad, p)$lms_days_active)))
stopifnot(identical(p, fit_preprocessor(s$train)))

constant <- s$train; constant$support_contacts <- 1
ref <- fit_monitoring_reference(constant)
current <- constant; current$support_contacts <- 2
m <- monitor_scoring_inputs(current, ref)
stopifnot(m$numeric$reasons[m$numeric$feature == "support_contacts"] == "constant_reference_changed")
expect_error(monitor_scoring_inputs(current, ref, missing_increase_limit = -1))

# Valid-input predictions remain invariant to the presence or absence of audit/outcome columns.
set.seed(20260813)
bundle <- make_model_bundle(s$train, s$validation)
full <- predict_bundle(bundle, s$test)
only_features <- s$test[c(model_numeric_features, model_categorical_features)]
stopifnot(isTRUE(all.equal(full, predict_bundle(bundle, only_features))))
cat("All input-contract, drift, and predictor-boundary checks passed.\n")
