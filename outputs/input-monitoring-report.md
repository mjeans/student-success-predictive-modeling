# Scoring-input monitoring: executed synthetic example

The reference is fitted on 2023-24 training data only. These checks inspect new inputs before outcome labels are available; they do not establish continued model accuracy.

**2025-26 input disposition:** `within_monitoring_thresholds`.

The illustrative thresholds flag an absolute mean shift above 0.5 training SD, missingness increasing by more than 10 percentage points, or a grade share changing by more than 10 percentage points. These are review triggers, not validated universal cutoffs.

| feature | current_observed | standardized_mean_shift | current_missing_rate | status | reasons |
|---|---|---|---|---|---|
| baseline_score | 1920 | -0.013 | 0.040 | within_thresholds |  |
| prior_attendance_rate | 1951 | -0.025 | 0.024 | within_thresholds |  |
| first_30d_attendance_rate | 2000 | -0.219 | 0.000 | within_thresholds |  |
| lms_days_active | 1905 | -0.061 | 0.048 | within_thresholds |  |
| assignments_completed_rate | 1938 | -0.046 | 0.031 | within_thresholds |  |
| support_contacts | 2000 | -0.025 | 0.000 | within_thresholds |  |
| mobility_event | 2000 | 0.010 | 0.000 | within_thresholds |  |
| prior_behavior_incidents | 2000 | 0.066 | 0.000 | within_thresholds |  |

| grade | reference_share | current_share | absolute_change | status |
|---|---|---|---|---|
| K-2 | 0.242 | 0.260 | 0.017 | within_thresholds |
| 3-5 | 0.241 | 0.247 | 0.006 | within_thresholds |
| 6-8 | 0.257 | 0.256 | 0.001 | within_thresholds |
| 9-12 | 0.260 | 0.237 | 0.023 | within_thresholds |

## Controlled failure drills

| Scenario | Observed response |
|---|---|
| Attendance sent as 95 instead of 0.95 | blocked before scoring |
| Half the LMS values removed | human_review |

The drills change copies of synthetic inputs only. They do not retrain the model, change the validation threshold, alter test outcomes, or regenerate the dashboard graphics.

## Operational response

A schema/range failure blocks scoring; correct the upstream extract and rerun. A drift alert calls for source and population review, not automatic retraining. Hold any outreach release until a responsible team reviews material alerts. Later, when outcome labels mature, assess discrimination, calibration, subgroup error and workload separately. A passed input check is not deployment approval.

[Monitoring policy](../docs/input-monitoring.md) · [Model card](../docs/model-card.md)
