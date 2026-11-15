# Fail on invalid representation; distinguish absent data from valid zero values.
validate_scoring_inputs <- function(data) {
  required <- c(model_numeric_features, model_categorical_features)
  absent <- setdiff(required, names(data))
  if (length(absent)) stop("Missing scoring fields: ", paste(absent, collapse = ", "))
  if (!nrow(data)) stop("Scoring data contain no rows.")
  ranges <- list(baseline_score = c(0, 100), prior_attendance_rate = c(0, 1),
                 first_30d_attendance_rate = c(0, 1), lms_days_active = c(0, 30),
                 assignments_completed_rate = c(0, 1), support_contacts = c(0, Inf),
                 mobility_event = c(0, 1), prior_behavior_incidents = c(0, Inf))
  integer_fields <- c("lms_days_active", "support_contacts", "mobility_event", "prior_behavior_incidents")
  for (field in model_numeric_features) {
    x <- data[[field]]
    if (!is.numeric(x)) stop("Expected numeric scoring field: ", field)
    known <- !is.na(x)
    bounds <- ranges[[field]]
    if (any(!is.finite(x[known])) || any(x[known] < bounds[1] | x[known] > bounds[2])) {
      stop("Out-of-range scoring field: ", field, ". Check units and source coding.")
    }
    if (field %in% integer_fields && any(x[known] != floor(x[known]))) stop("Expected whole counts: ", field)
  }
  if (anyNA(data$grade_band) || any(!as.character(data$grade_band) %in% c("K-2", "3-5", "6-8", "9-12"))) {
    stop("Invalid or missing grade_band; do not silently impute a new category.")
  }
  invisible(TRUE)
}

fit_monitoring_reference <- function(training_data) {
  validate_scoring_inputs(training_data)
  stats <- do.call(rbind, lapply(model_numeric_features, function(field) {
    x <- training_data[[field]]
    if (sum(!is.na(x)) < 2L) stop("Insufficient observed training values for: ", field)
    data.frame(feature = field, mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE),
               missing_rate = mean(is.na(x)), stringsAsFactors = FALSE)
  }))
  list(n = nrow(training_data), numeric = stats,
       grades = prop.table(table(factor(training_data$grade_band, levels = c("K-2", "3-5", "6-8", "9-12")))))
}

monitor_scoring_inputs <- function(data, reference, mean_shift_limit = 0.5,
                                   missing_increase_limit = 0.10, grade_shift_limit = 0.10) {
  validate_scoring_inputs(data)
  if (!is.finite(mean_shift_limit) || mean_shift_limit <= 0 ||
      !is.finite(missing_increase_limit) || missing_increase_limit < 0 || missing_increase_limit > 1 ||
      !is.finite(grade_shift_limit) || grade_shift_limit < 0 || grade_shift_limit > 1) stop("Invalid monitoring thresholds")
  rows <- lapply(seq_len(nrow(reference$numeric)), function(i) {
    r <- reference$numeric[i, ]
    x <- data[[r$feature]]
    observed <- x[!is.na(x)]
    current_mean <- if (length(observed)) mean(observed) else NA_real_
    change <- mean(is.na(x)) - r$missing_rate
    shift <- if (!length(observed)) NA_real_ else if (r$sd > 0) (current_mean - r$mean) / r$sd else
      if (current_mean == r$mean) 0 else NA_real_
    reasons <- character()
    if (!length(observed)) reasons <- c(reasons, "all_missing")
    if (length(observed) && r$sd == 0 && current_mean != r$mean) reasons <- c(reasons, "constant_reference_changed")
    if (is.finite(shift) && abs(shift) > mean_shift_limit) reasons <- c(reasons, "mean_shift")
    if (change > missing_increase_limit) reasons <- c(reasons, "missingness_increase")
    data.frame(feature = r$feature, current_n = length(x), current_observed = length(observed),
               reference_mean = r$mean, current_mean = current_mean, standardized_mean_shift = shift,
               reference_missing_rate = r$missing_rate, current_missing_rate = mean(is.na(x)),
               status = if (length(reasons)) "review" else "within_thresholds",
               reasons = paste(reasons, collapse = ";"), stringsAsFactors = FALSE)
  })
  grade_current <- prop.table(table(factor(data$grade_band, levels = names(reference$grades))))
  grades <- data.frame(grade = names(reference$grades), reference_share = as.numeric(reference$grades),
                       current_share = as.numeric(grade_current), stringsAsFactors = FALSE)
  grades$absolute_change <- abs(grades$current_share - grades$reference_share)
  grades$status <- ifelse(grades$absolute_change > grade_shift_limit, "review", "within_thresholds")
  numeric <- do.call(rbind, rows)
  list(numeric = numeric, grades = grades,
       disposition = if (any(numeric$status == "review") || any(grades$status == "review")) "human_review" else "within_monitoring_thresholds")
}
