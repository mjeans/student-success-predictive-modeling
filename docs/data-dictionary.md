# Data dictionary

| Field | Type | Timing | Modeling role | Definition |
|---|---|---|---|---|
| `student_id` | Character | Static | Identifier | Synthetic unique record ID |
| `academic_year` | Character | Static | Split | Cohort used for temporal validation |
| `school_id` | Character | Static | Reporting only | Synthetic school identifier |
| `grade_band` | Factor | Baseline | Predictor | K–2, 3–5, 6–8, or 9–12 |
| `baseline_score` | Numeric | Baseline | Predictor | Synthetic assessment score, 20–100 |
| `prior_attendance_rate` | Numeric | Prior year | Predictor | Prior-year attendance proportion |
| `first_30d_attendance_rate` | Numeric | Day 30 | Predictor | Attendance proportion during the feature window |
| `lms_days_active` | Integer | Day 30 | Predictor | Days active in the learning platform |
| `assignments_completed_rate` | Numeric | Day 30 | Predictor | Assignment-completion proportion |
| `support_contacts` | Integer | Day 30 | Predictor | Count of documented support contacts |
| `mobility_event` | Binary | Day 30 | Predictor | Synthetic enrollment-mobility indicator |
| `prior_behavior_incidents` | Integer | Prior year | Predictor | Synthetic prior incident count |
| `gender` | Character | Baseline | Audit only | Synthetic gender category |
| `race_ethnicity` | Character | Baseline | Audit only | Synthetic race/ethnicity category |
| `economically_disadvantaged` | Binary | Baseline | Audit only | Synthetic economic-disadvantage indicator |
| `multilingual_learner` | Binary | Baseline | Audit only | Synthetic multilingual-learner indicator |
| `disability_status` | Binary | Baseline | Audit only | Synthetic disability-status indicator |
| `chronic_absence` | Binary | End of year | Outcome | Synthetic end-of-year chronic-absence indicator |

Missingness is introduced deterministically in four predictors. Median values are learned from the training cohort only, and corresponding missingness indicators are added before modeling.
