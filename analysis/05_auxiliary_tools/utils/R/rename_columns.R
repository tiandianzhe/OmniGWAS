#' @title Rename Columns in Dataset
#' @description Rename columns using pattern replacement or direct mapping
#' @param data Input data.frame
#' @param pattern Old pattern to replace (character)
#' @param replacement New pattern (character)
#' @param columns Columns to apply renaming (default all)
#' @param fixed Use fixed matching? Default TRUE
#' @param use_regex Use regex? Default FALSE
#' @return data.frame with renamed columns
#' @examples
#' \dontrun{
#' # Rename outcome column IDs
#' data <- rename_columns(data,
#'   pattern = "Nonalcoholic_steatohepatitis_R11",
#'   replacement = "NASH"
#' )
#' }
rename_columns <- function(
    data,
    pattern = NULL,
    replacement = NULL,
    columns = NULL,
    fixed = TRUE,
    use_regex = FALSE
) {

  # Validate inputs
  if (is.null(pattern) && is.null(replacement)) {
    stop("Both 'pattern' and 'replacement' must be provided")
  }

  # Select columns to rename
  if (is.null(columns)) {
    columns <- names(data)
  }

  # Apply renaming
  for (col in columns) {
    if (col %in% names(data)) {
      if (use_regex) {
        names(data)[names(data) == col] <- sub(
          pattern, replacement, names(data)[names(data) == col],
          perl = TRUE
        )
      } else {
        names(data)[names(data) == col] <- chartr(
          pattern, replacement, names(data)[names(data) == col]
        )
      }
    }
  }

  return(data)
}


#' @title Rename with Direct Mapping
#' @description Rename columns using a named vector
#' @param data Input data.frame
#' @param mapping Named character vector: c(old_name = "new_name", ...)
#' @return data.frame with renamed columns
#' @examples
#' \dontrun{
#' # Direct mapping
#' data <- rename_with_mapping(data, c(
#'   "old_col1" = "new_col1",
#'   "old_col2" = "new_col2"
#' ))
#' }
rename_with_mapping <- function(data, mapping) {

  # Check for required packages
  if (!requireNamespace("dplyr", quietly = TRUE)) {
    stop("Package 'dplyr' is required")
  }

  # Validate mapping
  old_names <- names(mapping)
  new_names <- unname(mapping)
  missing <- old_names[!old_names %in% names(data)]

  if (length(missing) > 0) {
    warning("Columns not found: ", paste(missing, collapse = ", "))
  }

  # Rename using dplyr
  data <- data %>%
    dplyr::rename(!!!setNames(new_names[old_names %in% names(data)],
                              old_names[old_names %in% names(data)]))

  return(data)
}


#' @title Rename Values in Column
#' @description Rename specific values within a column
#' @param data Input data.frame
#' @param col_name Column name
#' @param old_values Vector of old values
#' @param new_values Vector of new values
#' @return data.frame with renamed values
#' @examples
#' \dontrun{
#' # Rename outcome identifiers
#' data <- rename_values(data, "outcome",
#'   old_values = c("Nonalcoholic_steatohepatitis_R11", "Liver_cancer"),
#'   new_values = c("NASH", "HCC")
#' )
#' }
rename_values <- function(data, col_name, old_values, new_values) {

  if (!col_name %in% names(data)) {
    stop("Column '", col_name, "' not found in data")
  }

  if (length(old_values) != length(new_values)) {
    stop("'old_values' and 'new_values' must have the same length")
  }

  # Create mapping
  mapping <- setNames(new_values, old_values)

  # Apply replacement
  data[[col_name]] <- dplyr::recode(data[[col_name]], !!!mapping)

  return(data)
}


#' @title Rename with String Replacement
#' @description Rename using stringr pattern replacement
#' @param data Input data.frame
#' @param col_name Column name to modify
#' @param pattern Pattern to match
#' @param replacement Replacement string
#' @param ... Additional arguments passed to str_replace
#' @return data.frame with renamed column
rename_with_str_replace <- function(data, col_name, pattern, replacement, ...) {

  if (!requireNamespace("stringr", quietly = TRUE)) {
    stop("Package 'stringr' is required")
  }

  if (!col_name %in% names(data)) {
    stop("Column '", col_name, "' not found in data")
  }

  data[[col_name]] <- stringr::str_replace(
    data[[col_name]],
    pattern = pattern,
    replacement = replacement,
    ...
  )

  return(data)
}


#' @title Standardize Column Names
#' @description Standardize column names (lowercase, underscores, etc.)
#' @param data Input data.frame
#' @param style Output style: "snake", "lower", "upper", "title"
#' @return data.frame with standardized column names
standardize_colnames <- function(data, style = "snake") {

  col_names <- names(data)

  new_names <- switch(style,
    "snake" = gsub("([a-z])([A-Z])", "\\1_\\2",
                   gsub("\\s+", "_",
                        gsub("[^a-zA-Z0-9_\\s]", "", col_names))),
    "lower" = tolower(col_names),
    "upper" = toupper(col_names),
    "title" = gsub("\\b([a-z])", "\\U\\1",
                   tolower(col_names), perl = TRUE)
  )

  names(data) <- new_names

  return(data)
}


#' @export
utils::globalVariables(c(
  "rename_with_mapping", "rename_values",
  "rename_with_str_replace", "standardize_colnames"
))
