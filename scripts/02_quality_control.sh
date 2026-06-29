#!/usr/bin/env bash

set -euo pipefail
shopt -s nullglob

RAW_DIR="data/raw"
TRIM_DIR="data/trimmed"

RAW_QC_DIR="qc/raw_fastqc"
TRIM_QC_DIR="qc/trimmed_fastqc"
FASTP_REPORT_DIR="qc/fastp"
MULTIQC_DIR="qc/multiqc"

THREADS=4

mkdir -p "$TRIM_DIR" "$RAW_QC_DIR" "$TRIM_QC_DIR" "$FASTP_REPORT_DIR" "$MULTIQC_DIR"

echo "======================================"
echo "Step 1: Running FastQC on raw reads"
echo "======================================"

fastqc "$RAW_DIR"/*.fastq.gz \
    --outdir "$RAW_QC_DIR" \
    --threads "$THREADS"

echo "Raw FastQC complete."

echo "======================================"
echo "Step 2: Running fastp trimming"
echo "======================================"

for R1 in "$RAW_DIR"/*_1.fastq.gz; do
    SAMPLE=$(basename "$R1" _1.fastq.gz)
    R2="$RAW_DIR/${SAMPLE}_2.fastq.gz"

    if [[ ! -f "$R2" ]]; then
        echo "Warning: Missing R2 file for $SAMPLE. Skipping."
        continue
    fi

    echo "Processing $SAMPLE with fastp..."

    fastp \
        -i "$R1" \
        -I "$R2" \
        -o "$TRIM_DIR/${SAMPLE}_1.trimmed.fastq.gz" \
        -O "$TRIM_DIR/${SAMPLE}_2.trimmed.fastq.gz" \
        --detect_adapter_for_pe \
        --thread "$THREADS" \
        -z 9 \
--html "$FASTP_REPORT_DIR/${SAMPLE}_fastp.html" \
        --json "$FASTP_REPORT_DIR/${SAMPLE}_fastp.json"
done

echo "fastp trimming complete."

echo "======================================"
echo "Step 3: Running FastQC on trimmed reads"
echo "======================================"

fastqc "$TRIM_DIR"/*.fastq.gz \
    --outdir "$TRIM_QC_DIR" \
    --threads "$THREADS"

echo "Trimmed FastQC complete."

echo "======================================"
echo "Step 4: Running MultiQC"
echo "======================================"

multiqc qc \
    --outdir "$MULTIQC_DIR" \
    --filename multiqc_report.html \
    --force

echo "MultiQC report created at qc/multiqc/multiqc_report.html"

echo "======================================"
echo "Quality control workflow complete."
echo "Open the MultiQC report with:"
echo "open qc/multiqc/multiqc_report.html"
echo "======================================"
