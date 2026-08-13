source("R/preprocessing.R")
source("R/modeling.R")
source("R/reporting.R")

student_data <- read.csv(
  "data/synthetic_student_success.csv",
  stringsAsFactors = FALSE,
  na.strings = c("", "NA")
)
student_data$grade_band <- factor(
  student_data$grade_band,
  levels = c("K-2", "3-5", "6-8", "9-12")
)

bundle <- readRDS("artifacts/model_bundle.rds")
scoring_data <- student_data[
  student_data$academic_year == "2025-26",
  ,
  drop = FALSE
]
probability <- predict_bundle(bundle, scoring_data)

scores <- data.frame(
  student_id = scoring_data$student_id,
  school_id = scoring_data$school_id,
  risk_probability = round(probability, 4),
  risk_band = risk_band(probability),
  support_queue = ifelse(
    probability >= bundle$threshold,
    "review_for_support",
    "routine_monitoring"
  ),
  stringsAsFactors = FALSE
)

scores <- scores[order(scores$risk_probability, decreasing = TRUE), ]
write.csv(scores, "outputs/scored_holdout_cohort.csv", row.names = FALSE)

cat(sprintf(
  "Scored %s records; %s entered the support-review queue.\n",
  nrow(scores),
  sum(scores$support_queue == "review_for_support")
))
