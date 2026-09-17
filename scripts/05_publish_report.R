source("config/model_config.R")
source("R/preprocessing.R")
source("R/metrics.R")
source("R/modeling.R")
source("R/portfolio_report.R")
d <- read.csv("data/synthetic_student_success.csv", na.strings = c("", "NA"))
d$grade_band <- factor(d$grade_band, levels = c("K-2", "3-5", "6-8", "9-12"))
test <- temporal_split(d)$test
bundle <- readRDS("artifacts/model_bundle.rds")
p <- predict_bundle(bundle, test)
y <- test$chronic_absence
metrics <- read.csv("outputs/test_metrics.csv")
comparison <- read.csv("outputs/validation_model_comparison.csv")
groups <- read.csv("outputs/subgroup_metrics.csv")

# One precision/recall point per distinct probability; tied scores enter together.
ord <- order(p, decreasing = TRUE)
ends <- c(which(diff(p[ord]) != 0), length(p))
pr <- data.frame(threshold = p[ord][ends],
                 recall = cumsum(y[ord] == 1L)[ends] / sum(y == 1L),
                 precision = cumsum(y[ord] == 1L)[ends] / ends)
write.csv(pr, "outputs/precision_recall_curve.csv", row.names = FALSE)
pr_plot <- ggplot(pr, aes(recall, precision)) +
  geom_step(direction = "vh", color = "#087e83", linewidth = .9) +
  geom_hline(yintercept = mean(y), color = "#687b89", linetype = 2) +
  coord_cartesian(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(title = "Precision across recall thresholds", x = "Recall (sensitivity)", y = "Precision",
       subtitle = sprintf("Synthetic temporal holdout; average precision %.3f", metrics$average_precision),
       caption = "Dashed line: holdout prevalence. Curve is diagnostic; the decision threshold stays locked.")
publish_plot(pr_plot, "assets/precision-recall.svg", "Precision-recall curve",
             "Threshold-level curve with tied predictions grouped together; prevalence is the reference.")
bins <- cut(p, seq(0, 1, .1), include.lowest = TRUE)
calibration <- do.call(rbind, lapply(levels(bins), function(b) {
  use <- bins == b
  if (!any(use)) return(NULL)
  data.frame(bin = b, n = sum(use), mean_predicted = mean(p[use]), observed = mean(y[use]))
}))
write.csv(calibration, "outputs/calibration_bins.csv", row.names = FALSE)
cal_plot <- ggplot(calibration, aes(mean_predicted, observed)) +
  geom_abline(slope = 1, intercept = 0, color = "#687b89", linetype = 2) +
  geom_point(aes(size = n), color = "#087e83") +
  coord_equal(xlim = c(0, 1), ylim = c(0, 1)) +
  labs(title = "Do predicted probabilities match observed risk?",
       subtitle = "Synthetic temporal holdout; equal-width probability bins",
       x = "Mean predicted probability", y = "Observed outcome proportion", size = "Bin n",
       caption = "Descriptive calibration only. Bin sizes vary; points are not equally precise.")
publish_plot(cal_plot, "assets/calibration.svg", "Calibration of holdout predictions",
             "Observed versus predicted probabilities in equal-width bins; marker area represents sample count.")

# Keep the established summary-card appearance, but derive every result from outputs.
svg <- paste(readLines("assets/model-evaluation-template.svg"), collapse = "\n")
values <- c(roc_auc = sprintf("%.3f", metrics$roc_auc), average_precision = sprintf("%.3f", metrics$average_precision),
            brier_score = sprintf("%.3f", metrics$brier_score), precision_percent = sprintf("%.1f%%", 100 * metrics$precision),
            prevalence = sprintf("%.3f", metrics$prevalence), flagged_percent = sprintf("%.1f%%", 100 * metrics$flagged_rate),
            flagged_width = sprintf("%.1f", 450 * min(metrics$flagged_rate / .25, 1)))
for (key in names(values)) svg <- gsub(paste0("{{", key, "}}"), values[[key]], svg, fixed = TRUE)
stopifnot(!grepl("{{", svg, fixed = TRUE))
writeLines(svg, "assets/model-evaluation.svg", useBytes = TRUE)

write_research_report(c("# Executed predictive-model evaluation", "",
  "## Question and design", "",
  "Can early attendance and service indicators prioritize supportive review on a later synthetic school-year cohort? Training, validation, and holdout years are separate; preprocessing is learned from training only. Protected attributes remain audit-only.", "",
  sprintf("The validation-selected model is %s; threshold %.4f is locked before holdout evaluation (n = %s).", bundle$selected_model, bundle$threshold, nrow(test)), "",
  "## Validation model comparison", "", md_table(comparison), "",
  "Average precision groups tied scores at the threshold level. It is not trapezoidal PR area. The September 2026 correction removes order dependence; logistic regression remains selected.", "",
  "## Holdout results", "", "![Source-generated evaluation summary](../assets/model-evaluation.svg)", "",
  "![Precision-recall diagnostic](../assets/precision-recall.svg)", "",
  "![Calibration diagnostic](../assets/calibration.svg)", "", md_table(metrics), "",
  "[Threshold-level PR data](precision_recall_curve.csv) and [calibration bin denominators](calibration_bins.csv). The threshold-analysis CSV is exploratory holdout capacity monitoring, not a basis for retuning the locked model.", "",
  "## Subgroup uncertainty and denominators", "",
  md_table(groups[, c("group_variable", "group", "n", "schools", "positives", "flagged", "sensitivity", "sensitivity_lower", "sensitivity_upper", "precision", "precision_lower", "precision_upper")]), "",
  "Intervals are 2.5th/97.5th percentiles from 500 school-cluster bootstrap replicates (seed 20260917), holding predictions and the model fixed. They account for resampling schools in this synthetic holdout, not training/model-selection uncertainty. Metrics are suppressed below 100 records; sensitivity additionally requires 20 positive outcomes and precision 20 flagged records. These are descriptive audits, not adjusted tests of group disparities or fairness certification.", "",
  "## Operational boundary", "",
  sprintf("The validation capacity target is 15%%; the locked cutoff flags %.1f%% of the holdout. A fixed cutoff does not guarantee a fixed workload.", 100 * metrics$flagged_rate), "",
  "Synthetic performance does not establish transportability or benefit. No automated eligibility, discipline, or denial decisions are authorized; a real deployment requires governance, external validation, and monitored human review."))
