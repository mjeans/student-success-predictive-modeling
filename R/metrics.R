clip_probability <- function(probability, epsilon = 1e-8) {
  pmin(pmax(probability, epsilon), 1 - epsilon)
}

roc_auc <- function(truth, probability) {
  positive <- sum(truth == 1L)
  negative <- sum(truth == 0L)
  if (positive == 0L || negative == 0L) return(NA_real_)
  ranks <- rank(probability, ties.method = "average")
  (sum(ranks[truth == 1L]) - positive * (positive + 1) / 2) /
    (positive * negative)
}

average_precision <- function(truth, probability) {
  if (length(truth) != length(probability) || length(truth) == 0L ||
      anyNA(truth) || !all(truth %in% c(0L, 1L)) ||
      any(!is.finite(probability))) {
    stop("Average precision requires paired binary outcomes and finite scores.")
  }
  positive <- sum(truth == 1L)
  if (positive == 0L) return(NA_real_)
  order_index <- order(probability, decreasing = TRUE)
  ordered_truth <- truth[order_index]
  scores <- probability[order_index]
  # One operating point per distinct score: ties must enter together.
  ends <- c(which(diff(scores) != 0), length(scores))
  cumulative_tp <- cumsum(ordered_truth == 1L)
  precision <- cumulative_tp[ends] / ends
  recall <- cumulative_tp[ends] / positive
  sum(diff(c(0, recall)) * precision)
}

calibration_statistics <- function(truth, probability) {
  p <- clip_probability(probability)
  logit_p <- qlogis(p)
  fit <- suppressWarnings(glm(truth ~ logit_p, family = binomial()))
  coefficients <- coef(fit)
  c(
    calibration_intercept = unname(coefficients[[1]]),
    calibration_slope = unname(coefficients[[2]])
  )
}

classification_metrics <- function(truth, probability, threshold) {
  flagged <- probability >= threshold
  tp <- sum(flagged & truth == 1L)
  fp <- sum(flagged & truth == 0L)
  fn <- sum(!flagged & truth == 1L)
  tn <- sum(!flagged & truth == 0L)

  c(
    threshold = threshold,
    flagged_rate = mean(flagged),
    sensitivity = ifelse(tp + fn > 0, tp / (tp + fn), NA_real_),
    specificity = ifelse(tn + fp > 0, tn / (tn + fp), NA_real_),
    precision = ifelse(tp + fp > 0, tp / (tp + fp), NA_real_)
  )
}

probability_metrics <- function(truth, probability, threshold) {
  p <- clip_probability(probability)
  calibration <- calibration_statistics(truth, p)
  c(
    prevalence = mean(truth),
    roc_auc = roc_auc(truth, p),
    average_precision = average_precision(truth, p),
    brier_score = mean((p - truth)^2),
    log_loss = -mean(truth * log(p) + (1 - truth) * log(1 - p)),
    calibration,
    classification_metrics(truth, p, threshold)
  )
}

capacity_threshold <- function(probability, capacity_rate = 0.15) {
  unname(quantile(probability, probs = 1 - capacity_rate, type = 8))
}

expected_calibration_error <- function(truth, probability, bins = 10L) {
  breaks <- seq(0, 1, length.out = bins + 1L)
  bin <- cut(probability, breaks, include.lowest = TRUE, labels = FALSE)
  total <- length(truth)
  sum(vapply(seq_len(bins), function(current_bin) {
    selected <- bin == current_bin
    if (!any(selected)) return(0)
    mean(selected) * abs(mean(probability[selected]) - mean(truth[selected]))
  }, numeric(1)))
}
