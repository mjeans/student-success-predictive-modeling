# Before scoring: validity is different from drift

The [executed monitoring report](../outputs/input-monitoring-report.md) demonstrates checks that can run before new outcomes arrive. Everything in this example is synthetic.

## Two different responses

- **Invalid representation blocks scoring.** Missing required fields, nonnumeric values, out-of-range rates, infinite values, fractional event counts, an empty cohort, and unknown/missing grade categories fail explicitly. Attendance is a proportion from 0 to 1, not a percentage from 0 to 100. Entirely missing training predictors cannot acquire a median.
- **Valid but shifted inputs trigger human review.** Training means/SDs, missingness rates and grade shares form a reference stored with the preprocessing bundle. Changed population composition or a missing feed can be syntactically valid. Warnings do not silently retrain, recalibrate or change the operating threshold.

The fixed example triggers are an absolute mean change above 0.5 training SD, missingness increasing by more than 0.10, or grade share shifting by more than 0.10. These illustrative tolerances must be agreed with a real data owner before operational use. They are not significance tests. Standardized means can miss changes in tails or multimodal distributions; a passed screen is not evidence of distributional equality.

Missing numeric inputs can still be imputed using training medians, but entirely missing scoring fields are prominently flagged for review. Categorical missingness is not imputed. A zero-variance reference changing to another value gets a specific warning rather than division by zero. Extra columns are permitted, but prediction remains restricted to the established formula; protected/audit fields and outcomes do not enter scoring.

## Failure drills and reproduction

```bash
Rscript scripts/01_generate_data.R
Rscript scripts/02_train_models.R
Rscript scripts/06_monitor_inputs.R
Rscript tests/test_input_monitoring.R
```

The first drill sends attendance in the wrong units and confirms a hard failure. The second removes half of a synthetic LMS feed and confirms a review alert. Neither modifies the original data, model, or test results. `make all` includes the monitoring report and its tests.

The monitoring code requires a newly built model bundle so its reference is fitted on training rows. Monitoring needs no outcome labels; later label-based monitoring must still evaluate calibration, ranking, subgroup performance, and support capacity. Drift alone is not concept drift, causality, proof of unfairness, or permission to deploy.
