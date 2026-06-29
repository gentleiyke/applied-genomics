#!/usr/bin/env bash

set -euo pipefail

THREADS=2

GENOME_DIR="reference/genome"
ANNOT_DIR="reference/annotation"
INDEX_DIR="reference/index/grcm39_ensembl116"

mkdir -p "$GENOME_DIR" "$ANNOT_DIR" "$INDEX_DIR"

FASTA_GZ="$GENOME_DIR/Mus_musculus.GRCm39.dna.primary_assembly.fa.gz"
GTF_GZ="$ANNOT_DIR/Mus_musculus.GRCm39.116.gtf.gz"

FASTA="$GENOME_DIR/Mus_musculus.GRCm39.dna.primary_assembly.fa"
GTF="$ANNOT_DIR/Mus_musculus.GRCm39.116.gtf"

INDEX_BASE="$INDEX_DIR/grcm39_ensembl116"
SS_FILE="${INDEX_BASE}.ss"
EXON_FILE="${INDEX_BASE}.exon"

echo "Downloading Ensembl GRCm39 reference genome and GTF annotation..."

if [[ ! -f "$FASTA_GZ" ]]; then
    wget -c -O "$FASTA_GZ" \
    "https://ftp.ensembl.org/pub/release-116/fasta/mus_musculus/dna/Mus_musculus.GRCm39.dna.primary_assembly.fa.gz"
fi

if [[ ! -f "$GTF_GZ" ]]; then
    wget -c -O "$GTF_GZ" \
    "https://ftp.ensembl.org/pub/release-116/gtf/mus_musculus/Mus_musculus.GRCm39.116.gtf.gz"
fi

echo "Uncompressing reference files..."

if [[ ! -f "$FASTA" ]]; then
    gunzip -c "$FASTA_GZ" > "$FASTA"
fi

if [[ ! -f "$GTF" ]]; then
    gunzip -c "$GTF_GZ" > "$GTF"
fi

echo "Checking if HISAT2 index already exists..."

if ls "${INDEX_BASE}".*.ht2 1> /dev/null 2>&1; then
    echo "HISAT2 index already exists. Skipping index build."
else
    echo "Extracting splice sites and exons from GTF..."

    hisat2_extract_splice_sites.py "$GTF" > "$SS_FILE"
    hisat2_extract_exons.py "$GTF" > "$EXON_FILE"

    echo "Building HISAT2 index..."

    hisat2-build \
        -p "$THREADS" \
        "$FASTA" \
        "$INDEX_BASE"
fi

echo "Cleaning uncompressed reference files to save disk space..."
rm -f "$FASTA" "$GTF"

echo "HISAT2 index build complete."
echo "Index base: $INDEX_BASE"
