#' @title Clean and Compress Data
#' @description Remove specified columns and save as compressed file
#' @param data Input data.frame
#' @param drop_cols Columns to remove (character vector)
#' @param keep_cols Columns to keep (character vector). If provided, drop_cols is ignored
#' @param output_path Output file path. Supports .gz extension for compression
#' @param sep Separator for output file. Default tab
#' @param row.names Remove row names? Default FALSE
#' @param col.names Keep column names? Default TRUE
#' @param quote Quote character? Default FALSE
#' @param na String for missing values. Default "NA"
#' @return Invisible TRUE if successful
#' @examples
#' \dontrun{
#' # Remove specific columns and save as compressed
#' clean_and_compress(data,
#'   drop_cols = c("outcome", "id.outcome", "mr_keep.outcome"),
#'   output_path = "E:/results/cleaned.txt.gz"
#' )
#'
#' # Keep only essential columns
#' clean_and_compress(data,
#'   keep_cols = c("SNP", "chr", "pos", "pval", "beta", "se"),
#'   output_path = "simple_data.txt.gz"
#' )
#' }
clean_and_compress <- function(
    data,
    drop_cols = NULL,
    keep_cols = NULL,
    output_path,
    sep = "\t",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    na = "NA"
) {

  # Determine columns to keep
  if (!is.null(keep_cols)) {
    # Keep specified columns
    cols_to_use <- keep_cols[keep_cols %in% names(data)]
    missing <- keep_cols[!keep_cols %in% names(data)]

    if (length(missing) > 0) {
      warning("Columns not found and skipped: ", paste(missing, collapse = ", "))
    }

    data <- data[, cols_to_use, drop = FALSE]
  } else if (!is.null(drop_cols)) {
    # Drop specified columns
    cols_to_drop <- drop_cols[drop_cols %in% names(data)]
    data <- data[, !names(data) %in% cols_to_drop, drop = FALSE]
  }

  # Create output directory
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Check if output should be compressed
  is_compressed <- grepl("\\.gz$", output_path, ignore.case = TRUE)

  # Write file
  if (is_compressed) {
    con <- gzfile(output_path, "wt")
    write.table(
      data,
      file = con,
      sep = sep,
      row.names = row.names,
      col.names = col.names,
      quote = quote,
      na = na
    )
    close(con)
  } else {
    write.table(
      data,
      file = output_path,
      sep = sep,
      row.names = row.names,
      col.names = col.names,
      quote = quote,
      na = na
    )
  }

  # Report
  file_size <- file.size(output_path) / 1024
  compression <- if (is_compressed) "gzip compressed" else "uncompressed"

  message(sprintf(
    "[%s] Cleaned and saved: %s\n      Dimensions: %d x %d | Size: %.1f KB | Format: %s",
    Sys.time(), output_path, nrow(data), ncol(data), file_size, compression
  ))

  invisible(TRUE)
}


#' @title Quick Clean for GWAS
#' @description Keep only essential GWAS columns and compress
#' @param data Input GWAS data.frame
#' @param output_path Output file path
#' @param chr_col Chromosome column name. Default "chr.outcome"
#' @param pos_col Position column name. Default "pos.outcome"
#' @return Invisible TRUE
quick_clean_gwas <- function(
    data,
    output_path,
    chr_col = "chr.outcome",
    pos_col = "pos.outcome"
) {

  # Essential GWAS columns
  essential_cols <- c(
    "SNP",
    chr_col,
    pos_col,
    "pval.outcome",
    "effect_allele.outcome",
    "other_allele.outcome",
    "beta.outcome",
    "se.outcome"
  )

  # Filter to existing columns
  cols_to_keep <- essential_cols[essential_cols %in% names(data)]

  # Call clean_and_compress
  clean_and_compress(
    data,
    keep_cols = cols_to_keep,
    output_path = output_path
  )
}


#' @title Remove Columns by Pattern
#' @description Remove columns matching a pattern
#' @param data Input data.frame
#' @param pattern Pattern to match (regex)
#' @param ignore.case Case insensitive? Default TRUE
#' @return data.frame with matching columns removed
remove_cols_by_pattern <- function(data, pattern, ignore.case = TRUE) {

  matches <- grep(pattern, names(data), value = TRUE, ignore.case = ignore.case)

  if (length(matches) > 0) {
    message("Removing columns: ", paste(matches, collapse = ", "))
    data <- data[, !names(data) %in% matches]
  }

  return(data)
}


#' @title Subset Columns
#' @description Keep only specified columns
#' @param data Input data.frame
#' @param cols Columns to keep
#' @param warn_missing Warn about missing columns? Default TRUE
#' @return data.frame with specified columns
subset_cols <- function(data, cols, warn_missing = TRUE) {

  existing <- cols[cols %in% names(data)]
  missing <- cols[!cols %in% names(data)]

  if (warn_missing && length(missing) > 0) {
    warning("Columns not found: ", paste(missing, collapse = ", "))
  }

  return(data[, existing, drop = FALSE])
}


#' @title Get Column Statistics
#' @description Get statistics for all columns
#' @param data Input data.frame
#' @return data.frame with column statistics
get_col_stats <- function(data) {

  stats <- data.frame(
    column = names(data),
    class = sapply(data, function(x) class(x)[1]),
    n_unique = sapply(data, function(x) length(unique(x[!is.na(x)]))),
    n_missing = sapply(data, function(x) sum(is.na(x))),
    pct_missing = sapply(data, function(x) round(100 * sum(is.na(x)) / nrow(data), 2)),
    stringsAsFactors = FALSE
  )

  return(stats)
}


#' @export
utils::globalVariables(c(
  "quick_clean_gwas", "remove_cols_by_pattern",
  "subset_cols", "get_col_stats"
))
