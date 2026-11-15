.PHONY: all data train evaluate score report monitor test clean

all: data train evaluate score report monitor test

data:
	Rscript scripts/01_generate_data.R

train: data
	Rscript scripts/02_train_models.R

evaluate: train
	Rscript scripts/03_evaluate_models.R

score: train
	Rscript scripts/04_score_new_cohort.R

test:
	Rscript tests/test_pipeline.R
	Rscript tests/test_input_monitoring.R

monitor: train
	Rscript scripts/06_monitor_inputs.R

report: evaluate
	Rscript scripts/05_publish_report.R

clean:
	rm -rf data artifacts
	rm -f outputs/*.csv
