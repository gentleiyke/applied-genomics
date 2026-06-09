#!/bin/bash

# Create main project folders
mkdir -p environment
mkdir -p data/raw
mkdir -p data/trimmed
mkdir -p data/metadata
mkdir -p reference/genome
mkdir -p reference/annotation
mkdir -p reference/index
mkdir -p qc/raw_fastqc
mkdir -p qc/trimmed_fastqc
mkdir -p alignment/sam
mkdir -p alignment/bam
mkdir -p alignment/logs
mkdir -p counts
mkdir -p scripts

# Create placeholder files
touch environment/install_tools.sh
touch data/metadata/sample_info.tsv
touch data/metadata/SRR_accessions.txt
touch counts/featurecounts_output.txt
touch counts/count_matrix.tsv
touch scripts/01_download_data.sh
touch scripts/02_quality_control.sh
touch scripts/03_build_index.sh
touch scripts/04_alignment.sh
touch scripts/05_featurecounts.sh

echo "Project folder structure created successfully."

