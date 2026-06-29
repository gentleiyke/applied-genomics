#!/usr/bin/env bash

set -euo pipefail

THREADS=2

READ_DIR="data/trimmed"
BAM_DIR="alignment/bam"
LOG_DIR="alignment/logs"
INDEX_BASE="reference/index/grcm39_ensembl116/grcm39_ensembl116"

ANNOTATION_DIR="reference/annotation"
SS_FILE="reference/index/grcm39_ensembl116/grcm39_ensembl116.ss"

mkdir -p "$BAM_DIR" "$LOG_DIR"

echo "Checking HISAT2 index..."

if ! ls "${INDEX_BASE}".*.ht2 1> /dev/null 2>&1; then
    echo "ERROR: HISAT2 index not found at $INDEX_BASE"
    echo "Run ./scripts/03_build_index.sh first."
    exit 1
fi

echo "Checking known splice-sites file for --known-splicesite-infile..."

if [[ ! -s "$SS_FILE" ]]; then
    echo "ERROR: Splice-sites file not found (or empty) at $SS_FILE"
    echo "Expected it alongside your index in reference/index/grcm39_ensembl116/"
    echo "If it lives elsewhere, update SS_FILE in this script."
    exit 1
fi

echo "Found splice-sites file: $SS_FILE"

echo "Checking trimmed FASTQ files..."

shopt -s nullglob
R1_FILES=( "$READ_DIR"/*_1.trimmed.fastq.gz )
shopt -u nullglob

if (( ${#R1_FILES[@]} == 0 )); then
    echo "ERROR: No trimmed R1 FASTQ files found in $READ_DIR"
    echo "Expected files like SRR5364316_1.trimmed.fastq.gz"
    exit 1
fi

echo "Starting HISAT2 alignment..."

for R1 in "${R1_FILES[@]}"; do
    SAMPLE=$(basename "$R1" _1.trimmed.fastq.gz)
    R2="$READ_DIR/${SAMPLE}_2.trimmed.fastq.gz"

    BAM="$BAM_DIR/${SAMPLE}.sorted.bam"
    LOG="$LOG_DIR/${SAMPLE}_hisat2.log"

    if [[ ! -f "$R2" ]]; then
        echo "ERROR: Missing R2 file for $SAMPLE: $R2"
        exit 1
    fi

    if [[ -f "$BAM" && -f "${BAM}.bai" ]]; then
        echo "Sorted BAM and index already exist for $SAMPLE. Skipping."
        continue
    fi

    echo "Aligning $SAMPLE..."

    hisat2 \
        -p "$THREADS" \
        --dta \
        --known-splicesite-infile "$SS_FILE" \
        -x "$INDEX_BASE" \
        -1 "$R1" \
        -2 "$R2" \
        2> "$LOG" \
        | samtools sort -@ "$THREADS" -o "$BAM" -

    samtools index "$BAM"

    echo "$SAMPLE alignment complete."
done

echo "Generating alignment rate tables..."

TSV="$LOG_DIR/alignment_rates.tsv"
MD="$LOG_DIR/alignment_rates.md"

printf "SampleID\tOverallAlignmentRate\tStatus\n" > "$TSV"
printf "| SampleID | Overall alignment rate | Status |\n" > "$MD"
printf "|---|---:|---|\n" >> "$MD"

for LOG in "$LOG_DIR"/*_hisat2.log; do
    SAMPLE=$(basename "$LOG" _hisat2.log)

    RATE=$(grep -oE '[0-9]+\.[0-9]+% overall alignment rate' "$LOG" | grep -oE '^[0-9.]+%' || true)

    if [[ -z "$RATE" ]]; then
        STATUS="ERROR (rate not found)"
        RATE="NA"
    else
        RATE_NUM=${RATE%\%}
        STATUS=$(awk -v rate="$RATE_NUM" 'BEGIN {
            if (rate < 75) print "FLAG (<75%)";
            else print "PASS";
        }')
    fi

    printf "%s\t%s\t%s\n" "$SAMPLE" "$RATE" "$STATUS" >> "$TSV"
    printf "| %s | %s | %s |\n" "$SAMPLE" "$RATE" "$STATUS" >> "$MD"
done

echo "Alignment complete."
echo "Alignment logs are in: $LOG_DIR"
echo "Markdown table created at: $MD"
