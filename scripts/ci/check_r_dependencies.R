#!/usr/bin/env Rscript

analysis_files <- list.files(
  "analysis",
  pattern = "\\.R$",
  recursive = TRUE,
  full.names = TRUE
)
violations <- character()
for (path in analysis_files) {
  lines <- readLines(path, warn = FALSE)
  active <- lines[!grepl("^[[:space:]]*#", lines)]
  if (any(grepl(
    "install\\.packages|install_github|install_local|install_metaxcan",
    active
  ))) {
    violations <- c(violations, path)
  }
}
if (length(violations) > 0) {
  stop("Runtime dependency installation found in: ", paste(violations, collapse = ", "))
}
message("No runtime dependency installation in analysis R examples or modules")
