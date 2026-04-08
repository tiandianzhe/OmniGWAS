#' @title Export Data to TXT File
#' @description Export data.frame to tab/comma-separated text file
#' @param data Input data.frame
#' @param output_path Output file path (.txt, .tsv, .csv)
#' @param sep Separator. Default tab "\\t"
#' @param row.names Remove row names? Default FALSE
#' @param col.names Keep column names? Default TRUE
#' @param quote Quote strings? Default FALSE
#' @param na String for missing values. Default "NA"
#' @param eol End of line character. Default "\\n"
#' @param create_dir Create output directory if needed? Default TRUE
#' @return Invisible TRUE if successful
#' @examples
#' \dontrun{
#' # Export as tab-separated TXT
#' export_to_txt(data, "E:/results/output.txt")
#'
#' # Export as CSV
#' export_to_txt(data, "results.csv", sep = ",")
#'
#' # Export with quotes around strings
#' export_to_txt(data, "output.txt", quote = TRUE)
#' }
export_to_txt <- function(
    data,
    output_path,
    sep = "\t",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    na = "NA",
    eol = "\n",
    create_dir = TRUE
) {

  # Create output directory
  output_dir <- dirname(output_path)
  if (create_dir && !dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    message("Created directory: ", output_dir)
  }

  # Detect separator from extension if not specified
  if (sep == "\t") {
    if (grepl("\\.csv$", output_path, ignore.case = TRUE)) {
      sep <- ","
    }
  }

  # Write file
  write.table(
    data,
    file = output_path,
    sep = sep,
    row.names = row.names,
    col.names = col.names,
    quote = quote,
    na = na,
    eol = eol
  )

  # Report
  file_size <- file.size(output_path) / 1024
  sep_name <- if (sep == "\t") "tab-separated" else if (sep == ",") "comma-separated" else sep

  message(sprintf(
    "[%s] Exported %d rows x %d cols to: %s (%.1f KB)",
    Sys.time(), nrow(data), ncol(data), output_path, file_size
  ))

  invisible(TRUE)
}


#' @title Export to FUMA Format
#' @description Export data in FUMA GWAS SNP annotation format
#' @param data Input data.frame
#' @param output_path Output file path
#' @param required_cols Required FUMA columns
#' @return Invisible TRUE
#' @examples
#' \dontrun{
#' # Export for FUMA annotation
#' export_for_fuma(data, "E:/mr/liver/HCC/FUMA/VATV_FUMA.txt")
#' }
export_for_fuma <- function(
    data,
    output_path,
    required_cols = c(
      "SNP", "chr.outcome", "pos.outcome", "pval.outcome",
      "effect_allele.outcome", "other_allele.outcome",
      "beta.outcome", "se.outcome"
    )
) {

  # Filter columns
  cols_to_use <- required_cols[required_cols %in% names(data)]
  missing <- required_cols[!required_cols %in% names(data)]

  if (length(missing) > 0) {
    warning("Columns not found in FUMA export: ", paste(missing, collapse = ", "))
  }

  # Subset data
  fuma_data <- data[, cols_to_use, drop = FALSE]

  # Ensure chr column is character
  if ("chr.outcome" %in% names(fuma_data)) {
    fuma_data$chr.outcome <- as.character(fuma_data$chr.outcome)
  }

  # Export
  export_to_txt(
    fuma_data,
    output_path,
    sep = "\t",
    row.names = FALSE,
    col.names = TRUE,
    quote = FALSE,
    na = "NA"
  )

  invisible(TRUE)
}


#' @title Export with Compression
#' @description Export to gzipped text file
#' @param data Input data.frame
#' @param output_path Output file path (.gz)
#' @param compression_level Compression level 1-9. Default 6
#' @param ... Additional arguments passed to write.table
#' @return Invisible TRUE
#' @examples
#' \dontrun{
#' # Export with gzip compression
#' export_gz(data, "results.txt.gz")
#' }
export_gz <- function(
    data,
    output_path,
    compression_level = 6,
    ...
) {

  # Create directory
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Write gzipped file
  con <- gzfile(output_path, "wt", compression = compression_level)

  write.table(
    data,
    file = con,
    ...
  )

  close(con)

  # Report
  file_size <- file.size(output_path) / 1024
  message(sprintf(
    "[%s] Exported and compressed: %s (%.1f KB)",
    Sys.time(), output_path, file_size
  ))

  invisible(TRUE)
}


#' @title Append Data to File
#' @description Append data to existing text file
#' @param data Input data.frame
#' @param file_path File to append to
#' @param sep Separator. Default tab
#' @param ... Additional arguments passed to write.table
#' @return Invisible TRUE
append_to_txt <- function(data, file_path, sep = "\t", ...) {

  write.table(
    data,
    file = file_path,
    sep = sep,
    append = TRUE,
    col.names = FALSE,
    ...
  )

  message("Appended ", nrow(data), " rows to: ", file_path)

  invisible(TRUE)
}


#' @title Batch Export Multiple Data Frames
#' @description Export multiple data frames to separate files
#' @param data_list Named list of data.frames
#' @param output_dir Output directory
#' @param suffix Suffix for filenames
#' @param format Output format: "txt", "csv", "gz"
#' @return Vector of output paths
#' @examples
#' \dontrun{
#' # Batch export
#' files <- batch_export(
#'   list(Summary = sum_data, TopHits = top_hits),
#'   "E:/results/",
#'   format = "gz"
#' )
#' }
batch_export <- function(
    data_list,
    output_dir,
    suffix = "",
    format = "txt"
) {

  # Create directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Determine extension
  ext <- switch(format,
    "txt" = ".txt",
    "csv" = ".csv",
    "gz" = ".txt.gz",
    ".txt"
  )

  # Export each
  paths <- sapply(seq_along(data_list), function(i) {

    name <- if (!is.null(names(data_list))) {
      names(data_list)[i]
    } else {
      paste0("data_", i)
    }

    filename <- paste0(name, suffix, ext)
    output_path <- file.path(output_dir, filename)

    if (format == "gz") {
      export_gz(data_list[[i]], output_path)
    } else {
      export_to_txt(data_list[[i]], output_path)
    }

    return(output_path)
  })

  message(sprintf("[%s] Batch exported %d files to: %s",
                  Sys.time(), length(data_list), output_dir))

  return(paths)
}


#' @export
utils::globalVariables(c(
  "export_for_fuma", "export_gz",
  "append_to_txt", "batch_export"
))
