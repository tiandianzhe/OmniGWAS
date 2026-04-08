#' @title Save Data to RDS File
#' @description Save R object to RDS (R Data Serialization) format
#' @param data Input R object (usually data.frame)
#' @param output_path Output file path (.rds)
#' @param compress Compression type: "none", "gzip", "bzip2", "xz". Default "gzip"
#' @param version Version of save format. Default 3
#' @return Invisible TRUE if successful
#' @examples
#' \dontrun{
#' # Save processed data
#' save_to_rds(data, "E:/mr/comorbidity/data.rds")
#'
#' # Save with compression
#' save_to_rds(large_data, "data.rds", compress = "xz")
#' }
save_to_rds <- function(
    data,
    output_path,
    compress = "gzip",
    version = 3
) {

  # Create output directory if needed
  output_dir <- dirname(output_path)
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    message("Created directory: ", output_dir)
  }

  # Save file
  saveRDS(data, file = output_path, compress = compress, version = version)

  # Report
  file_size <- file.size(output_path) / 1024
  obj_size <- object.size(data) / 1024

  message(sprintf(
    "[%s] Saved object to: %s\n      Size on disk: %.1f KB | Object size: %.1f KB",
    Sys.time(), output_path, file_size, obj_size
  ))

  invisible(TRUE)
}


#' @title Load RDS File
#' @description Load R object from RDS file
#' @param input_path Input file path (.rds)
#' @return R object
#' @examples
#' \dontrun{
#' # Load RDS file
#' data <- load_rds("E:/mr/comorbidity/data.rds")
#' }
load_rds <- function(input_path) {

  if (!file.exists(input_path)) {
    stop("File not found: ", input_path)
  }

  data <- readRDS(input_path)

  message(sprintf(
    "[%s] Loaded: %s (%.1f KB)",
    Sys.time(), input_path, file.size(input_path) / 1024
  ))

  return(data)
}


#' @title Save Data to Compressed RDS with Timestamp
#' @description Save with automatic timestamp in filename
#' @param data Input R object
#' @param base_name Base filename without extension
#' @param output_dir Output directory
#' @param prefix Optional prefix for filename
#' @return Path to saved file
#' @examples
#' \dontrun{
#' # Save with timestamp
#' path <- save_with_timestamp(data, "processed_data", "E:/results/")
#' # Creates: E:/results/processed_data_20240101_143022.rds
#' }
save_with_timestamp <- function(
    data,
    base_name,
    output_dir = ".",
    prefix = ""
) {

  # Create directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Generate timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")

  # Build filename
  if (prefix == "") {
    filename <- paste0(base_name, "_", timestamp, ".rds")
  } else {
    filename <- paste0(prefix, "_", base_name, "_", timestamp, ".rds")
  }

  output_path <- file.path(output_dir, filename)

  # Save
  save_to_rds(data, output_path)

  return(output_path)
}


#' @title Batch Save Multiple Objects to RDS
#' @description Save multiple R objects to separate RDS files
#' @param object_list Named list of R objects
#' @param output_dir Output directory
#' @param use_names Use list names as filenames? Default TRUE
#' @return Vector of output file paths
#' @examples
#' \dontrun{
#' # Batch save
#' results <- list(
#'   NASH = nash_data,
#'   NAFLD = nafld_data,
#'   HCC = hcc_data
#' )
#' paths <- batch_save_rds(results, "E:/mr/liver/")
#' }
batch_save_rds <- function(object_list, output_dir, use_names = TRUE) {

  # Create directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  }

  # Save each object
  paths <- sapply(seq_along(object_list), function(i) {

    obj <- object_list[[i]]

    if (use_names && !is.null(names(object_list))) {
      filename <- paste0(names(object_list)[i], ".rds")
    } else {
      filename <- paste0("object_", i, ".rds")
    }

    output_path <- file.path(output_dir, filename)
    save_to_rds(obj, output_path)

    return(output_path)
  })

  message(sprintf("[%s] Saved %d objects to: %s",
                  Sys.time(), length(object_list), output_dir))

  return(paths)
}


#' @export
utils::globalVariables(c(
  "load_rds", "save_with_timestamp", "batch_save_rds"
))
