#!/usr/bin/env Rscript

# Fixed command driver for the Python wrapper. Caller values are decoded from
# JSON and remain data throughout execution.

if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Package 'jsonlite' is required. Restore the project's renv lockfile.")
}

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
if (length(script_arg) != 1) {
  stop("Unable to resolve the utils R driver path")
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

if (!is.character(operation) || length(operation) != 1) {
  stop("Request operation must be a single string")
}

as_character_vector <- function(value) {
  if (is.null(value) || length(value) == 0) {
    return(character())
  }
  as.character(unlist(value, use.names = FALSE))
}

optional_path <- function(value) {
  if (is.null(value) || length(value) == 0 || !nzchar(value)) {
    return(NULL)
  }
  as.character(value)
}

if (operation == "read") {
  source(file.path(module_dir, "read_table.R"), local = TRUE)
  separator <- switch(payload$sep,
    "auto" = "auto",
    "tab" = "\t",
    "comma" = ",",
    "space" = "",
    stop("Unsupported separator")
  )
  data <- read_data(
    file_path = payload$input_file,
    header = isTRUE(payload$header),
    sep = separator,
    na.strings = payload$na_strings,
    check.names = isTRUE(payload$check_names)
  )
  cat("ROWS:", nrow(data), "\n")
  cat("COLS:", ncol(data), "\n")
  cat("HEAD:\n")
  print(utils::head(data, 3))

} else if (operation == "convert") {
  source(file.path(module_dir, "convert_pos.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  columns <- as_character_vector(payload$columns)
  target_type <- payload$to_type

  if (!target_type %in% c("numeric", "integer", "character")) {
    stop("Unsupported conversion type")
  }

  for (column in columns) {
    if (!column %in% names(data)) {
      warning("Column not found and skipped: ", column)
      next
    }
    if (target_type == "numeric") {
      data <- convert_to_numeric(data, column, quiet = TRUE)
    } else if (target_type == "integer") {
      data <- convert_to_integer(data, column)
    } else {
      data <- convert_to_character(data, column)
    }
    cat("Converted:", column, "->", target_type, "| NAs:", sum(is.na(data[[column]])), "\n")
  }

  output_file <- optional_path(payload$output_file)
  if (!is.null(output_file)) {
    saveRDS(data, output_file)
  }

} else if (operation == "export_excel") {
  source(file.path(module_dir, "export_excel.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  export_to_excel(data, payload$output_file, sheet_name = payload$sheet_name)

} else if (operation == "rename") {
  source(file.path(module_dir, "rename_columns.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  data <- rename_with_str_replace(
    data,
    payload$column,
    payload$pattern,
    payload$replacement
  )
  output_file <- optional_path(payload$output_file)
  if (!is.null(output_file)) {
    saveRDS(data, output_file)
  }

} else if (operation == "export_rds") {
  source(file.path(module_dir, "export_rds.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  compression <- if (identical(payload$compress, "none")) FALSE else payload$compress
  save_to_rds(data, payload$output_file, compress = compression)

} else if (operation == "clean") {
  source(file.path(module_dir, "clean_compress.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  keep_cols <- as_character_vector(payload$keep_cols)
  drop_cols <- as_character_vector(payload$drop_cols)
  if (length(keep_cols) > 0) {
    clean_and_compress(data, keep_cols = keep_cols, output_path = payload$output_file)
  } else {
    clean_and_compress(data, drop_cols = drop_cols, output_path = payload$output_file)
  }

} else if (operation == "export_txt") {
  source(file.path(module_dir, "export_txt.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  separator <- switch(payload$sep,
    "tab" = "\t",
    "comma" = ",",
    "space" = " ",
    stop("Unsupported separator")
  )
  export_to_txt(
    data,
    payload$output_file,
    sep = separator,
    col.names = isTRUE(payload$header)
  )

} else if (operation == "clean_gwas") {
  source(file.path(module_dir, "clean_compress.R"), local = TRUE)
  data <- readRDS(payload$input_file)
  clean_and_compress(
    data,
    keep_cols = as_character_vector(payload$essential_cols),
    output_path = payload$output_file
  )

} else {
  stop("Unsupported operation: ", operation)
}

cat("DONE\n")
