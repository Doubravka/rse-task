#!/usr/bin/env Rscript

library(optparse)
library(flowCore)
library(ggplot2)
library(uwot)

option_list <- list(
  make_option(c("-i", "--input"), type="character", help="Input FCS file"),
  make_option(c("-o", "--output"), type="character", help="Output FCS file"),
  make_option(c("-p", "--plot"), type="character", help="Output plot file"),
  make_option(c("-c", "--channels"), type="character", default=NULL, help="Channels file (optional)"),
  make_option(c("-x", "--exclude"), type="character", default=NULL, help="Channel exclusion pattern (regex), for description")
)

opt <- parse_args(OptionParser(option_list=option_list))

if (is.null(opt$input) || is.null(opt$output) || is.null(opt$plot)) {
  stop("Input, output and plot must be provided")
}

ff <- read.FCS(opt$input, transformation = FALSE)
params <- parameters(ff)

# Channel selection logic
if (!is.null(opt$channels) && file.exists(opt$channels)) {
  # Extract names of channels from FCS input
  fcs_names <- pData(params)$name
  
  # Read channels file
  channels_df <- read.table(opt$channels, header=TRUE, sep="\t", stringsAsFactors=FALSE)
  # Remove quotes from column names if present
  colnames(channels_df) <- gsub('"', '', colnames(channels_df))
  
  # Get channels to use (where column "use" == 1)
  channels_to_use <- channels_df$name[channels_df$use == 1]
  
  # Find channels which are in the FCS file and the channels file
  matching_channels <- which(fcs_names %in% channels_to_use)
  
  if (length(matching_channels) == 0) {
    stop("No matching channels found between FCS file and channels file")
  }
  
  # Extract expression data for selected channels
  expr <- exprs(ff)[, matching_channels, drop=FALSE]
} else {
  desc <- pData(params)$desc

  # Use all channels with non empty description or exclude by pattern if provided
  if (is.null(opt$exclude) || opt$exclude == "") {
    channels <- which(!is.na(desc))
  } else {
    channels <- which(!is.na(desc) & !grepl(opt$exclude, desc, ignore.case = TRUE))
  }
  expr <- exprs(ff)[, channels, drop=FALSE]
}

expr_trans <- asinh(expr / 5)

umap_res <- umap(expr_trans, n_components = 2)
km <- kmeans(umap_res, centers = 5)

new_expr <- cbind(exprs(ff), UMAP1=umap_res[,1], UMAP2=umap_res[,2], Cluster=km$cluster)
new_ff <- flowFrame(new_expr)

write.FCS(new_ff, filename = opt$output)

df <- data.frame(UMAP1=umap_res[,1], UMAP2=umap_res[,2], Cluster=factor(km$cluster))
plt <- ggplot(df, aes(x=UMAP1, y=UMAP2, color=Cluster)) + geom_point(size=0.5) + theme_minimal()

ggsave(opt$plot, plot=plt)
