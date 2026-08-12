#' @title Batch SMR Dynamic Immune Single-Cell Analysis
#' @description Execute SMR (Summary-based Mendelian Randomization) analysis across
#'              multiple dynamic immune cell populations in batch mode.
#'
#' @author OmniGWAS contributors
#' @version 0.1.0
#'
#' @importFrom utils txtProgressBar setTxtProgressBar

#' Run batch SMR analysis across dynamic immune cell populations
#'
#' @param xqtl_resources Vector of xQTL resource names (e.g., cell types + timepoints)
#' @param out_filename Path to GWAS summary statistics RDS file
#' @param outcome_name Name of the GWAS trait
#' @param xqtl_type Type of xQTL (default: "sc_eqtl")
#' @param save_base_path Base directory for saving results
#' @param pval P-value threshold for SMR (default: 5e-8)
#' @param diff_freq_prop Proportion threshold for differential frequency (default: 0.9)
#' @param diff_freq Frequency difference threshold (default: 0.2)
#' @param ancestry Population ancestry (default: "EUR")
#' @param quick_smr Use quick SMR mode (default: TRUE)
#' @param smr_HEIDI_p HEIDI test P-value threshold (default: 0.05)
#' @param plot_col Plot color (default: "#B4D151")
#' @param plot_highlight.col Highlight color (default: "#8680C0")
#' @param verbose Print progress messages (default: TRUE)
#' @param stop_on_error Stop execution on first error (default: FALSE)
#' @param runner Optional function used to run one resource. Intended for testing.
#'               When NULL, easyGWAS::batch_xqtl_smr is used.
#' @param ... Additional arguments passed to easyGWAS::batch_xqtl_smr
#'
#' @return List with success/failed summaries and detailed results
#'
#' @examples
#' \dontrun{
#' # Define immune cell populations with timepoints
#' xqtl_resources <- c(
#'   "CD4_Memory_stim_16h", "CD4_Memory_stim_40h",
#'   "TN_0h", "TN_16h", "TN_40h",
#'   "TEM_0h", "TEM_16h", "TEM_40h"
#' )
#'
#' result <- run_smr_dynamic_batch(
#'   xqtl_resources = xqtl_resources,
#'   out_filename = "GWAS.rds",
#'   outcome_name = "NAFLD",
#'   save_base_path = "/results/NAFLD/dynamic/"
#' )
#' }
#'
#' @export
run_smr_dynamic_batch <- function(
    xqtl_resources,
    out_filename,
    outcome_name,
    xqtl_type = "sc_eqtl",
    save_base_path = ".",
    pval = 5e-8,
    diff_freq_prop = 0.9,
    diff_freq = 0.2,
    ancestry = "EUR",
    quick_smr = TRUE,
    smr_HEIDI_p = 0.05,
    plot_col = "#B4D151",
    plot_highlight.col = "#8680C0",
    verbose = TRUE,
    stop_on_error = FALSE,
    runner = NULL,
    ...
) {

  # Validate inputs
  if (!file.exists(out_filename)) {
    stop("GWAS file not found: ", out_filename)
  }

  if (!dir.exists(save_base_path)) {
    dir.create(save_base_path, recursive = TRUE)
  }

  if (length(xqtl_resources) == 0) {
    stop("At least one xQTL resource is required")
  }
  if (any(!nzchar(xqtl_resources)) || any(grepl("[/\\\\]", xqtl_resources)) ||
      any(xqtl_resources %in% c(".", ".."))) {
    stop("xQTL resources must be non-empty path components without separators")
  }
  if (anyDuplicated(xqtl_resources)) {
    stop("xQTL resources must be unique")
  }

  if (is.null(runner)) {
    if (!requireNamespace("easyGWAS", quietly = TRUE)) {
      stop(
        "Optional package 'easyGWAS' is required for SMR execution. ",
        "Obtain a compatible version from an authorized source and review its license."
      )
    }
    if (!"batch_xqtl_smr" %in% getNamespaceExports("easyGWAS")) {
      stop("The installed easyGWAS package does not export batch_xqtl_smr")
    }
    runner <- getExportedValue("easyGWAS", "batch_xqtl_smr")
  }

  if (!is.function(runner)) {
    stop("runner must be a function")
  }

  # Initialize tracking
  success_list <- character()
  fail_list <- character()
  result_details <- list()

  n_total <- length(xqtl_resources)

  if (verbose) {
    message("========================================")
    message("Starting batch SMR dynamic immune analysis")
    message(paste0("Total resources: ", n_total))
    message(paste0("Trait: ", outcome_name))
    message(paste0("Output directory: ", save_base_path))
    message("========================================")
    pb <- txtProgressBar(min = 0, max = n_total, style = 3)
  }

  # Process each xQTL resource
  for (i in seq_along(xqtl_resources)) {
    xqtl_resource <- xqtl_resources[i]

    if (verbose) {
      setTxtProgressBar(pb, i - 1)
    }

    # Build output directory for this resource
    resource_path <- file.path(save_base_path, xqtl_resource)

    if (!dir.exists(resource_path)) {
      dir.create(resource_path, recursive = TRUE)
    }

    message(paste0("\n[", i, "/", n_total, "] Processing: ", xqtl_resource))

    attempt <- tryCatch({
      runner(
        out_filename = out_filename,
        id_outcome = NULL,
        outcome_name = outcome_name,
        xqtl_resource = xqtl_resource,
        xqtl_type = xqtl_type,
        smr_multi = FALSE,
        pval = pval,
        diff_freq_prop = diff_freq_prop,
        diff_freq = diff_freq,
        ancestry = ancestry,
        MAF = NULL,
        quick_smr = quick_smr,
        smr_HEIDI_p = smr_HEIDI_p,
        only_gene = FALSE,
        plot_col = plot_col,
        plot_highlight.col = plot_highlight.col,
        save_path = resource_path,
        ...
      )
      list(success = TRUE, output_dir = resource_path)
    }, error = function(e) {
      list(success = FALSE, error = conditionMessage(e))
    })

    if (isTRUE(attempt$success)) {
      if (verbose) {
        message(paste0("[", i, "/", n_total, "] SUCCESS: ", xqtl_resource))
      }
      success_list <- c(success_list, xqtl_resource)
      result_details[[xqtl_resource]] <- list(
        status = "success",
        output_dir = attempt$output_dir
      )
    } else {
      fail_msg <- attempt$error
      if (verbose) {
        message(paste0("[", i, "/", n_total, "] FAIL: ", xqtl_resource,
                       " - ", fail_msg))
      }

      fail_list <- c(fail_list, xqtl_resource)
      result_details[[xqtl_resource]] <- list(
        status = "failed",
        error = fail_msg
      )

      if (stop_on_error) {
        if (verbose) {
          close(pb)
        }
        stop("Stopped on first error at: ", xqtl_resource)
      }
    }

    if (verbose) {
      setTxtProgressBar(pb, i)
    }
  }

  if (verbose) {
    close(pb)
  }

  # Generate summary
  summary_df <- generate_smr_summary(
    success_list = success_list,
    fail_list = fail_list,
    result_details = result_details,
    outcome_name = outcome_name,
    save_base_path = save_base_path
  )

  if (verbose) {
    message("\n========================================")
    message("Batch SMR analysis completed!")
    message(paste0("Success: ", length(success_list), "/", n_total))
    message(paste0("Failed: ", length(fail_list), "/", n_total))
    if (length(fail_list) > 0) {
      message("\nFailed resources:")
      for (f in fail_list) {
        message("  - ", f)
      }
    }
    message(paste0("\nSummary: ", file.path(save_base_path, "smr_batch_summary.csv")))
    message("========================================")
  }

  return(invisible(list(
    success = success_list,
    failed = fail_list,
    details = result_details,
    summary = summary_df
  )))
}


