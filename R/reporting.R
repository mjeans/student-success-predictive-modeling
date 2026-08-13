subgroup_metrics <- function(data, probability, threshold, group_variable,
                             minimum_n = 100L) {
  groups <- unique(data[[group_variable]])
  rows <- lapply(groups, function(group_value) {
    selected <- data[[group_variable]] == group_value
    n <- sum(selected)
    truth <- data$chronic_absence[selected]
    p <- probability[selected]

    if (n < minimum_n) {
      return(data.frame(
        group_variable = group_variable,
        group = as.character(group_value),
        n = n,
        prevalence = NA_real_,
        flagged_rate = NA_real_,
        sensitivity = NA_real_,
        precision = NA_real_,
        brier_score = NA_real_,
        suppressed = TRUE
      ))
    }

    classified <- classification_metrics(truth, p, threshold)
    data.frame(
      group_variable = group_variable,
      group = as.character(group_value),
      n = n,
      prevalence = mean(truth),
      flagged_rate = classified[["flagged_rate"]],
      sensitivity = classified[["sensitivity"]],
      precision = classified[["precision"]],
      brier_score = mean((p - truth)^2),
      suppressed = FALSE
    )
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
