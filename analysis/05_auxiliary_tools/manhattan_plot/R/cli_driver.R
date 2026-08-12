#!/usr/bin/env Rscript

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Restore dependencies from renv.lock.")
}
if (!requireNamespace("data.table", quietly = TRUE)) {
  stop("Package 'data.table' is required. Restore dependencies from renv.lock.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Unable to resolve the Manhattan plot R driver path")
}
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
module_dir <- dirname(script_path)

stdin_connection <- file("stdin", open = "r")
on.exit(close(stdin_connection), add = TRUE)
request_text <- paste(readLines(stdin_connection, warn = FALSE), collapse = "\n")
if (!nzchar(request_text)) {
  stop("Expected a JSON request on standard input")
}
request <- jsonlite::fromJSON(request_text, simplifyVector = TRUE)
operation <- request$operation
payload <- request$payload
if (!operation %in% c("manhattan", "qq")) {
  stop("Unsupported plotting operation")
}

source(file.path(module_dir, "manhattan_plot.R"), local = TRUE)
data <- data.table::fread(payload$input_file, data.table = FALSE)

if (operation == "manhattan") {
  fdr_col <- if (is.null(payload$fdr_col) || !nzchar(payload$fdr_col)) {
    NULL
  } else {
    payload$fdr_col
  }
  label_snps <- if (is.null(payload$label_snps)) {
    NULL
  } else {
    as.character(payload$label_snps)
  }
  create_manhattan_plot(
    data = data,
    pval_col = payload$pval_col,
    fdr_col = fdr_col,
    threshold = payload$threshold,
    threshold_type = payload$threshold_type,
    label_snps = label_snps,
    title = payload$title,
    width = payload$width,
    height = payload$height,
    dpi = payload$dpi,
    output = payload$output,
    sig_point_color = payload$sig_color
  )
} else {
  create_qq_plot(
    data = data,
    pval_col = payload$pval_col,
    title = payload$title,
    width = payload$width,
    height = payload$height,
    output = payload$output,
    dpi = payload$dpi
  )
}