#' Generate batch SMR summary report
#'
#' @param success_list Vector of successful resource names
#' @param fail_list Vector of failed resources with error messages
#' @param result_details Detailed results for each resource
#' @param outcome_name Name of the trait
#' @param save_base_path Directory to save summary
#'
#' @return Data frame of summary results
#'
#' @export
generate_smr_summary <- function(
    success_list,
    fail_list,
    result_details,
    outcome_name,
    save_base_path
) {

  failure_messages <- vapply(fail_list, function(resource) {
    error <- result_details[[resource]]$error
    if (is.null(error) || length(error) == 0) "unknown error" else error
  }, character(1))

  summary_df <- data.frame(
    resource = c(success_list, fail_list),
    status = c(rep("success", length(success_list)),
               rep("failed", length(fail_list))),
    error_msg = c(rep(NA, length(success_list)),
                  failure_messages),
    trait = rep(outcome_name, length(success_list) + length(fail_list)),
    timestamp = rep(Sys.time(), length(success_list) + length(fail_list)),
    stringsAsFactors = FALSE
  )

  # Save summary
  summary_file <- file.path(save_base_path, "smr_batch_summary.csv")
  write.csv(summary_df, summary_file, row.names = FALSE)

  return(summary_df)
}


#' Export stable batch SMR results as JSON
#'
#' @param results Result object returned by run_smr_dynamic_batch
#' @param output_dir Directory in which to write smr_batch_results.json
#' @param outcome_name Name of the outcome trait
#' @export
export_smr_batch_results <- function(results, output_dir, outcome_name) {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Restore dependencies from renv.lock.")
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }
  serialize_detail <- function(detail) {
    serialized <- list(status = jsonlite::unbox(detail$status))
    if (!is.null(detail$output_dir)) {
      serialized$output_dir <- jsonlite::unbox(detail$output_dir)
    }
    if (!is.null(detail$error)) {
      serialized$error <- jsonlite::unbox(detail$error)
    }
    serialized
  }
  details <- lapply(results$details, serialize_detail)
  if (length(details) == 0) {
    details <- structure(list(), names = character())
  }
  payload <- list(
    status = jsonlite::unbox("completed"),
    outcome_name = jsonlite::unbox(outcome_name),
    total_resources = jsonlite::unbox(
      length(results$success) + length(results$failed)
    ),
    success_count = jsonlite::unbox(length(results$success)),
    failed_count = jsonlite::unbox(length(results$failed)),
    success_list = I(unname(results$success)),
    failed_list = I(unname(results$failed)),
    details = details,
    output_dir = jsonlite::unbox(output_dir)
  )
  output_file <- file.path(output_dir, "smr_batch_results.json")
  jsonlite::write_json(payload, output_file, auto_unbox = FALSE, pretty = TRUE)
  invisible(output_file)
}




