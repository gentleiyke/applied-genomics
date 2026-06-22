#!/usr/bin/env bash

set -euo pipefail

ACCESSIONS="data/metadata/SRR_accessions.txt"
RAW_DIR="data/raw"
SRA_DIR="data/sra"
TMP_DIR="tmp/fasterq"

mkdir -p "$RAW_DIR" "$SRA_DIR" "$TMP_DIR"

echo "Starting SRA download..."

while read -r SRR; do
    [[ -z "$SRR" ]] && continue

    SINGLE_GZ="$RAW_DIR/${SRR}.fastq.gz"
    SINGLE_SPLIT_GZ="$RAW_DIR/${SRR}_1.fastq.gz"
    PAIRED_1_GZ="$RAW_DIR/${SRR}_1.fastq.gz"
    PAIRED_2_GZ="$RAW_DIR/${SRR}_2.fastq.gz"

    echo "Checking existing FASTQ files for $SRR..."

    if [[ -f "$PAIRED_1_GZ" && -f "$PAIRED_2_GZ" ]]; then
        echo "Found paired-end compressed FASTQ files for $SRR. Skipping download/conversion."
        rm -rf "$SRA_DIR/$SRR" "$TMP_DIR"/*
        continue
    fi

    if [[ -f "$SINGLE_GZ" || -f "$SINGLE_SPLIT_GZ" ]]; then
        echo "Found single-end compressed FASTQ file for $SRR. Skipping download/conversion."
        rm -rf "$SRA_DIR/$SRR" "$TMP_DIR"/*
        continue
    fi

    echo "Downloading $SRR with prefetch..."
    prefetch "$SRR" --output-directory "$SRA_DIR"

    SRA_FILE="$SRA_DIR/$SRR/$SRR.sra"

    if [[ ! -f "$SRA_FILE" ]]; then
        echo "ERROR: Expected SRA file not found: $SRA_FILE"
        exit 1
    fi

    echo "Converting $SRR to FASTQ..."
    fasterq-dump "$SRA_FILE" \
        --split-files \
        --threads 2 \
        --outdir "$RAW_DIR" \
        --temp "$TMP_DIR" \
        --size-check off

    echo "Compressing FASTQ files for $SRR..."

    shopt -s nullglob
    FASTQ_FILES=( "$RAW_DIR/${SRR}"*.fastq )
    shopt -u nullglob

    if (( ${#FASTQ_FILES[@]} == 0 )); then
        echo "ERROR: No FASTQ files were created for $SRR"
        exit 1
    fi

    gzip -f "${FASTQ_FILES[@]}"

    echo "Checking compressed FASTQ output for $SRR..."

    if [[ -f "$PAIRED_1_GZ" && -f "$PAIRED_2_GZ" ]]; then
        echo "Confirmed paired-end gzip output for $SRR."
        echo "Deleting SRA file for $SRR to save space..."
        rm -rf "$SRA_DIR/$SRR"
    elif [[ -f "$SINGLE_GZ" || -f "$SINGLE_SPLIT_GZ" ]]; then
        echo "Confirmed single-end gzip output for $SRR."
        echo "Deleting SRA file for $SRR to save space..."
        rm -rf "$SRA_DIR/$SRR"
    else
        echo "ERROR: Compressed FASTQ files not found after gzip for $SRR"
        echo "Keeping SRA file for safety: $SRA_FILE"
        exit 1
    fi

    echo "Cleaning temporary files for $SRR..."
    rm -rf "$TMP_DIR"/*

done < "$ACCESSIONS"

echo "Download and FASTQ conversion complete."
