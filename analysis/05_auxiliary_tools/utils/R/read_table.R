#' @title Read Tabular Data File
#' @description Read data from text/tab-separated files with flexible options
#' @param file_path Path to the input file (supports .txt, .tsv, .gz)
#' @param header Logical: does the file have header row? Default TRUE
#' @param sep Separator character. Options: "auto", "\\t", "\\s+", ","
#' @param na.strings Character vector of strings to be interpreted as NA
#' @param check.names Logical: should column names be syntactically valid? Default FALSE
#' @param stringsAsFactors Logical: convert strings to factors? Default FALSE
#' @param comment.char Character indicating comment lines
#' @param quote Character used for quoting
#' @param dec Decimal separator
#' @param ... Additional arguments passed to read.table
#' @return data.frame
#' @examples
#' \dontrun{
#' # Read tab-separated file
#' data <- read_data("C:/data/results.txt")
#'
#' # Read comma-separated with custom NA strings
#' data <- read_data("data.csv", sep = ",", na.strings = c("NA", " ", "-"))
#'
#' # Read gzipped file
#' data <- read_data("results.txt.gz")
#' }
read_data <- function(
    file_path,
    header = TRUE,
    sep = "auto",
    na.strings = "NA",
    check.names = FALSE,
    stringsAsFactors = FALSE,
    comment.char = "#",
    quote = "",
    dec = ".",
    ...
) {

  # Validate file exists
  if (!file.exists(file_path)) {
    stop("File not found: ", file_path)
  }

  # Detect separator if set to auto
  if (sep == "auto") {
    sep <- detect_separator(file_path)
  }

  # Handle gzipped files
  if (grepl("\\.gz$", file_path, ignore.case = TRUE)) {
    con <- gzfile(file_path, "rt")
    on.exit(close(con), add = TRUE)
    data <- read.table(
      file = con,
      header = header,
      sep = sep,
      na.strings = na.strings,
      check.names = check.names,
      stringsAsFactors = stringsAsFactors,
      comment.char = comment.char,
      quote = quote,
      dec = dec,
      ...
    )
  } else {
    data <- read.table(
      file = file_path,
      header = header,
      sep = sep,
      na.strings = na.strings,
      check.names = check.names,
      stringsAsFactors = stringsAsFactors,
      comment.char = comment.char,
      quote = quote,
      dec = dec,
      ...
    )
  }

  return(data)
}


#' @title Auto-detect Separator
#' @description Automatically detect the separator character in a file
#' @param file_path Path to the file
#' @return Separator character
detect_separator <- function(file_path) {

  # Read first few lines
  lines <- readLines(file_path, n = 5)

  # Count separators
  tab_count <- sum(sapply(lines, function(x) length(gregexpr("\t", x)[[1]])))
  comma_count <- sum(sapply(lines, function(x) length(gregexpr(",", x)[[1]])))
  space_count <- sum(sapply(lines, function(x) length(gregexpr("\\s+", x)[[1]])))

  # Return most common separator
  counts <- c(tab = tab_count, comma = comma_count, space = space_count)
  sep_names <- c("\\t", ",", "\\s+")

  return(sep_names[which.max(counts)])
}


#' @title Read GWAS Summary Statistics
#' @description Specialized reader for GWAS summary statistics files
#' @param file_path Path to GWAS sumstats file
#' @param ... Additional arguments passed to read_data
#' @return data.frame with standardized column names
read_gwas_sumstats <- function(file_path, ...) {

  data <- read_data(file_path, ...)

  # Standardize column names (case-insensitive)
  col_names <- tolower(names(data))
  names(data) <- col_names

  # Return data
  return(data)
}


#' @export
utils::globalVariables(c("detect_separator", "read_gwas_sumstats"))
