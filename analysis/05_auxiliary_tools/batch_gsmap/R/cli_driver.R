#!/usr/bin/env Rscript

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Restore the project's renv lockfile.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Unable to resolve the batch gsMap R driver path")
}
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
module_dir <- dirname(script_path)

stdin_connection <- file("stdin", open = "r")
on.exit(close(stdin_connection), add = TRUE)
payload_text <- paste(readLines(stdin_connection, warn = FALSE), collapse = "\n")
if (!nzchar(payload_text)) {
  stop("Expected a JSON payload on standard input")
}
payload <- jsonlite::fromJSON(payload_text, simplifyVector = TRUE)

if (!is.null(payload$r_library_path) && nzchar(payload$r_library_path)) {
  .libPaths(c(payload$r_library_path, .libPaths()))
}

source(file.path(module_dir, "batch_gsmap.R"), local = TRUE)
result <- run_gsmap_batch(
  sample_names = as.character(payload$sample_names),
  sumstats_file = payload$sumstats_file,
  trait_name = payload$trait_name,
  h5ad_dir = payload$h5ad_dir,
  annotation = payload$annotation,
  data_layer = payload$data_layer,
  max_processes = as.integer(payload$max_processes),
  save_base_path = payload$save_base_path,
  verbose = isTRUE(payload$verbose),
  stop_on_error = isTRUE(payload$stop_on_error)
)
export_batch_results(result, output_dir = payload$save_base_path, format = "json")
