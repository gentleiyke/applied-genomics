#!/usr/bin/env bash

set -euo pipefail

THREADS=4

BAM_DIR="alignment/bam"
COUNTS_DIR="counts"
ANNOT_DIR="reference/annotation"

GTF_GZ="$ANNOT_DIR/Mus_musculus.GRCm39.116.gtf.gz"
GTF="$ANNOT_DIR/Mus_musculus.GRCm39.116.gtf"

FEATURECOUNTS_OUT="$COUNTS_DIR/featurecounts_output.txt"
COUNT_MATRIX="$COUNTS_DIR/count_matrix.tsv"
SUMMARY_OUT="$COUNTS_DIR/featurecounts_output.txt.summary"

mkdir -p "$COUNTS_DIR"

echo "======================================"
echo "Checking input BAM files"
echo "======================================"

shopt -s nullglob
BAM_FILES=( "$BAM_DIR"/*.sorted.bam )
shopt -u nullglob

if (( ${#BAM_FILES[@]} == 0 )); then
    echo "ERROR: No sorted BAM files found in $BAM_DIR"
    echo "Run ./scripts/04_alignment.sh first."
    exit 1
fi

echo "Found ${#BAM_FILES[@]} BAM files."

echo "======================================"
echo "Checking GRCm39.116 annotation file"
echo "======================================"

if [[ -f "$GTF" ]]; then
    echo "Using existing uncompressed GTF: $GTF"
elif [[ -f "$GTF_GZ" ]]; then
    echo "Uncompressing GTF annotation..."
    gunzip -c "$GTF_GZ" > "$GTF"
else
    echo "ERROR: GTF annotation file not found."
    echo "Expected one of:"
    echo "$GTF"
    echo "$GTF_GZ"
    exit 1
fi

echo "======================================"
echo "Running featureCounts"
echo "======================================"

featureCounts \
    -T "$THREADS" \
    -p \
    --countReadPairs \
    -B \
    -C \
    -s 0 \
    -t exon \
    -g gene_id \
    -a "$GTF" \
    -o "$FEATURECOUNTS_OUT" \
    "${BAM_FILES[@]}"

echo "featureCounts complete."

echo "======================================"
echo "Creating simplified count matrix"
echo "======================================"

awk '
BEGIN { OFS="\t" }
NR==1 && /^#/ { next }
NR==2 {
    printf "GeneID"
    for (i=7; i<=NF; i++) {
        sample=$i
        gsub(".*/", "", sample)
        gsub(".sorted.bam", "", sample)
        printf OFS sample
    }
    printf "\n"
    next
}
NR>2 {
    printf $1
    for (i=7; i<=NF; i++) {
        printf OFS $i
    }
    printf "\n"
}
' "$FEATURECOUNTS_OUT" > "$COUNT_MATRIX"

echo "Simplified count matrix created:"
echo "$COUNT_MATRIX"

echo "Summary file created:"
echo "$SUMMARY_OUT"

echo "======================================"
echo "Read counting workflow complete."
echo "======================================"
