project_root <- normalizePath(file.path("..", ".."), mustWork = TRUE)
module_root <- file.path(project_root, "analysis", "05_auxiliary_tools")

testthat::test_that("utility functions transform and read small fixtures", {
  source(file.path(module_root, "utils", "R", "read_table.R"), local = TRUE)
  source(file.path(module_root, "utils", "R", "convert_pos.R"), local = TRUE)
  input <- tempfile(fileext = ".tsv")
  writeLines(c("SNP\tPOS", "rs1\t100", "rs2\t200"), input)
  data <- read_data(input, sep = "\t")
  testthat::expect_equal(nrow(data), 2)
  data$POS <- as.character(data$POS)
  converted <- convert_to_numeric(data, "POS", quiet = TRUE)
  testthat::expect_type(converted$POS, "double")
})

testthat::test_that("gsMap batch logic accepts an isolated runner", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  fixture_dir <- tempfile("gsmap-fixture-")
  output_dir <- tempfile("gsmap-output-")
  dir.create(fixture_dir)
  sumstats <- tempfile(fileext = ".tsv")
  writeLines("SNP\tP", sumstats)
  file.create(file.path(fixture_dir, "sample.MOSTA.h5ad"))
  calls <- 0L
  mock_runner <- function(...) {
    calls <<- calls + 1L
    invisible(NULL)
  }
  result <- run_gsmap_batch(
    sample_names = "sample",
    sumstats_file = sumstats,
    trait_name = "trait",
    h5ad_dir = fixture_dir,
    save_base_path = output_dir,
    verbose = FALSE,
    runner = mock_runner
  )
  testthat::expect_equal(calls, 1L)
  testthat::expect_equal(result$success, "sample")
  testthat::expect_true(file.exists(file.path(output_dir, "batch_summary.csv")))
})

testthat::test_that("SMR batch logic accepts an isolated runner", {
  source(
    file.path(module_root, "batch_smr_dynamic", "R", "batch_smr_dynamic.R"),
    local = TRUE
  )
  outcome <- tempfile(fileext = ".rds")
  saveRDS(data.frame(SNP = "rs1"), outcome)
  output_dir <- tempfile("smr-output-")
  calls <- 0L
  mock_runner <- function(...) {
    calls <<- calls + 1L
    invisible(NULL)
  }
  result <- run_smr_dynamic_batch(
    xqtl_resources = "resource_0h",
    out_filename = outcome,
    outcome_name = "trait",
    save_base_path = output_dir,
    verbose = FALSE,
    runner = mock_runner
  )
  testthat::expect_equal(calls, 1L)
  testthat::expect_equal(result$success, "resource_0h")
  testthat::expect_true(file.exists(file.path(output_dir, "smr_batch_summary.csv")))
})

testthat::test_that("gsMap failures are summarized without losing parentheses", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  fixture_dir <- tempfile("gsmap-failure-fixture-")
  output_dir <- tempfile("gsmap-failure-output-")
  dir.create(fixture_dir)
  sumstats <- tempfile(fileext = ".tsv")
  writeLines("SNP\tP", sumstats)
  file.create(file.path(fixture_dir, "sample.MOSTA.h5ad"))
  failing_runner <- function(...) stop("upstream failed (retry exhausted)")
  result <- run_gsmap_batch(
    sample_names = "sample",
    sumstats_file = sumstats,
    trait_name = "trait",
    h5ad_dir = fixture_dir,
    save_base_path = output_dir,
    verbose = FALSE,
    runner = failing_runner
  )
  testthat::expect_equal(result$failed, "sample")
  testthat::expect_equal(result$summary$sample, "sample")
  testthat::expect_equal(result$summary$error_msg, "upstream failed (retry exhausted)")
})

testthat::test_that("SMR failures are summarized without losing parentheses", {
  source(
    file.path(module_root, "batch_smr_dynamic", "R", "batch_smr_dynamic.R"),
    local = TRUE
  )
  outcome <- tempfile(fileext = ".rds")
  saveRDS(data.frame(SNP = "rs1"), outcome)
  output_dir <- tempfile("smr-failure-output-")
  failing_runner <- function(...) stop("upstream failed (retry exhausted)")
  result <- run_smr_dynamic_batch(
    xqtl_resources = "resource_0h",
    out_filename = outcome,
    outcome_name = "trait",
    save_base_path = output_dir,
    verbose = FALSE,
    runner = failing_runner
  )
  testthat::expect_equal(result$failed, "resource_0h")
  testthat::expect_equal(result$summary$resource, "resource_0h")
  testthat::expect_equal(result$summary$error_msg, "upstream failed (retry exhausted)")
})

testthat::test_that("Manhattan pvalue mode uses P when an FDR column is present", {
  source(
    file.path(module_root, "manhattan_plot", "R", "manhattan_plot.R"),
    local = TRUE
  )
  data <- data.frame(
    SNP = c("rs1", "rs2"),
    CHR = c(1, 1),
    BP = c(100, 200),
    P = c(0.01, 0.5),
    FDR = c(0.9, 0.9)
  )
  output <- tempfile(fileext = ".png")
  plot <- create_manhattan_plot(
    data,
    fdr_col = "FDR",
    threshold = 0.05,
    threshold_type = "pvalue",
    output = output,
    base_family = "sans"
  )
  point_layers <- vapply(plot$layers, function(layer) {
    inherits(layer$geom, "GeomPoint")
  }, logical(1))
  significant_layer <- plot$layers[[which(point_layers)[2]]]$data
  testthat::expect_equal(significant_layer$SNP, "rs1")
  testthat::expect_equal(significant_layer$logP, 2)
  testthat::expect_true(file.size(output) > 0)
})

