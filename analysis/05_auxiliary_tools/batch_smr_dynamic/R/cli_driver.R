#!/usr/bin/env Rscript

# Fixed command driver for the Python wrapper. Values are decoded from JSON and
# never interpolated into executable R source.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Restore dependencies from renv.lock.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Unable to resolve the batch SMR R driver path")
}
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
module_dir <- dirname(script_path)

stdin_connection <- file("stdin", open = "r")
on.exit(close(stdin_connection), add = TRUE)
request_text <- paste(readLines(stdin_connection, warn = FALSE), collapse = "\n")
if (!nzchar(request_text)) {
  stop("Expected a JSON request on standard input")
}
payload <- jsonlite::fromJSON(request_text, simplifyVector = TRUE)

source(file.path(module_dir, "batch_smr_dynamic.R"), local = TRUE)
result <- run_smr_dynamic_batch(
  xqtl_resources = as.character(payload$xqtl_resources),
  out_filename = payload$out_filename,
  outcome_name = payload$outcome_name,
  xqtl_type = payload$xqtl_type,
  save_base_path = payload$save_base_path,
  pval = payload$pval,
  diff_freq_prop = payload$diff_freq_prop,
  diff_freq = payload$diff_freq,
  ancestry = payload$ancestry,
  quick_smr = isTRUE(payload$quick_smr),
  smr_HEIDI_p = payload$smr_HEIDI_p,
  plot_col = payload$plot_col,
  plot_highlight.col = payload$plot_highlight_col,
  verbose = isTRUE(payload$verbose),
  stop_on_error = isTRUE(payload$stop_on_error)
)

export_smr_batch_results(
  result,
  output_dir = payload$save_base_path,
  outcome_name = payload$outcome_name
)
