deterministic_uniform <- function(index, salt) {
  x <- sin(index * 12.9898 + salt * 78.233) * 43758.5453
  x - floor(x)
}

clamp <- function(x, lower, upper) {
  pmin(pmax(x, lower), upper)
}

generate_student_success_data <- function(n_per_year = 2000L) {
  years <- c("2023-24", "2024-25", "2025-26")
  n <- length(years) * n_per_year
  index <- seq_len(n)
  academic_year <- rep(years, each = n_per_year)
  school_number <- ((index * 17L) %% 30L) + 1L

  grade_levels <- c("K-2", "3-5", "6-8", "9-12")
  race_levels <- c("Asian", "Black", "Hispanic", "White", "Multiracial")
  grade_band <- grade_levels[floor(deterministic_uniform(index, 1) * 4) + 1L]
  race_ethnicity <- race_levels[floor(deterministic_uniform(index, 2) * 5) + 1L]

  gender_draw <- deterministic_uniform(index, 3)
  gender <- ifelse(
    gender_draw < 0.49, "Female",
    ifelse(gender_draw < 0.98, "Male", "Nonbinary")
  )

  economically_disadvantaged <- as.integer(
    deterministic_uniform(index, 4) < (0.42 + 0.10 * (school_number %% 5L == 0L))
  )
  multilingual_learner <- as.integer(
    deterministic_uniform(index, 5) <
      (0.18 + 0.08 * (race_ethnicity %in% c("Hispanic", "Asian")))
  )
  disability_status <- as.integer(deterministic_uniform(index, 6) < 0.14)
  mobility_event <- as.integer(
    deterministic_uniform(index, 7) < (0.08 + 0.06 * economically_disadvantaged)
  )

  safe_qnorm <- function(x) qnorm(clamp(x, 1e-6, 1 - 1e-6))

  baseline_score <- clamp(
    68 + 14 * safe_qnorm(deterministic_uniform(index, 8)) -
      5 * economically_disadvantaged - 4 * disability_status,
    20, 100
  )
  prior_attendance_rate <- clamp(
    0.93 - 0.07 * economically_disadvantaged - 0.06 * mobility_event -
      0.035 * disability_status +
      0.035 * safe_qnorm(deterministic_uniform(index, 9)) +
      0.008 * ((school_number %% 6L) - 2.5),
    0.55, 0.995
  )
  first_30d_attendance_rate <- clamp(
    prior_attendance_rate - 0.025 * mobility_event -
      0.012 * (academic_year == "2025-26") +
      0.025 * safe_qnorm(deterministic_uniform(index, 10)),
    0.45, 1
  )
  lms_days_active <- clamp(
    round(
      19 + 9 * (first_30d_attendance_rate - 0.80) +
        3 * safe_qnorm(deterministic_uniform(index, 11)) -
        2 * multilingual_learner
    ),
    0, 30
  )
  assignments_completed_rate <- clamp(
    0.90 - 0.28 * (1 - first_30d_attendance_rate) -
      0.08 * mobility_event - 0.04 * multilingual_learner +
      0.06 * safe_qnorm(deterministic_uniform(index, 12)),
    0.20, 1
  )
  support_contacts <- floor(
    5 * deterministic_uniform(index, 13) +
      2 * mobility_event + economically_disadvantaged
  )
  prior_behavior_incidents <- floor(
    4 * deterministic_uniform(index, 14) +
      2 * ((1 - first_30d_attendance_rate) > 0.12)
  )

  outcome_logit <- -3.55 +
    5.8 * (1 - prior_attendance_rate) +
    7.2 * (1 - first_30d_attendance_rate) +
    1.0 * mobility_event +
    0.45 * disability_status +
    0.35 * economically_disadvantaged +
    0.12 * prior_behavior_incidents -
    0.018 * (baseline_score - 65) -
    0.025 * (lms_days_active - 15) -
    0.9 * (assignments_completed_rate - 0.75) +
    0.15 * (academic_year == "2025-26") +
    0.18 * (school_number %% 7L == 0L)

  chronic_absence_probability <- plogis(outcome_logit)
  chronic_absence <- as.integer(
    deterministic_uniform(index, 15) < chronic_absence_probability
  )

  baseline_score[deterministic_uniform(index, 16) < 0.035] <- NA_real_
  prior_attendance_rate[deterministic_uniform(index, 17) < 0.025] <- NA_real_
  lms_days_active[deterministic_uniform(index, 18) < 0.040] <- NA_real_
  assignments_completed_rate[deterministic_uniform(index, 19) < 0.030] <- NA_real_

  data.frame(
    student_id = sprintf("STU-%05d", index),
    academic_year = academic_year,
    school_id = sprintf("SCH-%02d", school_number),
    grade_band = factor(grade_band, levels = grade_levels),
    baseline_score = round(baseline_score, 2),
    prior_attendance_rate = round(prior_attendance_rate, 4),
    first_30d_attendance_rate = round(first_30d_attendance_rate, 4),
    lms_days_active = lms_days_active,
    assignments_completed_rate = round(assignments_completed_rate, 4),
    support_contacts = as.integer(support_contacts),
    mobility_event = mobility_event,
    prior_behavior_incidents = as.integer(prior_behavior_incidents),
    gender = gender,
    race_ethnicity = race_ethnicity,
    economically_disadvantaged = economically_disadvantaged,
    multilingual_learner = multilingual_learner,
    disability_status = disability_status,
    chronic_absence = chronic_absence,
    stringsAsFactors = FALSE
  )
}
