#!/usr/bin/env Rscript

recipe_files <- c(
  "analysis/01_basic_gwas/basic_gwas.R",
  "analysis/02_multiomics_gwas/multiomics_gwas.R",
  "analysis/03_singlecell_gwas/singlecell_gwas.R",
  "analysis/04_comorbidity_gwas/comorbidity_gwas.R",
  "analysis/05_auxiliary_tools/auxiliary_tools.R"
)

parse_recipe_chunks <- function(path) {
  lines <- readLines(path, warn = FALSE)
  in_chunk <- FALSE
  chunk <- character()
  chunk_start <- NA_integer_
  chunk_number <- 0L
  for (line_number in seq_along(lines)) {
    line <- lines[[line_number]]
    if (!in_chunk && grepl("^```[rR][[:space:]]*$", line)) {
      in_chunk <- TRUE
      chunk <- character()
      chunk_start <- line_number + 1L
    } else if (in_chunk && grepl("^```[[:space:]]*$", line)) {
      chunk_number <- chunk_number + 1L
      tryCatch(
        parse(text = chunk, keep.source = TRUE),
        error = function(error) {
          stop(
            path,
            ": R chunk ",
            chunk_number,
            " beginning at line ",
            chunk_start,
            " is invalid: ",
            conditionMessage(error)
          )
        }
      )
      in_chunk <- FALSE
    } else if (in_chunk) {
      chunk <- c(chunk, line)
    }
  }
  if (in_chunk) {
    stop(path, ": unclosed R code fence beginning at line ", chunk_start)
  }
  if (chunk_number == 0L) {
    stop(path, ": no fenced R examples found")
  }
  message("Parsed ", chunk_number, " R example chunks in ", path)
}

all_r_files <- c(
  list.files(
    file.path("analysis", "05_auxiliary_tools"),
    pattern = "\\.R$",
    recursive = TRUE,
    full.names = TRUE
  ),
  list.files(file.path("scripts", "ci"), pattern = "\\.R$", full.names = TRUE),
  list.files(file.path("tests", "r"), pattern = "\\.R$", full.names = TRUE),
  recipe_files
)
all_r_files <- unique(sub("^\\./", "", all_r_files))
source_files <- setdiff(all_r_files, recipe_files)

for (path in source_files) {
  parse(path, keep.source = TRUE)
  message("Parsed R source: ", path)
}
for (path in recipe_files) {
  parse_recipe_chunks(path)
}
