model_formula <- chronic_absence ~
  baseline_score +
  prior_attendance_rate +
  first_30d_attendance_rate +
  lms_days_active +
  assignments_completed_rate +
  support_contacts +
  mobility_event +
  prior_behavior_incidents +
  grade_band +
  baseline_score_missing +
  prior_attendance_rate_missing +
  lms_days_active_missing +
  assignments_completed_rate_missing

fit_candidate_models <- function(training_data) {
  if (!requireNamespace("rpart", quietly = TRUE)) {
    stop("The recommended R package 'rpart' is required.")
  }

  list(
    logistic_regression = glm(
      model_formula,
      data = training_data,
      family = binomial()
    ),
    decision_tree = rpart::rpart(
      model_formula,
      data = training_data,
      method = "class",
      control = rpart::rpart.control(
        cp = 0.002,
        maxdepth = 5L,
        minbucket = 75L,
        xval = 10L
      )
    )
  )
}

predict_candidate <- function(model, model_name, new_data) {
  if (model_name == "logistic_regression") {
    return(as.numeric(predict(model, newdata = new_data, type = "response")))
  }

  probabilities <- predict(model, newdata = new_data, type = "prob")
  if (!"1" %in% colnames(probabilities)) {
    stop("Decision-tree predictions do not include the positive class.")
  }
  as.numeric(probabilities[, "1"])
}

compare_models <- function(models, validation_data, capacity_rate = 0.15) {
  rows <- lapply(names(models), function(model_name) {
    probability <- predict_candidate(
      models[[model_name]],
      model_name,
      validation_data
    )
    threshold <- capacity_threshold(probability, capacity_rate)
    metrics <- probability_metrics(
      validation_data$chronic_absence,
      probability,
      threshold
    )
    data.frame(
      model = model_name,
      t(metrics),
      expected_calibration_error = expected_calibration_error(
        validation_data$chronic_absence,
        probability
      ),
      row.names = NULL,
      check.names = FALSE
    )
  })

  comparison <- do.call(rbind, rows)
  comparison <- comparison[
    order(-comparison$pr_auc, comparison$brier_score),
    ,
    drop = FALSE
  ]
  rownames(comparison) <- NULL
  comparison
}

make_model_bundle <- function(raw_training_data, raw_validation_data,
                              capacity_rate = 0.15) {
  preprocessor <- fit_preprocessor(raw_training_data)
  training_data <- apply_preprocessor(raw_training_data, preprocessor)
  validation_data <- apply_preprocessor(raw_validation_data, preprocessor)
  models <- fit_candidate_models(training_data)
  comparison <- compare_models(models, validation_data, capacity_rate)
  selected_model <- comparison$model[[1]]

  list(
    preprocessor = preprocessor,
    models = models,
    selected_model = selected_model,
    threshold = comparison$threshold[[1]],
    capacity_rate = capacity_rate,
    validation_comparison = comparison,
    feature_policy = list(
      predictors = c(model_numeric_features, model_categorical_features),
      audit_only = audit_features,
      outcome = "chronic_absence"
    )
  )
}

predict_bundle <- function(bundle, raw_data) {
  prepared <- apply_preprocessor(raw_data, bundle$preprocessor)
  predict_candidate(
    bundle$models[[bundle$selected_model]],
    bundle$selected_model,
    prepared
  )
}
