#' @title Convert Column to Numeric Type
#' @description Convert specified columns to numeric type with error checking
#' @param data Input data.frame
#' @param col_name Column name to convert
#' @param quiet Suppress messages? Default FALSE
#' @return data.frame with converted column
#' @examples
#' \dontrun{
#' # Convert pos column to numeric
#' data <- convert_to_numeric(data, "pos")
#'
#' # Check NA counts after conversion
#' result <- convert_to_numeric(data, "pos.outcome", quiet = FALSE)
#' cat("NA count:", sum(is.na(result$pos.outcome)))
#' }
convert_to_numeric <- function(data, col_name, quiet = FALSE) {

  # Check if column exists
  if (!col_name %in% names(data)) {
    stop("Column '", col_name, "' not found in data")
  }

  # Get original class
  original_class <- class(data[[col_name]])

  # Convert to numeric
  converted <- as.numeric(data[[col_name]])

  # Count NAs introduced
  na_count <- sum(is.na(converted))
  original_na <- sum(is.na(data[[col_name]]))
  new_na <- na_count - original_na

  # Update data
  data[[col_name]] <- converted

  # Report
  if (!quiet) {
    message(sprintf(
      "[%s] Converted '%s': %s -> numeric | NAs: %d (new: %d)",
      Sys.time(), col_name, original_class, na_count, new_na
    ))
  }

  return(data)
}


#' @title Convert Multiple Columns to Numeric
#' @description Convert multiple columns to numeric type
#' @param data Input data.frame
#' @param col_names Vector of column names to convert
#' @param quiet Suppress messages? Default FALSE
#' @return data.frame with converted columns
convert_columns_to_numeric <- function(data, col_names, quiet = FALSE) {

  for (col in col_names) {
    if (col %in% names(data)) {
      data <- convert_to_numeric(data, col, quiet = quiet)
    } else {
      warning("Column '", col, "' not found, skipping")
    }
  }

  return(data)
}


#' @title Convert Column to Integer
#' @description Convert specified columns to integer type
#' @param data Input data.frame
#' @param col_name Column name to convert
#' @param na.rm Remove NAs before conversion? Default TRUE
#' @return data.frame with converted column
convert_to_integer <- function(data, col_name, na.rm = TRUE) {

  if (!col_name %in% names(data)) {
    stop("Column '", col_name, "' not found in data")
  }

  if (na.rm) {
    data[[col_name]] <- as.integer(data[[col_name]])
  } else {
    data[[col_name]] <- as.integer(as.numeric(data[[col_name]]))
  }

  return(data)
}


#' @title Convert Character Columns
#' @description Convert columns to character type
#' @param data Input data.frame
#' @param col_names Vector of column names
#' @return data.frame with converted columns
convert_to_character <- function(data, col_names) {

  for (col in col_names) {
    if (col %in% names(data)) {
      data[[col]] <- as.character(data[[col]])
    }
  }

  return(data)
}


#' @title Check Column Types
#' @description Display column types and NA counts for all columns
#' @param data Input data.frame
#' @param max_na_report Maximum NAs to report per column
#' @return invisible(NULL)
check_column_types <- function(data, max_na_report = 100) {

  cat("\n=== Column Type Summary ===\n\n")

  for (col in names(data)) {
    col_class <- class(data[[col]])[1]
    na_count <- sum(is.na(data[[col]]))
    na_pct <- sprintf("%.1f%%", 100 * na_count / nrow(data))

    cat(sprintf(
      "%-30s %-15s NAs: %d (%s)\n",
      col, col_class, na_count, na_pct
    ))
  }

  invisible(NULL)
}


#' @export
utils::globalVariables(c(
  "convert_columns_to_numeric",
  "convert_to_integer",
  "convert_to_character",
  "check_column_types"
))
