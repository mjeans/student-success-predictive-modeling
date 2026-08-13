# Generated outputs

Running `make all` writes the following files here:

- `validation_model_comparison.csv` — candidate-model validation metrics
- `test_metrics.csv` — selected-model temporal holdout metrics
- `subgroup_metrics.csv` — audit metrics with minimum-cell suppression
- `threshold_analysis.csv` — workload and classification tradeoffs
- `scored_holdout_cohort.csv` — example review-queue output

These files are ignored because they contain generated record-level scores or results that continuous integration recreates. Portfolio-level benchmark results are summarized in the main README, while the scripts remain the authoritative reproducible source.
