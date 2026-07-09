# Applied Genomics

## Name
Ikemefula Oriaku

## Program Title
RNA-seq Project Setup and Version Control

## Project Description
RNA sequencing (RNA-seq) is a next-generation sequencing technique used to capture and quantify RNA molecules in a biological sample. By providing a "snapshot" of the transcriptome at a given time, it reveals exactly which genes are active, how much they are transcribed, and helps identify alternative splicing and gene fusions

## Dataset Description
This project uses five publicly available RNA-seq samples from NCBI GEO/SRA study GSE96870, which investigated transcriptional changes in the central nervous system after upper-respiratory Influenza A infection. The selected samples are from mouse cerebellum and include non-infected Day 0 samples and Influenza A-infected Day 4 samples. The organism is *Mus musculus*. The sequencing type is transcriptomic RNA-seq using Illumina HiSeq 2500 paired-end reads. Raw reads were downloaded from SRA, quality checked with FastQC, trimmed with fastp where needed, and summarized using MultiQC.

## Reference Genome and Alignment
Reads were aligned to the *Mus musculus* GRCm38 reference genome using HISAT2. Alignment was performed on trimmed paired-end FASTQ files, and SAM output was piped directly into sorted BAM files with samtools to reduce disk usage. 

The overall alignment rate for each sample is shown below.

| SampleID | Overall alignment rate | Status |
|---|---:|---|
| SRR5364316 | 99.46% | PASS |
| SRR5364317 | 99.43% | PASS |
| SRR5364318 | 99.37% | PASS |
| SRR5364322 | 99.38% | PASS |
| SRR5364323 | 99.43% | PASS |

## Read Counting
Gene-level read counts were generated from the sorted BAM alignment files using featureCounts from the Subread package. Counts were assigned to exon features and summarised by Ensembl gene ID using the *Mus musculus* GRCm39 Ensembl release 116 GTF annotation. The final count matrix is saved in `counts/count_matrix.tsv`.

## Differential Gene Expression Analysis

Differential gene expression analysis was performed in R using DESeq2. Raw gene-level counts from `counts/count_matrix.tsv` were imported along with the sample metadata file `data/metadata/sample_info.tsv`. Low-count genes were filtered before running DESeq2. The comparison performed was `Day4_InfluenzaA_Cerebellum` versus `Day0_NonInfected_Cerebellum`.

| Comparison | Total genes tested | Significant DEGs | Upregulated | Downregulated |
|---|---:|---:|---:|---:|
| Day4_InfluenzaA_Cerebellum vs Day0_NonInfected_Cerebellum | 19,911 | 2 | 2 | 0 |

Significant DEGs were defined as genes with adjusted p-value < 0.05 and absolute log2 fold change >= 1. A total of 19,911 genes were tested, and 2 significant differentially expressed genes were identified. Both significant DEGs were upregulated in the Day 4 Influenza A cerebellum samples compared with the Day 0 non-infected cerebellum samples. No significant downregulated genes were detected.

The dataset contains an unbalanced design with three Day 0 non-infected control samples and two Day 4 Influenza A-infected samples. All five samples were retained because DESeq2 can model unequal replicate numbers, but the smaller infected group may limit statistical power.

