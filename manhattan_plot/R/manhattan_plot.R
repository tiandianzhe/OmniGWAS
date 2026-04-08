#' ---
#' title: Manhattan Plot Module for GWAS Results Visualization
#' description: Generate publication-ready Manhattan plots from GWAS summary statistics
#' author: WorkBuddy AI Assistant
#' date: 2026-04-08
#' ---

# ============================================
# manhattan_plot.R
# Main function for generating Manhattan plots
# ============================================

#' Install and Load Required Packages
#' @param pkgs Character vector of package names
#' @return NULL (packages are loaded in the environment)
install_and_load <- function(pkgs) {
  for (p in pkgs) {
    if (!requireNamespace(p, quietly = TRUE)) {
      install.packages(p, repos = "https://cloud.r-project.org")
    }
  }
  invisible(lapply(pkgs, library, character.only = TRUE))
}

#' Create Manhattan Plot
#'
#' @param data Data frame with columns: SNP, CHR, BP, P (or FDR)
#' @param pval_col Column name for p-value (default: "P")
#' @param fdr_col Column name for FDR (default: NULL, will calculate from P)
#' @param threshold Significance threshold (default: 5e-8 for GWAS, 0.05 for FDR)
#' @param threshold_type "pvalue" or "fdr" (default: "fdr")
#' @param color_palette Color palette for chromosomes (default: rainbow gradient)
#' @param label_snps Vector of SNP IDs to label (default: significant SNPs)
#' @param genomewideline Add genome-wide significance line (default: TRUE)
#' @param suggestiveline Add suggestive line (default: TRUE)
#' @param title Plot title (default: "Manhattan Plot")
#' @param width Plot width (default: 12)
#' @param height Plot height (default: 6)
#' @param dpi Resolution (default: 300)
#' @param output Output file path (default: "manhattan_plot.png")
#' @param sig_point_color Color for significant points (default: "black")
#' @param sig_point_size Size of significant points (default: 0.8)
#' @param nonsig_point_size Size of non-significant points (default: 0.5)
#' @param label_fontsize Font size for SNP labels (default: 3)
#' @param base_family Font family (default: "Arial")
#' @return ggplot2 object (invisibly)
#' @export
create_manhattan_plot <- function(
    data,
    pval_col = "P",
    fdr_col = NULL,
    threshold = 0.05,
    threshold_type = "fdr",
    color_palette = NULL,
    label_snps = NULL,
    genomewideline = FALSE,
    suggestiveline = TRUE,
    title = "Manhattan Plot",
    width = 12,
    height = 6,
    dpi = 300,
    output = "manhattan_plot.png",
    sig_point_color = "black",
    sig_point_size = 0.8,
    nonsig_point_size = 0.5,
    label_fontsize = 3,
    base_family = "Arial"
) {

  # Install and load required packages
  install_and_load(c("data.table", "dplyr", "ggplot2", "ggrepel", "scales"))

  # Data validation
  required_cols <- c("SNP", "CHR", "BP")
  if (!pval_col %in% names(data) && is.null(fdr_col)) {
    stop("Either pval_col or fdr_col must be present in data")
  }

  # Prepare data
  df <- data.table::as.data.table(data)
  df$CHR <- as.numeric(df$CHR)

  # Calculate -log10(P) or use FDR
  if (!is.null(fdr_col) && fdr_col %in% names(df)) {
    df$FDR <- df[[fdr_col]]
    df$FDR[df$FDR == 0] <- 1e-300
    df$logP <- -log10(df$FDR)
    y_label <- expression(-log[10](FDR))
  } else {
    df$P <- df[[pval_col]]
    df$P[df$P == 0] <- 1e-300
    df$logP <- -log10(df$P)
    y_label <- expression(-log[10](P))
  }

  # Remove NAs and order
  df <- df[!is.na(CHR) & !is.na(BP)]
  df <- df[order(CHR, BP)]

  # Calculate cumulative positions
  chr_info <- df %>%
    dplyr::group_by(CHR) %>%
    dplyr::summarise(chr_len = max(as.numeric(BP), na.rm = TRUE), .groups = "drop") %>%
    dplyr::arrange(CHR) %>%
    dplyr::mutate(chr_start = lag(cumsum(as.numeric(chr_len)), default = 0))

  df <- df %>%
    dplyr::left_join(chr_info, by = "CHR") %>%
    dplyr::mutate(BP_cum = BP + chr_start)

  axis_df <- chr_info %>%
    dplyr::mutate(center = chr_start + chr_len / 2)

  # Determine significance column and threshold
  if (threshold_type == "fdr") {
    sig_col <- "FDR"
    threshold_log <- -log10(threshold)
  } else {
    sig_col <- "P"
    threshold_log <- -log10(threshold)
  }

  # Prepare labels
  if (is.null(label_snps)) {
    label_df <- df[df[[sig_col]] < threshold, ]
  } else {
    label_df <- df[df$SNP %in% label_snps, ]
  }

  # Color palette
  if (is.null(color_palette)) {
    n_chr <- length(unique(df$CHR))
    if (n_chr <= 12) {
      color_palette <- c("#26649A", "#E69F00", "#009E73", "#F0E442",
                         "#0072B2", "#D55E00", "#CC79A7", "#999999",
                         "#56B4E9", "#78D5D7", "#F4A582", "#D1E9C2")
    } else {
      color_palette <- grDevices::colorRampPalette(
        c("#E31A1C", "#FF7F00", "#FDBF6F", "#33A02C",
          "#1F78B4", "#6A3D9A", "#B15928", "#FB9A99",
          "#A6CEE3", "#B2DF8A", "#FFFF00", "#CAB2D6",
          "#FFF68F", "#87CEFA", "#EE82EE", "#8B0000",
          "#006400", "#FFD700", "#4B0082", "#FF1493",
          "#00CED1", "#9400D3")
      )(n_chr)
    }
  }

  # Create plot
  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data$BP_cum, y = .data$logP)) +

    # Non-significant points with chromosome colors
    ggplot2::geom_point(
      data = df[df[[sig_col]] >= threshold, ],
      ggplot2::aes(color = as.factor(.data$CHR)),
      size = nonsig_point_size,
      alpha = 0.8
    ) +

    # Significant points
    ggplot2::geom_point(
      data = df[df[[sig_col]] < threshold, ],
      color = sig_point_color,
      size = sig_point_size,
      alpha = 0.9
    ) +

    # Color scale
    ggplot2::scale_color_manual(values = color_palette, guide = "none") +

    # Threshold line
    ggplot2::geom_hline(
      yintercept = threshold_log,
      linetype = 2,
      linewidth = 0.5,
      color = "#E64B35"
    ) +

    # Labels
    ggrepel::geom_text_repel(
      data = label_df,
      ggplot2::aes(label = .data$SNP),
      size = label_fontsize,
      box.padding = 0.4,
      point.padding = 0.25,
      min.segment.length = 0,
      segment.size = 0.2,
      segment.alpha = 0.6,
      max.overlaps = 50,
      seed = 1
    ) +

    # X-axis
    ggplot2::scale_x_continuous(
      breaks = axis_df$center,
      labels = axis_df$CHR,
      expand = ggplot2::expansion(mult = c(0.01, 0.01))
    ) +

    # Labels and theme
    ggplot2::labs(
      x = "Chromosome",
      y = y_label,
      title = title
    ) +

    ggplot2::theme_classic(base_size = 12, base_family = base_family) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold", size = 14),
      axis.line = ggplot2::element_line(linewidth = 0.4),
      axis.ticks = ggplot2::element_line(linewidth = 0.4),
      axis.text = ggplot2::element_text(color = "black"),
      axis.title = ggplot2::element_text(color = "black"),
      panel.grid.major = ggplot2::element_blank(),
      panel.grid.minor = ggplot2::element_blank()
    )

  # Save plot
  ggplot2::ggsave(
    filename = output,
    plot = p,
    width = width,
    height = height,
    dpi = dpi
  )

  message("Manhattan plot saved to: ", output)
  invisible(p)
}

