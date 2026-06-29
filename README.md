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
