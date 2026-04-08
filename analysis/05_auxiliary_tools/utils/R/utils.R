#' @title OmniGWAS Utilities
#' @name OmniGWAS-utils
#' @description Auxiliary data processing tools for GWAS analysis
#'
#' This module provides a comprehensive suite of R functions for:
#' \itemize{
#'   \item Data reading and parsing (read_table.R)
#'   \item Column type conversion (convert_pos.R)
#'   \item Excel export (export_excel.R)
#'   \item Column renaming (rename_columns.R)
#'   \item RDS file operations (export_rds.R)
#'   \item Data cleaning and compression (clean_compress.R)
#'   \item Text file export (export_txt.R)
#' }
#'
#' @docType package
#' @author OmniGWAS Team
#' @keywords package
#' @examples
#' \dontrun{
#' # Source all functions
#' source("utils/R/utils.R")
#'
#' # Or source individual modules
#' source("utils/R/read_table.R")
#' source("utils/R/export_excel.R")
#' }
NULL

# Module version
UTILS_VERSION <- "1.0.0"

# Module description
UTILS_DESCRIPTION <- "Auxiliary data processing tools for GWAS analysis"


#' @title Load All Utils Modules
#' @description Source all R files in the utils module
#' @param module_dir Directory containing utils R files
#' @param quiet Suppress messages? Default FALSE
#' @return Invisible TRUE
load_utils <- function(module_dir = NULL, quiet = FALSE) {

  if (is.null(module_dir)) {
    module_dir <- file.path(dirname(sys.frame(1)$ofile), "R")
  }

  if (!dir.exists(module_dir)) {
    stop("Module directory not found: ", module_dir)
  }

  # List all R files
  r_files <- list.files(
    module_dir,
    pattern = "\\.R$",
    full.names = TRUE
  )

  # Source each file
  for (f in r_files) {
    if (!quiet) {
      message("Loading: ", basename(f))
    }
    source(f, local = FALSE)
  }

  if (!quiet) {
    message(sprintf(
      "\n[OK] OmniGWAS utils v%s loaded (%d functions)",
      UTILS_VERSION, length(r_files)
    ))
  }

  invisible(TRUE)
}


#' @title List All Exported Functions
#' @description Get a list of all available functions in utils
#' @return Character vector of function names
list_utils_functions <- function() {

  utils_functions <- c(
    # read_table.R
    "read_data", "detect_separator", "read_gwas_sumstats",

    # convert_pos.R
    "convert_to_numeric", "convert_columns_to_numeric",
    "convert_to_integer", "convert_to_character", "check_column_types",

    # export_excel.R
    "export_to_excel", "export_sheets_to_excel", "format_date_columns",

    # rename_columns.R
    "rename_columns", "rename_with_mapping", "rename_values",
    "rename_with_str_replace", "standardize_colnames",

    # export_rds.R
    "save_to_rds", "load_rds", "save_with_timestamp", "batch_save_rds",

    # clean_compress.R
    "clean_and_compress", "quick_clean_gwas", "remove_cols_by_pattern",
    "subset_cols", "get_col_stats",

    # export_txt.R
    "export_to_txt", "export_for_fuma", "export_gz",
    "append_to_txt", "batch_export",

    # utils.R
    "load_utils", "list_utils_functions"
  )

  return(sort(unique(utils_functions)))
}


#' @title Print Utils Module Info
#' @description Display information about the utils module
print_utils_info <- function() {

  cat("\n")
  cat("==============================================\n")
  cat("  OmniGWAS Utils Module Information\n")
  cat("==============================================\n")
  cat(sprintf("\n  Version: %s\n", UTILS_VERSION))
  cat(sprintf("  Description: %s\n", UTILS_DESCRIPTION))
  cat("\n  Included Modules:\n")
  cat("  - read_table.R     : Data reading functions\n")
  cat("  - convert_pos.R   : Column type conversion\n")
  cat("  - export_excel.R   : Excel export (writexl)\n")
  cat("  - rename_columns.R : Column/value renaming\n")
  cat("  - export_rds.R     : RDS file operations\n")
  cat("  - clean_compress.R : Data cleaning & compression\n")
  cat("  - export_txt.R     : Text file export\n")
  cat(sprintf("\n  Total Functions: %d\n", length(list_utils_functions())))
  cat("\n  Usage:\n")
  cat("  source(\"utils/R/utils.R\")\n")
  cat("\n==============================================\n")
  cat("\n")

  invisible(NULL)
}


#' @title Quick Start Guide
#' @description Show quick start examples for common tasks
quick_start_utils <- function() {

  cat("\n")
  cat("=== OmniGWAS Utils Quick Start ===\n\n")

  cat("1. Load all functions:\n")
  cat('   source("utils/R/utils.R")\n\n')

  cat("2. Read data file:\n")
  cat('   data <- read_data("results.txt.gz")\n\n')

  cat("3. Convert column to numeric:\n")
  cat('   data <- convert_to_numeric(data, "pos.outcome")\n\n')

  cat("4. Rename column values:\n")
  cat('   data <- rename_values(data, "outcome",\n')
  cat('     old_values = c("Nonalcoholic_steatohepatitis_R11"),\n')
  cat('     new_values = c("NASH"))\n\n')

  cat("5. Remove columns and save:\n")
  cat('   clean_and_compress(data,\n')
  cat('     drop_cols = c("outcome", "id.outcome"),\n')
  cat('     output_path = "cleaned.txt.gz")\n\n')

  cat("6. Export to Excel:\n")
  cat('   export_to_excel(data, "output.xlsx")\n\n')

  cat("7. Save as RDS:\n")
  cat('   save_to_rds(data, "data.rds")\n\n')

  cat("8. Export for FUMA:\n")
  cat('   export_for_fuma(data, "FUMA_input.txt")\n\n')

  invisible(NULL)
}


# Module initialization message
.onLoad <- function(libname, pkgname) {
  # Optional: show info on package load
  # print_utils_info()
}


# Module unload message
.onUnload <- function(libpath) {
  message("Unloading OmniGWAS utils module...")
}
