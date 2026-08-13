.PHONY: all data train evaluate score test clean

all: data train evaluate score test

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

clean:
	rm -rf data artifacts
	rm -f outputs/*.csv
