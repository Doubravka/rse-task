#!/usr/bin/env Rscript

library(optparse)
library(flowCore)
library(ggplot2)
library(uwot)

option_list <- list(
  make_option(c("-i", "--input"), type = "character", help = "Input FCS file"),
  make_option(
    c("-o", "--output"),
    type = "character",
    help = "Output FCS file"
  ),
  make_option(c("-p", "--plot"), type = "character", help = "Output plot file"),
  make_option(
    c("-c", "--channels"),
    type = "character",
    default = NULL,
    help = "Channels file (optional)"
  ),
  make_option(
    c("-x", "--exclude"),
    type = "character",
    default = NULL,
    help = "Channel exclusion pattern (regex), for description"
  ),
  make_option(
    c("-s", "--seed"),
    type = "integer",
    default = NULL,
    help = "Random seed for reproducible results (optional)"
  )
)

opt <- parse_args(OptionParser(option_list = option_list))

if (is.null(opt$input) || is.null(opt$output) || is.null(opt$plot)) {
  stop("Input, output and plot parameters must be provided")
}

# Set seed if provided
if (!is.null(opt$seed)) {
  set.seed(opt$seed)
  cat("Using seed:", opt$seed, "\n")
}

flow_frame <- read.FCS(opt$input, transformation = FALSE)
fcs_params <- parameters(flow_frame)

# Channel selection logic
if (!is.null(opt$channels) && file.exists(opt$channels)) {
  # Extract names of channels from FCS input
  fcs_names <- pData(fcs_params)$name
  
  # Read channels file
  channels_df <- read.table(
    opt$channels,
    header = TRUE,
    sep = "\t",
    stringsAsFactors = FALSE
  )
  # Remove quotes from column names if present
  colnames(channels_df) <- gsub('"', "", colnames(channels_df))

  # Get channels to use (where column "use" == 1)
  channels_to_use <- channels_df$name[channels_df$use == 1]
  
  # Find channels which are in the FCS file and the channels file
  matching_channels <- which(fcs_names %in% channels_to_use)
  
  if (length(matching_channels) == 0) {
    stop("No matching channels found between FCS file and channels file")
  }
  
  # Extract expression data for selected channels
  expression_data <- exprs(flow_frame)[, matching_channels, drop = FALSE]
} else {
  fcs_desc <- pData(fcs_params)$desc

  # Select channels based on description
  if (is.null(opt$exclude) || opt$exclude == "") {
    # Use all channels with non empty description
    channels <- which(!is.na(fcs_desc))
  } else {
    # Use non empty channels and exclude by pattern if provided
    channels <- which(
      !is.na(fcs_desc) & !grepl(opt$exclude, fcs_desc, ignore.case = TRUE)
    )
  }

  expression_data <- exprs(flow_frame)[, channels, drop = FALSE]
}

if (ncol(expression_data) <= 1) {
  stop("Expression data must have more than one column for umap analysis.")
}

expression_data_trans <- asinh(expression_data / 5)

umap_res <- umap(expression_data_trans, n_components = 2)
k_means <- kmeans(umap_res, centers = 5)

new_expression_data <- cbind(
  exprs(flow_frame),
  UMAP1 = umap_res[, 1],
  UMAP2 = umap_res[, 2], Cluster = k_means$cluster
)

new_flow_frame <- flowFrame(new_expression_data)

write.FCS(new_flow_frame, filename = opt$output)

df <- data.frame(
  UMAP1 = umap_res[, 1],
  UMAP2 = umap_res[, 2],
  Cluster = factor(k_means$cluster)
)

umap_plot <- ggplot(
  df,
  aes(x = UMAP1, y = UMAP2, color = Cluster)
) + geom_point(size = 0.5) + theme_minimal()

ggsave(opt$plot, plot = umap_plot)