# ============================================
# QQ Plot Function
# ============================================

#' Create QQ Plot
#'
#' @param data Data frame with p-values
#' @param pval_col Column name for p-values (default: "P")
#' @param title Plot title (default: "Q-Q Plot")
#' @param width Width (default: 6)
#' @param height Height (default: 6)
#' @param output Output file path (default: "qq_plot.png")
#' @param dpi Resolution (default: 300)
#' @return ggplot2 object (invisibly)
#' @export
create_qq_plot <- function(
    data,
    pval_col = "P",
    title = "Q-Q Plot",
    width = 6,
    height = 6,
    output = "qq_plot.png",
    dpi = 300
) {

  install_and_load(c("ggplot2", "data.table"))

  df <- data.table::as.data.table(data)
  pvalues <- df[[pval_col]]
  pvalues <- pvalues[!is.na(pvalues) & pvalues > 0]

  n <- length(pvalues)
  obs_logp <- -log10(sort(pvalues))
  exp_logp <- -log10(ppoints(n))

  plot_data <- data.frame(
    expected = exp_logp,
    observed = obs_logp
  )

  # Calculate lambda (genomic inflation factor)
  lambda <- median(qchisq(pvalues, df = 1, lower.tail = FALSE, log.p = TRUE)) / median(qchisq(0.5, df = 1, lower.tail = FALSE, log.p = TRUE))
  lambda_text <- sprintf("lambda = %.3f", lambda)

  p <- ggplot2::ggplot(plot_data, ggplot2::aes(x = .data$expected, y = .data$observed)) +
    ggplot2::geom_point(alpha = 0.5, size = 1, color = "#2171B5") +
    ggplot2::geom_abline(intercept = 0, slope = 1, linetype = 2, color = "red", linewidth = 0.8) +
    ggplot2::labs(
      x = expression(Expected ~ -log[10](P)),
      y = expression(Observed ~ -log[10](P)),
      title = title
    ) +
    ggplot2::annotate("text", x = max(exp_logp) * 0.1, y = max(obs_logp) * 0.95,
                     label = lambda_text, size = 4, hjust = 0) +
    ggplot2::theme_classic(base_size = 12) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(hjust = 0.5, face = "bold"),
      axis.text = ggplot2::element_text(color = "black"),
      axis.title = ggplot2::element_text(color = "black")
    )

  ggplot2::ggsave(output, p, width = width, height = height, dpi = dpi)
  message("QQ plot saved to: ", output)
  invisible(p)
}

