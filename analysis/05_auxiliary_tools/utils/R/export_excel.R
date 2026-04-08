#' @title Export Data to Excel File
#' @description Export data.frame to .xlsx file with writexl
#' @param data Input data.frame
#' @param output_path Output file path (.xlsx)
#' @param sheet_name Sheet name. Default "Sheet1"
#' @param col_names Write column names? Default TRUE
#' @param format_dates Format date columns? Default TRUE
#' @return Invisible TRUE if successful
#' @examples
#' \dontrun{
#' # Export to Excel
#' export_to_excel(res, "E:/results/output.xlsx")
#'
#' # Export with custom sheet name
#' export_to_excel(data, "report.xlsx", sheet_name = "GWAS Results")
#' }
export_to_excel <- function(
    data,
    output_path,
    sheet_name = "Sheet1",
    col_names = TRUE,
    format_dates = TRUE
) {

  # Load required package
  if (!requireNamespace("writexl", quietly = TRUE)) {
    install.packages("writexl", repos = "https://cran.rstudio.com/")
  }
  library(writexl)

  # Create output directory if needed
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    message("Created directory: ", output_dir)
  }

  # Format date columns if requested
  if (format_dates) {
    data <- format_date_columns(data)
  }

  # Write file
  write_xlsx(data, path = output_path)

  # Report
  file_size <- file.size(output_path) / 1024
  message(sprintf(
    "[%s] Exported %d rows x %d cols to: %s (%.1f KB)",
    Sys.time(), nrow(data), ncol(data), output_path, file_size
  ))

  invisible(TRUE)
}


#' @title Export Multiple Sheets to Excel
#' @description Export a named list of data.frames to separate sheets
#' @param sheet_list Named list of data.frames
#' @param output_path Output file path (.xlsx)
#' @param sheet_names Optional vector of sheet names
#' @return Invisible TRUE if successful
#' @examples
#' \dontrun{
#' # Export multiple sheets
#' sheets <- list(
#'   "Summary" = summary_data,
#'   "Top Hits" = top_hits,
#'   "QCs" = qc_results
#' )
#' export_sheets_to_excel(sheets, "E:/results/complete_report.xlsx")
#' }
export_sheets_to_excel <- function(sheet_list, output_path, sheet_names = NULL) {

  if (!requireNamespace("writexl", quietly = TRUE)) {
    install.packages("writexl", repos = "https://cran.rstudio.com/")
  }
  library(writexl)

  # Create directory
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Use names or default
  if (is.null(sheet_names)) {
    sheet_names <- names(sheet_list)
    if (is.null(sheet_names)) {
      sheet_names <- paste0("Sheet", seq_along(sheet_list))
    }
  }

  # Write workbook
  write_xlsx(sheet_list, path = output_path)

  message(sprintf(
    "[%s] Exported %d sheets to: %s",
    Sys.time(), length(sheet_list), output_path
  ))

  invisible(TRUE)
}


#' @title Format Date Columns
#' @description Convert POSIXct/POSIXlt columns to character for Excel export
#' @param data Input data.frame
#' @return data.frame with formatted dates
format_date_columns <- function(data) {

  for (col in names(data)) {
    if (inherits(data[[col]], c("POSIXct", "POSIXlt", "Date"))) {
      data[[col]] <- format(data[[col]], "%Y-%m-%d %H:%M:%S")
    }
  }

  return(data)
}


#' @export
utils::globalVariables(c("format_date_columns", "export_sheets_to_excel"))
