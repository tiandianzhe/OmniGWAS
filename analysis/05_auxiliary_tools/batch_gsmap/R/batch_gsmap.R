#' @title Batch gsMap Analysis for Spatial Transcriptomics GWAS Colocalization
#' @description Execute gsMap analysis across multiple spatial transcriptomics samples
#'              in batch mode. Supports parallel processing and comprehensive result logging.
#'
#' @author OmniGWAS contributors
#' @version 0.1.0
#'
#' @importFrom utils txtProgressBar setTxtProgressBar

#' Run gsMap batch analysis for a list of samples
#'
#' @param sample_names Vector of sample names to process
#' @param sumstats_file Path to GWAS summary statistics file (.gz supported)
#' @param trait_name Name of the GWAS trait
#' @param h5ad_dir Directory containing h5ad spatial transcriptomics files
#' @param annotation Annotation type (default: "annotation")
#' @param data_layer Data layer type (default: "count")
#' @param max_processes Maximum number of parallel processes (default: 10)
#' @param save_base_path Base directory for saving results
#' @param verbose Print progress messages (default: TRUE)
#' @param stop_on_error Stop execution on first error (default: FALSE)
#' @param runner Optional function used to run one sample. Intended for testing.
#'               When NULL, easyGWAS::run_gsmap_quick_mode is used.
#'
#' @return List with success and failure summaries
#'
#' @examples
#' \dontrun{
#' sample_names <- c("E9.5_E1S1", "E10.5_E1S1", "E11.5_E1S1")
#' result <- run_gsmap_batch(
#'   sample_names = sample_names,
#'   sumstats_file = "GWAS.sumstats.gz",
#'   trait_name = "NAFLD",
#'   h5ad_dir = "/data/ST/",
#'   save_base_path = "/results/NAFLD/"
#' )
#' }
#'
#' @export
run_gsmap_batch <- function(
    sample_names,
    sumstats_file,
    trait_name,
    h5ad_dir,
    annotation = "annotation",
    data_layer = "count",
    max_processes = 10,
    save_base_path = ".",
    verbose = TRUE,
    stop_on_error = FALSE,
    runner = NULL
) {

  # Validate inputs
  if (!file.exists(sumstats_file)) {
    stop("Summary statistics file not found: ", sumstats_file)
  }

  if (!dir.exists(h5ad_dir)) {
    stop("H5AD directory not found: ", h5ad_dir)
  }

  if (length(sample_names) == 0) {
    stop("At least one sample name is required")
  }
  if (any(!nzchar(sample_names)) || any(grepl("[/\\\\]", sample_names)) ||
      any(sample_names %in% c(".", ".."))) {
    stop("Sample names must be non-empty path components without separators")
  }
  if (anyDuplicated(sample_names)) {
    stop("Sample names must be unique")
  }

  if (is.null(runner)) {
    if (!requireNamespace("easyGWAS", quietly = TRUE)) {
      stop(
        "Optional package 'easyGWAS' is required for gsMap execution. ",
        "Install it explicitly and review its GPL-3.0-or-later license."
      )
    }
    if (!"run_gsmap_quick_mode" %in% getNamespaceExports("easyGWAS")) {
      stop("The installed easyGWAS package does not export run_gsmap_quick_mode")
    }
    runner <- getExportedValue("easyGWAS", "run_gsmap_quick_mode")
  }

  if (!is.function(runner)) {
    stop("runner must be a function")
  }

  if (!dir.exists(save_base_path)) {
    dir.create(save_base_path, recursive = TRUE)
  }

  # Initialize tracking lists
  success_list <- character()
  fail_list <- character()
  result_details <- list()

  # Total samples
  n_total <- length(sample_names)

  if (verbose) {
    message("========================================")
    message(paste0("Starting batch gsMap analysis"))
    message(paste0("Total samples: ", n_total))
    message(paste0("Max parallel processes: ", max_processes))
    message(paste0("Output directory: ", save_base_path))
    message("========================================")
    pb <- txtProgressBar(min = 0, max = n_total, style = 3)
  }

  # Process each sample
  for (i in seq_along(sample_names)) {
    sample_name <- sample_names[i]

    if (verbose) {
      setTxtProgressBar(pb, i - 1)
    }

    # Build h5ad file path
    hdf5_path <- file.path(h5ad_dir, paste0(sample_name, ".MOSTA.h5ad"))

    # Check if h5ad file exists
    if (!file.exists(hdf5_path)) {
      fail_msg <- "h5ad file not found"
      if (verbose) {
        message(paste0("\n[", i, "/", n_total, "] SKIP: ", sample_name,
                       " - ", fail_msg))
      }
      fail_list <- c(fail_list, sample_name)
      result_details[[sample_name]] <- list(
        status = "failed",
        error = fail_msg
      )
      next
    }

    sample_output_dir <- file.path(save_base_path, sample_name)
    if (!dir.exists(sample_output_dir)) {
      dir.create(sample_output_dir, recursive = TRUE)
    }

    attempt <- tryCatch({
      runner(
        sumstats_file = sumstats_file,
        trait_name = trait_name,
        hdf5_path = hdf5_path,
        sample_name = sample_name,
        annotation = annotation,
        data_layer = data_layer,
        max_processes = max_processes,
        save_path = sample_output_dir
      )
      list(success = TRUE, output_dir = sample_output_dir)
    }, error = function(e) {
      list(success = FALSE, error = conditionMessage(e))
    })

    if (isTRUE(attempt$success)) {
      if (verbose) {
        message(paste0("\n[", i, "/", n_total, "] SUCCESS: ", sample_name))
      }
      success_list <- c(success_list, sample_name)
      result_details[[sample_name]] <- list(
        status = "success",
        output_dir = attempt$output_dir
      )
    } else {
      fail_msg <- attempt$error
      if (verbose) {
        message(paste0("\n[", i, "/", n_total, "] FAIL: ", sample_name,
                       " - ", fail_msg))
      }
      fail_list <- c(fail_list, sample_name)
      result_details[[sample_name]] <- list(
        status = "failed",
        error = fail_msg
      )

      if (stop_on_error) {
        if (verbose) {
          close(pb)
        }
        stop("Stopped on first error at sample: ", sample_name)
      }
    }

    if (verbose) {
      setTxtProgressBar(pb, i)
    }
  }

  if (verbose) {
    close(pb)
  }

  # Generate summary report
  summary_report <- generate_batch_summary(
    success_list = success_list,
    fail_list = fail_list,
    result_details = result_details,
    trait_name = trait_name,
    save_base_path = save_base_path
  )

  if (verbose) {
    message("\n========================================")
    message("Batch analysis completed!")
    message(paste0("Success: ", length(success_list), "/", n_total))
    message(paste0("Failed: ", length(fail_list), "/", n_total))
    if (length(fail_list) > 0) {
      message("\nFailed samples:")
      for (f in fail_list) {
        message("  - ", f)
      }
    }
    message(paste0("\nSummary report saved to: ",
                   file.path(save_base_path, "batch_summary.csv")))
    message("========================================")
  }

  return(invisible(list(
    success = success_list,
    failed = fail_list,
    details = result_details,
    summary = summary_report
  )))
}


