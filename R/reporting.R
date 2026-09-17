# Fixed-model, school-resampling percentile intervals for descriptive audits.
cluster_intervals <- function(truth, probability, threshold, school, replicates = 500L) {
  flag <- probability >= threshold
  totals <- rowsum(cbind(tp = as.integer(flag & truth == 1L),
                        positive = as.integer(truth == 1L), flagged = as.integer(flag)),
                  group = school, reorder = FALSE)
  if (nrow(totals) < 2L) return(rep(NA_real_, 4))
  set.seed(20260917)
  bootstrap <- replicate(replicates, {
    z <- colSums(totals[sample.int(nrow(totals), nrow(totals), replace = TRUE), , drop = FALSE])
    c(sensitivity = if (z["positive"] > 0) z["tp"] / z["positive"] else NA_real_,
      precision = if (z["flagged"] > 0) z["tp"] / z["flagged"] else NA_real_)
  })
  c(quantile(bootstrap[1, ], c(.025, .975), na.rm = TRUE, names = FALSE),
    quantile(bootstrap[2, ], c(.025, .975), na.rm = TRUE, names = FALSE))
}

subgroup_metrics <- function(data, probability, threshold, group_variable,
                             minimum_n = 100L) {
  groups <- unique(data[[group_variable]])
  rows <- lapply(groups, function(group_value) {
    selected <- data[[group_variable]] == group_value
    n <- sum(selected)
    truth <- data$chronic_absence[selected]
    p <- probability[selected]
    positive <- sum(truth == 1L)
    flagged <- sum(p >= threshold)
    tp <- sum(truth == 1L & p >= threshold)
    suppressed <- n < minimum_n
    ci <- if (suppressed) rep(NA_real_, 4) else
      cluster_intervals(truth, p, threshold, data$school_id[selected])
    data.frame(
      group_variable = group_variable, group = as.character(group_value), n = n,
      schools = length(unique(data$school_id[selected])),
      positives = if (suppressed) NA_integer_ else positive,
      flagged = if (suppressed) NA_integer_ else flagged,
      true_positives = if (suppressed) NA_integer_ else tp,
      prevalence = if (suppressed) NA_real_ else mean(truth),
      flagged_rate = if (suppressed) NA_real_ else mean(p >= threshold),
      sensitivity = if (suppressed || positive < 20) NA_real_ else tp / positive,
      sensitivity_lower = if (suppressed || positive < 20) NA_real_ else ci[1],
      sensitivity_upper = if (suppressed || positive < 20) NA_real_ else ci[2],
      precision = if (suppressed || flagged < 20) NA_real_ else tp / flagged,
      precision_lower = if (suppressed || flagged < 20) NA_real_ else ci[3],
      precision_upper = if (suppressed || flagged < 20) NA_real_ else ci[4],
      brier_score = if (suppressed) NA_real_ else mean((p - truth)^2),
      suppressed = suppressed)
  })
  do.call(rbind, rows)
}

all_subgroup_metrics <- function(data, probability, threshold) {
  do.call(rbind, lapply(audit_features, function(group_variable) {
    subgroup_metrics(data, probability, threshold, group_variable)
  }))
}

threshold_analysis <- function(truth, probability, capacity_rates = c(.10, .15, .20, .25)) {
  do.call(rbind, lapply(capacity_rates, function(capacity_rate) {
    threshold <- capacity_threshold(probability, capacity_rate)
    metrics <- classification_metrics(truth, probability, threshold)
    data.frame(
      capacity_rate = capacity_rate,
      t(metrics),
      row.names = NULL,
      check.names = FALSE
    )
  }))
}

risk_band <- function(probability) {
  cut(
    probability,
    breaks = c(-Inf, 0.15, 0.30, 0.50, Inf),
    labels = c("low", "moderate", "high", "very_high"),
    right = FALSE
  )
}
