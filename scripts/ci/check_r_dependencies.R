#!/usr/bin/env Rscript

module_files <- list.files(
  file.path("analysis", "05_auxiliary_tools"),
  pattern = "\\.R$",
  recursive = TRUE,
  full.names = TRUE
)
module_files <- module_files[grepl("/R/", module_files, fixed = TRUE)]
violations <- character()
for (path in module_files) {
  lines <- readLines(path, warn = FALSE)
  active <- lines[!grepl("^[[:space:]]*#", lines)]
  if (any(grepl("install\\.packages|install_github|install_local", active))) {
    violations <- c(violations, path)
  }
}
if (length(violations) > 0) {
  stop("Runtime dependency installation found in: ", paste(violations, collapse = ", "))
}
message("No runtime dependency installation in auxiliary R modules")