#' Generate batch summary report
#'
#' @param success_list Vector of successful sample names
#' @param fail_list Vector of failed sample names with error messages
#' @param result_details Detailed results for each sample
#' @param trait_name Name of the trait
#' @param save_base_path Directory to save summary
#'
#' @return Data frame of summary results
#'
#' @export
generate_batch_summary <- function(
    success_list,
    fail_list,
    result_details,
    trait_name,
    save_base_path
) {

  failure_messages <- vapply(fail_list, function(sample_name) {
    error <- result_details[[sample_name]]$error
    if (is.null(error) || length(error) == 0) "unknown error" else error
  }, character(1))

  summary_df <- data.frame(
    sample = c(success_list, fail_list),
    status = c(rep("success", length(success_list)),
               rep("failed", length(fail_list))),
    error_msg = c(rep(NA, length(success_list)),
                  failure_messages),
    stringsAsFactors = FALSE
  )

  # Add timestamp and trait info
  summary_df$trait <- rep(trait_name, nrow(summary_df))
  summary_df$timestamp <- rep(Sys.time(), nrow(summary_df))

  # Save to CSV
  summary_file <- file.path(save_base_path, "batch_summary.csv")
  write.csv(summary_df, summary_file, row.names = FALSE)

  return(summary_df)
}




#' Parse sample names from directory
#'
#' @param h5ad_dir Directory containing h5ad files
#' @param pattern File pattern to match (default: "*.MOSTA.h5ad")
#'
#' @return Vector of sample names (without .MOSTA.h5ad extension)
#'
#' @examples
#' \dontrun{
#' samples <- parse_sample_names("/data/ST/")
#' }
#'
#' @export
parse_sample_names <- function(h5ad_dir, pattern = "*.MOSTA.h5ad") {
  files <- list.files(h5ad_dir, pattern = pattern, full.names = FALSE)
  sample_names <- gsub(pattern, "\\1", gsub("\\.MOSTA\\.h5ad$", "", files))
  return(sample_names)
}


#' Create batch configuration from YAML file
#'
#' @param config_file Path to YAML configuration file
#'
#' @return List of configuration parameters
#'
#' @examples
#' \dontrun{
#' config <- load_batch_config("config.yaml")
#' run_gsmap_batch(sample_names = config$samples, ...)
#' }
#'
#' @export
load_batch_config <- function(config_file) {
  if (!requireNamespace("yaml", quietly = TRUE)) {
    stop("Package 'yaml' is required. Restore dependencies from renv.lock.")
  }
  config <- yaml::read_yaml(config_file)
  return(config)
}


#' Export batch results to structured format
#'
#' @param results Result object from run_gsmap_batch
#' @param output_dir Directory to save exported results
#' @param format Export format: "csv", "json", or "both" (default: "both")
#'
#' @export
export_batch_results <- function(results, output_dir, format = "both") {

  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Export summary
  if (format %in% c("csv", "both")) {
    write.csv(results$summary,
              file.path(output_dir, "batch_summary.csv"),
              row.names = FALSE)
  }

  if (format %in% c("json", "both")) {
    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required. Restore dependencies from renv.lock.")
    }
    json_results <- list(
      trait = results$summary$trait[1],
      total_samples = length(results$success) + length(results$failed),
      success_count = length(results$success),
      failed_count = length(results$failed),
      success_list = results$success,
      failed_list = results$failed,
      details = results$details,
      timestamp = as.character(Sys.time())
    )
    jsonlite::write_json(json_results,
                         file.path(output_dir, "batch_results.json"),
                         pretty = TRUE)
  }

  message("Results exported to: ", output_dir)
}