#' Parse xQTL resources from dynamic immune cell datasets
#'
#' @param dataset Dataset name (default: "dynamic_immune")
#' @param timepoints Vector of timepoints to include (default: c("0h", "16h", "40h", "5d"))
#' @param cell_types Vector of cell types to include (default: all)
#'
#' @return Vector of xQTL resource names
#'
#' @examples
#' \dontrun{
#' resources <- parse_dynamic_resources(timepoints = c("0h", "16h", "40h"))
#' }
#'
#' @export
parse_dynamic_resources <- function(
    dataset = "dynamic_immune",
    timepoints = c("0h", "16h", "40h", "5d"),
    cell_types = NULL
) {
  if (!identical(dataset, "dynamic_immune")) {
    stop("Only the documented 'dynamic_immune' resource catalog is supported")
  }
  resources <- c(
    "CD4_Memory_stim_16h", "CD4_Memory_stim_40h", "CD4_Memory_stim_5d",
    "CD4_Memory_uns_0h", "CD4_Naive_uns_0h", "CD4_Naive_stim_16h",
    "CD4_Naive_stim_40h", "CD4_Naive_stim_5d", "HSP_16h",
    "nTreg_0h", "nTreg_16h", "nTreg_40h", "T_ER-stress_5d",
    "TCM_0h", "TCM_16h", "TCM_40h", "TCM_5d", "TCM_LA",
    "TEM_0h", "TEM_16h", "TEM_40h", "TEM_5d",
    "TEM_HLApositive_40h", "TEM_HLApositive_5d", "TEM_LA",
    "TEMRA_0h", "TEMRA_16h", "TEMRA_40h", "TEMRA_5d", "TEMRA_LA",
    "TM_cycling_5d", "TM_ER-stress_40h", "TN2_40h",
    "TN_0h", "TN_16h", "TN_40h", "TN_5d",
    "TN_cycling_40h", "TN_cycling_5d", "TN_HSP_5d",
    "TN_IFN_16h", "TN_IFN_40h", "TN_IFN_5d", "TN_IFN_LA",
    "TN_LA", "TN_NFKB"
  )

  suffix <- sub("^.*_", "", resources)
  resources <- resources[suffix %in% c(timepoints, "LA", "NFKB")]

  if (!is.null(cell_types)) {
    if (!is.character(cell_types) || length(cell_types) == 0 ||
        any(!nzchar(cell_types))) {
      stop("cell_types must be a non-empty character vector when supplied")
    }
    keep <- vapply(resources, function(resource) {
      any(resource == cell_types | startsWith(resource, paste0(cell_types, "_")))
    }, logical(1))
    resources <- resources[keep]
  }
  sort(resources)
}