# ============================================
# Batch Processing Function
# ============================================

#' Generate Both Manhattan and QQ Plots
#'
#' @param data Input data frame
#' @param pval_col P-value column name
#' @param fdr_col FDR column name (optional)
#' @param threshold Significance threshold
#' @param threshold_type "pvalue" or "fdr"
#' @param label_snps SNPs to label
#' @param output_dir Output directory
#' @param prefix Output file prefix
#' @return NULL
#' @export
generate_gwas_plots <- function(
    data,
    pval_col = "P",
    fdr_col = NULL,
    threshold = 0.05,
    threshold_type = "fdr",
    label_snps = NULL,
    output_dir = ".",
    prefix = "gwas"
) {

  # Manhattan plot
  manhattan_out <- file.path(output_dir, paste0(prefix, "_manhattan.png"))
  create_manhattan_plot(
    data = data,
    pval_col = pval_col,
    fdr_col = fdr_col,
    threshold = threshold,
    threshold_type = threshold_type,
    label_snps = label_snps,
    output = manhattan_out,
    title = paste(prefix, "Manhattan Plot")
  )

  # QQ plot (if P-values available)
  if (pval_col %in% names(data)) {
    qq_out <- file.path(output_dir, paste0(prefix, "_qq.png"))
    create_qq_plot(
      data = data,
      pval_col = pval_col,
      output = qq_out,
      title = paste(prefix, "Q-Q Plot")
    )
  }

  message("All plots generated successfully!")
}
