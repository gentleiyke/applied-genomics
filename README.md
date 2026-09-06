# Mouse Influenza RNA-seq Analysis

A reproducible RNA-seq analysis of mouse cerebellum samples from NCBI GEO/SRA study **GSE96870**, comparing Day 4 Influenza A-infected samples with Day 0 non-infected controls.

## Overview

Five *Mus musculus* cerebellum RNA-seq samples were analysed:

* 3 Day 0 non-infected controls
* 2 Day 4 Influenza A-infected samples

The workflow covers:

`NCBI SRA → FastQC → fastp → MultiQC → HISAT2 → samtools → featureCounts → DESeq2`

Reads were mapped to the *Mus musculus* **GRCm39** reference genome and quantified using the Ensembl release 116 GTF annotation.

## Key Results

All five samples achieved HISAT2 overall alignment rates between **99.37% and 99.46%**.

DESeq2 differential-expression analysis compared:

`Day4_InfluenzaA_Cerebellum` vs `Day0_NonInfected_Cerebellum`

| Metric           | Result |
| ---------------- | -----: |
| Genes tested     | 19,911 |
| Significant DEGs |      2 |
| Upregulated      |      2 |
| Downregulated    |      0 |

Significant DEGs were defined using an adjusted p-value < 0.05 and an absolute log2 fold change >= 1.

## Workflow Structure

```text
mouse-influenza-rnaseq-analysis/
├── data/metadata/           # Sample metadata and SRA accessions
├── scripts/                 # Reproducible Bash and R workflows
├── qc/                      # FastQC, fastp and MultiQC outputs
├── alignment/logs/          # HISAT2 alignment logs and rates
├── counts/                  # featureCounts output and count matrix
├── results/deseq2/          # DESeq2 tables and figures
├── report/                  # Full analysis report
├── environment.yml          # Reproducible Conda environment
└── README.md
```

## Full Analysis Report

A detailed report containing the methods, results, interpretation, limitations and figures is available here:

[RNA-seq Analysis Report](report/RNAseq_analysis_report.md)

## Tools

* NCBI SRA Toolkit
* Conda / Bioconda / conda-forge
* FastQC
* fastp
* MultiQC
* HISAT2
* samtools
* featureCounts / Subread
* R
* DESeq2
* Git / GitHub
* Bash / Unix command line
* Ensembl GRCm39 release 116

## Reproducibility

The analysis scripts are numbered in workflow order:

```text
01_download_data.sh
02_quality_control.sh
03_build_index.sh
04_alignment.sh
05_featurecounts.sh
06_deseq2_analysis.R
```

Large sequencing files, BAM files and reference-genome files are excluded from version control and can be regenerated using the provided metadata, scripts and environment specification.

## Limitations

The analysis contains five samples with an unbalanced 3:2 design. DESeq2 can model unequal replicate numbers, although the small number of infected samples limits statistical power and the biological conclusions that can be drawn from the two significant DEGs.
