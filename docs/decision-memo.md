# Decision memo

## Recommendation

Use the score only as a prioritization aid for a trained support team, and begin with a time-limited shadow-mode evaluation. Do not automate outreach or student-level decisions.

## Evidence

The later-cohort benchmark retains useful discrimination (ROC AUC approximately 0.80) and improves substantially on the outcome prevalence baseline for precision-recall performance. At the validation-selected threshold, roughly 64% of flagged holdout records experience the synthetic outcome.

The same threshold flags 17.6% of the holdout cohort even though it was selected for a 15% validation capacity. That difference is operationally important: a static cutoff does not guarantee a static workload when prevalence or score distributions move.

Subgroup results also differ. In the reference run, economically disadvantaged students and students with a disability are flagged at higher rates. Those differences are consistent with the synthetic data-generating process, but they still require review because excluded characteristics may be associated with included indicators. Removing an attribute from the formula is not equivalent to removing inequity.

## Proposed operating controls

1. Run in shadow mode for one complete review cycle.
2. Require staff verification before any student contact.
3. Monitor data completeness and score distributions weekly.
4. Review capacity, sensitivity, precision, calibration, and subgroup gaps monthly.
5. Document why support was offered and whether students could access it.
6. Separate predictive monitoring from any later causal evaluation of the support program.
7. Pause scoring after a material data, policy, or population change until revalidation is complete.

## Decision boundary

The benchmark supports further evaluation of a human-reviewed queue. It does not support autonomous deployment, disciplinary use, or claims that changing a predictor will change the outcome.
