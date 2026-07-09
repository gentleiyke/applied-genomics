#!/usr/bin/env Rscript

# Differential Gene Expression Analysis with DESeq2

suppressPackageStartupMessages({
  library(DESeq2)
  library(tidyverse)
  library(pheatmap)
})

# Set file paths

count_file <- "counts/count_matrix.tsv"
metadata_file <- "data/metadata/sample_info.tsv"

out_dir <- "results/deseq2"
plot_dir <- file.path(out_dir, "plots")

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(plot_dir, recursive = TRUE, showWarnings = FALSE)

# Import count matrix

counts <- read.delim(
  count_file,
  row.names = 1,
  check.names = FALSE
)

metadata <- read.delim(
  metadata_file,
  check.names = FALSE
)

# Check sample names

if (!"SampleID" %in% colnames(metadata)) {
  stop("metadata file must contain a SampleID column")
}

if (!"Condition" %in% colnames(metadata)) {
  stop("metadata file must contain a Condition column")
}

rownames(metadata) <- metadata$SampleID

# Keep metadata in the same order as count matrix columns
metadata <- metadata[colnames(counts), , drop = FALSE]

if (!all(colnames(counts) == rownames(metadata))) {
  stop("Sample names in count matrix and metadata do not match")
}

# Convert condition to factor
metadata$Condition <- factor(metadata$Condition)

cat("Samples used in analysis:\n")
print(metadata)

cat("\nConditions found:\n")
print(table(metadata$Condition))

# Create DESeq2 object

dds <- DESeqDataSetFromMatrix(
  countData = round(as.matrix(counts)),
  colData = metadata,
  design = ~ Condition
)

# Filter low-count genes
dds <- dds[rowSums(counts(dds)) >= 10, ]

# Run DESeq2

dds <- DESeq(dds)

# Choose comparison

conditions <- levels(metadata$Condition)

if (length(conditions) < 2) {
  stop("Need at least two conditions for differential expression analysis")
}

reference_condition <- "Day0_NonInfected_Cerebellum"
treatment_condition <- "Day4_InfluenzaA_Cerebellum"

if (!reference_condition %in% conditions) {
  stop(paste("Reference condition not found in metadata:", reference_condition))
}

if (!treatment_condition %in% conditions) {
  stop(paste("Treatment condition not found in metadata:", treatment_condition))
}

metadata$Condition <- relevel(metadata$Condition, ref = reference_condition)

cat("\nReference condition:", reference_condition, "\n")
cat("Treatment condition:", treatment_condition, "\n")

res <- results(
  dds,
  contrast = c("Condition", treatment_condition, reference_condition)
)

res <- lfcShrink(
  dds,
  contrast = c("Condition", treatment_condition, reference_condition),
  res = res,
  type = "normal"
)

# Export full results

res_df <- as.data.frame(res) %>%
  rownames_to_column("GeneID") %>%
  arrange(padj)

full_results_file <- file.path(
  out_dir,
  paste0("deseq2_full_results_", treatment_condition, "_vs_", reference_condition, ".tsv")
)

write.table(
  res_df,
  full_results_file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

# Export significant DEGs

sig_res <- res_df %>%
  filter(!is.na(padj)) %>%
  filter(padj < 0.05, abs(log2FoldChange) >= 1) %>%
  mutate(Direction = ifelse(log2FoldChange > 0, "Up", "Down"))

sig_results_file <- file.path(
  out_dir,
  paste0("significant_DEGs_", treatment_condition, "_vs_", reference_condition, ".tsv")
)

write.table(
  sig_res,
  sig_results_file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

# Export VST-normalized counts

vsd <- vst(dds, blind = FALSE)

vst_counts <- assay(vsd) %>%
  as.data.frame() %>%
  rownames_to_column("GeneID")

vst_file <- file.path(out_dir, "vst_normalized_counts.tsv")

write.table(
  vst_counts,
  vst_file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

# DEG summary

total_genes_tested <- sum(!is.na(res_df$padj))
sig_deg_count <- nrow(sig_res)
up_count <- sum(sig_res$Direction == "Up")
down_count <- sum(sig_res$Direction == "Down")

summary_df <- data.frame(
  Comparison = paste0(treatment_condition, "_vs_", reference_condition),
  TotalGenesTested = total_genes_tested,
  SignificantDEGs = sig_deg_count,
  Upregulated = up_count,
  Downregulated = down_count
)

summary_file <- file.path(out_dir, "deg_summary.tsv")

write.table(
  summary_df,
  summary_file,
  sep = "\t",
  quote = FALSE,
  row.names = FALSE
)

print(summary_df)

# PCA plot

pca_file <- file.path(plot_dir, "pca_plot.png")

png(pca_file, width = 900, height = 700)
print(plotPCA(vsd, intgroup = "Condition"))
dev.off()

# MA plot

ma_file <- file.path(
  plot_dir,
  paste0("ma_plot_", treatment_condition, "_vs_", reference_condition, ".png")
)

png(ma_file, width = 900, height = 700)
plotMA(res, ylim = c(-5, 5), main = paste(treatment_condition, "vs", reference_condition))
dev.off()

# Volcano plot

volcano_df <- res_df %>%
  mutate(
    Significant = ifelse(!is.na(padj) & padj < 0.05 & abs(log2FoldChange) >= 1, "Significant", "Not significant")
  )

volcano_file <- file.path(
  plot_dir,
  paste0("volcano_plot_", treatment_condition, "_vs_", reference_condition, ".png")
)

volcano_plot <- ggplot(
  volcano_df,
  aes(x = log2FoldChange, y = -log10(padj), color = Significant)
) +
  geom_point(alpha = 0.6, size = 1.5) +
  theme_minimal() +
  labs(
    title = paste("Volcano Plot:", treatment_condition, "vs", reference_condition),
    x = "log2 Fold Change",
    y = "-log10 adjusted p-value"
  )

ggsave(volcano_file, volcano_plot, width = 8, height = 6)

# Heatmap of top genes

if (nrow(sig_res) >= 2) {
  top_genes <- sig_res %>%
    arrange(padj) %>%
    slice_head(n = min(30, nrow(sig_res))) %>%
    pull(GeneID)

  heatmap_mat <- assay(vsd)[top_genes, , drop = FALSE]
  heatmap_mat <- heatmap_mat - rowMeans(heatmap_mat)

  heatmap_file <- file.path(
    plot_dir,
    paste0("heatmap_top_DEGs_", treatment_condition, "_vs_", reference_condition, ".png")
  )

  png(heatmap_file, width = 900, height = 800)
  pheatmap(
    heatmap_mat,
    annotation_col = metadata["Condition"],
    show_rownames = FALSE,
    main = "Top Significant DEGs"
  )
  dev.off()
}

cat("\nDESeq2 analysis complete.\n")
cat("Full results:", full_results_file, "\n")
cat("Significant DEGs:", sig_results_file, "\n")
cat("VST-normalized counts:", vst_file, "\n")
cat("DEG summary:", summary_file, "\n")