testthat::test_that("Manhattan inputs reject invalid positions and probabilities", {
  source(
    file.path(module_root, "manhattan_plot", "R", "manhattan_plot.R"),
    local = TRUE
  )
  valid <- data.frame(SNP = "rs1", CHR = 1, BP = 100, P = 0.5)
  invalid_bp <- valid
  invalid_bp$BP <- "not-a-position"
  testthat::expect_error(
    create_manhattan_plot(invalid_bp, output = tempfile(fileext = ".png")),
    "BP must contain only finite numeric values"
  )
  invalid_p <- valid
  invalid_p$P <- 1.5
  testthat::expect_error(
    create_manhattan_plot(invalid_p, output = tempfile(fileext = ".png")),
    "interval \\[0, 1\\]"
  )
  invalid_fdr <- valid
  invalid_fdr$FDR <- Inf
  testthat::expect_error(
    create_manhattan_plot(
      invalid_fdr,
      fdr_col = "FDR",
      output = tempfile(fileext = ".png")
    ),
    "FDR must contain only finite numeric values"
  )
})

testthat::test_that("missing gsMap files remain visible in the summary", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  fixture_dir <- tempfile("gsmap-missing-fixture-")
  output_dir <- tempfile("gsmap-missing-output-")
  dir.create(fixture_dir)
  sumstats <- tempfile(fileext = ".tsv")
  writeLines("SNP\tP", sumstats)
  result <- run_gsmap_batch(
    sample_names = "missing",
    sumstats_file = sumstats,
    trait_name = "trait",
    h5ad_dir = fixture_dir,
    save_base_path = output_dir,
    verbose = FALSE,
    runner = function(...) stop("runner should not be called")
  )
  testthat::expect_equal(result$failed, "missing")
  testthat::expect_equal(result$summary$error_msg, "h5ad file not found")

  testthat::expect_error(
    run_gsmap_batch(
      sample_names = "missing",
      sumstats_file = sumstats,
      trait_name = "trait",
      h5ad_dir = fixture_dir,
      save_base_path = output_dir,
      verbose = FALSE,
      stop_on_error = TRUE,
      runner = function(...) stop("runner should not be called")
    ),
    "Stopped on missing h5ad input"
  )
})

testthat::test_that("gsMap sample discovery treats its pattern as a glob", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  fixture_dir <- tempfile("gsmap-discovery-")
  dir.create(fixture_dir)
  file.create(file.path(fixture_dir, c(
    "sample_b.MOSTA.h5ad",
    "sample_a.MOSTA.h5ad",
    "not-a-match.txt"
  )))
  testthat::expect_equal(
    parse_sample_names(fixture_dir),
    c("sample_a", "sample_b")
  )
})

testthat::test_that("batch identifiers cannot escape their output roots", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  source(
    file.path(module_root, "batch_smr_dynamic", "R", "batch_smr_dynamic.R"),
    local = TRUE
  )
  sumstats <- tempfile(fileext = ".tsv")
  writeLines("SNP\tP", sumstats)
  h5ad_dir <- tempfile("h5ad-")
  dir.create(h5ad_dir)
  outcome <- tempfile(fileext = ".rds")
  saveRDS(data.frame(SNP = "rs1"), outcome)
  testthat::expect_error(
    run_gsmap_batch(
      "../outside", sumstats, "trait", h5ad_dir,
      verbose = FALSE, runner = function(...) NULL
    ),
    "path components"
  )
  testthat::expect_error(
    run_smr_dynamic_batch(
      "../outside", outcome, "trait",
      verbose = FALSE, runner = function(...) NULL
    ),
    "path components"
  )
})

testthat::test_that("batch JSON schemas keep scalar counts and array lists", {
  source(file.path(module_root, "batch_gsmap", "R", "batch_gsmap.R"), local = TRUE)
  source(
    file.path(module_root, "batch_smr_dynamic", "R", "batch_smr_dynamic.R"),
    local = TRUE
  )
  output_dir <- tempfile("json-schema-")
  dir.create(output_dir)
  results <- list(
    success = "one",
    failed = character(),
    details = list(one = list(status = "success", output_dir = "out")),
    summary = data.frame(trait = "trait")
  )
  export_batch_results(results, output_dir, format = "json")
  gsmap_json <- jsonlite::fromJSON(
    file.path(output_dir, "batch_results.json"),
    simplifyVector = FALSE
  )
  testthat::expect_type(gsmap_json$success_count, "integer")
  testthat::expect_equal(gsmap_json$success_count, 1L)
  testthat::expect_type(gsmap_json$success_list, "list")
  testthat::expect_equal(gsmap_json$success_list, list("one"))
  testthat::expect_equal(gsmap_json$failed_list, list())

  export_smr_batch_results(results, output_dir, outcome_name = "trait")
  smr_json <- jsonlite::fromJSON(
    file.path(output_dir, "smr_batch_results.json"),
    simplifyVector = FALSE
  )
  testthat::expect_type(smr_json$success_count, "integer")
  testthat::expect_equal(smr_json$success_list, list("one"))
  testthat::expect_equal(smr_json$failed_list, list())
})

testthat::test_that("R and Python document the same dynamic resource catalog", {
  source(
    file.path(module_root, "batch_smr_dynamic", "R", "batch_smr_dynamic.R"),
    local = TRUE
  )
  expected <- c(
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
  testthat::expect_setequal(parse_dynamic_resources(), expected)
  testthat::expect_setequal(
    parse_dynamic_resources(cell_types = "TEMRA"),
    expected[startsWith(expected, "TEMRA_")]
  )
})
