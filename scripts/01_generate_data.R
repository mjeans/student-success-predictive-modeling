source("config/model_config.R")
source("R/data_generation.R")

dir.create("data", showWarnings = FALSE, recursive = TRUE)

student_data <- generate_student_success_data(model_config$n_per_year)
write.csv(
  student_data,
  "data/synthetic_student_success.csv",
  row.names = FALSE,
  na = ""
)

cat(
  sprintf(
    "Generated %s deterministic synthetic records across %s academic years.\n",
    format(nrow(student_data), big.mark = ","),
    length(unique(student_data$academic_year))
  )
)