#' Consolidate SMR results across dynamic timepoints
#'
#' @param result_dirs Vector of result directories from batch analysis
#' @param output_file Path to save consolidated results
#' @param min_heidi_p Minimum HEIDI test P-value (default: 0.05)
#' @param min_n_snps Minimum number of SNPs (default: 1)
#'
#' @return Data frame of consolidated SMR results
#'
#' @export
consolidate_dynamic_smr <- function(
    result_dirs,
    output_file = NULL,
    min_heidi_p = 0.05,
    min_n_snps = 1
) {

  all_results <- list()

  for (dir in result_dirs) {
    smr_file <- file.path(dir, "smr_results.csv")
    heidi_file <- file.path(dir, "smr_heidi_results.csv")

    if (file.exists(smr_file)) {
      res <- read.csv(smr_file, stringsAsFactors = FALSE)
      res$resource <- basename(dir)
      all_results[[length(all_results) + 1]] <- res
    }
  }

  if (length(all_results) == 0) {
    warning("No SMR results found in provided directories")
    return(NULL)
  }

  # Combine all results
  combined <- do.call(rbind, all_results)

  # Filter by HEIDI and SNP count
  if ("p_HEIDI" %in% names(combined)) {
    combined <- combined[combined$p_HEIDI > min_heidi_p, ]
  }
  if ("n_snps" %in% names(combined)) {
    combined <- combined[combined$n_snps >= min_n_snps, ]
  }

  # Sort by P-value
  if ("p_SMR" %in% names(combined)) {
    combined <- combined[order(combined$p_SMR), ]
  }

  # Save if output specified
  if (!is.null(output_file)) {
    write.csv(combined, output_file, row.names = FALSE)
    message("Consolidated results saved to: ", output_file)
  }

  return(combined)
}


#' Create visualization of dynamic SMR results
#'
#' @param smr_results Consolidated SMR results data frame
#' @param output_file Path to save plot
#' @param cell_type_col Column name for cell type (default: "CellType")
#' @param time_col Column name for timepoint (default: "Timepoint")
#' @param pval_col Column name for P-value (default: "p_SMR")
#'
#' @export
plot_dynamic_smr_heatmap <- function(
    smr_results,
    output_file = "dynamic_smr_heatmap.png",
    cell_type_col = "CellType",
    time_col = "Timepoint",
    pval_col = "p_SMR"
) {

  if (!requireNamespace("ggplot2", quietly = TRUE)) {
    stop("Package 'ggplot2' is required. Restore dependencies from renv.lock.")
  }

  # Transform P-values to -log10
  smr_results$neg_log_pval <- -log10(smr_results[[pval_col]])

  # Create heatmap
  p <- ggplot2::ggplot(smr_results,
                       ggplot2::aes_string(x = time_col,
                                           y = cell_type_col,
                                           fill = "neg_log_pval")) +
    ggplot2::geom_tile() +
    ggplot2::scale_fill_gradient(low = "white", high = "steelblue",
                                 name = "-log10(P-value)") +
    ggplot2::theme_minimal() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 45, hjust = 1)) +
    ggplot2::labs(title = "Dynamic SMR Results Across Immune Cell Populations",
                  x = "Timepoint", y = "Cell Type")

  ggplot2::ggsave(output_file, p, width = 10, height = 8)
  message("Heatmap saved to: ", output_file)
}
