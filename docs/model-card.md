# Model card

## Model purpose

Prioritize a capacity-limited human review queue for proactive attendance support after the first 30 instructional days. The score estimates the probability of chronic absence by the end of the academic year in a fully synthetic population.

## Intended users

- Student-success analysts monitoring model and queue performance
- Program managers allocating voluntary support resources
- Trained school staff reviewing context before outreach

## Prohibited uses

- Discipline, surveillance, grading, placement, or eligibility decisions
- Automatic outreach without contextual review
- Ranking staff or schools
- Interpreting risk factors as causal drivers
- Application to real students without governance, validation, consent review, and local legal review

## Data and outcome

The generator creates 6,000 synthetic records across three academic years. Predictors are limited to baseline information and measures available within the first 30 days. The binary outcome is whether a student's end-of-year attendance rate would meet a chronic-absence definition in the synthetic data-generating process.

No real people or institutions are represented.

## Development design

| Component | Cohort | Role |
|---|---|---|
| Training | 2023–24 | Fit imputation and candidate models |
| Validation | 2024–25 | Compare candidates and set the review threshold |
| Test | 2025–26 | One-time final evaluation |

The temporal split is more demanding and operationally realistic than a random split when deployment occurs in a future cohort.

## Candidate models

1. Logistic regression with main effects and missingness indicators
2. Constrained decision tree with maximum depth 5 and minimum leaf size 75

Logistic regression is favored in the reference run because it provides stronger validation PR AUC and probability accuracy while remaining interpretable.

## Predictor policy

Included predictors:

- Baseline assessment score
- Prior-year attendance rate
- First-30-day attendance rate
- LMS active days
- Assignment completion rate
- Support-contact count
- Mobility indicator
- Prior behavior-incident count
- Grade band
- Missingness indicators learned consistently across cohorts

Audit-only fields:

- Gender
- Race/ethnicity
- Economic-disadvantage status
- Multilingual-learner status
- Disability status

Audit-only fields are never included in the model formula.

## Evaluation

The project reports ROC AUC, PR AUC, Brier score, log loss, calibration intercept and slope, expected calibration error, sensitivity, specificity, precision, and flagged rate. Subgroup tables add sample size, prevalence, review rate, sensitivity, precision, and Brier score. Cells below 100 records are suppressed.

## Threshold policy

The validation threshold is the 85th percentile of validation probabilities, corresponding to a 15% review capacity. Because score distributions change, the same threshold can flag a different proportion in the next cohort. This is monitored explicitly rather than hidden.

## Limitations

- Synthetic performance does not establish real-world validity.
- The outcome embeds assumptions chosen for demonstration.
- Demographic exclusion does not remove proxy pathways or structural inequity.
- Group metrics can be unstable even above the minimum sample threshold.
- The project evaluates prediction, not intervention impact.
- Model transport to another district, year, population, or definition is unsupported.

## Monitoring recommendations

Before any real deployment, define owners and review cadence for data quality, prevalence, score distribution, flagged rate, missingness, discrimination, calibration, subgroup gaps, intervention capacity, appeals, and retirement criteria. Revalidate after material policy, population, product, or data-pipeline changes.
