#!/usr/bin/env bash
#
# dataset_preparation_pipeline.sh
# ------------------------------------------------------------
# Automates dataset preparation for machine learning projects.
# Features:
#   Random train/val/test split
#   Resize with ImageMagick
#   Move/copy mode
#   Normalizes filenames (spaces → underscores)
#   Generates dataset_summary.txt
#
# Usage:
#   ./dataset-prep-pipeline.sh --input raw_data --output data --split "70 15 15" --resize 256x256 --copy
# ------------------------------------------------------------

set -euo pipefail

# Default Parameters
SPLIT="70 15 15"
RESIZE=""
MODE="copy"
INPUT_DIR=""
OUTPUT_DIR="data"
LOGFILE="dataset_prep.log"

# Functions 
show_help() {
cat << EOF
Usage: ${0##*/} [OPTIONS]

Options:
  --input DIR         /Paste the file path/cifar-10-batches-py
  --output DIR        Output directory for processed dataset [default: ./data]
  --split "A B C"     Train/Val/Test split ratios [default: 70 15 15]
  --resize WxH        Resize images to given dimensions using ImageMagick (optional)
  --copy              Copy files instead of moving (default)
  --move              Move files instead of copying
  -h, --help          Show this help message and exit

Example:
  ./dataset-prep-pipeline.sh --input ./raw_images --output ./data --split "70 15 15" --resize 256x256 --copy
EOF
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

normalize_filenames() {
    find "$1" -type f | while read -r file; do
        new_file="$(echo "$file" | tr ' ' '_' | tr -d '()[]{}')"
        if [[ "$file" != "$new_file" ]]; then
            mv "$file" "$new_file"
        fi
    done
}

resize_images() {
    if [[ -n "$RESIZE" ]]; then
        log "Resizing images to $RESIZE ..."
        find "$1" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) -exec mogrify -resize "$RESIZE" "{}" \;
    fi
}

split_dataset() {
    local src_dir="$1"
    local dst_dir="$2"
    local split=($SPLIT)
    local total=$(find "$src_dir" -type f | wc -l)
    local train_count=$((total * split[0] / 100))
    local val_count=$((total * split[1] / 100))
    local test_count=$((total - train_count - val_count))

    log "Total images: $total | Train: $train_count | Val: $val_count | Test: $test_count"

    mkdir -p "$dst_dir"/{train,val,test}

    find "$src_dir" -type f | shuf | awk -v t=$train_count -v v=$val_count -v mode="$MODE" -v dst="$dst_dir" '
    {
        if (NR <= t) subset = "train"
        else if (NR <= t+v) subset = "val"
        else subset = "test"

        cmd = (mode == "move" ? "mv" : "cp")
        system(cmd " \"" $0 "\" \"" dst "/" subset "/\"")
    }'
}

generate_summary() {
    local dir="$1"
    local summary_file="$dir/dataset_summary.txt"

    echo "Dataset Summary - Generated $(date)" > "$summary_file"
    echo >> "$summary_file"
    for subset in train val test; do
        count=$(find "$dir/$subset" -type f | wc -l)
        echo "$subset: $count images" >> "$summary_file"
    done
    echo  >> "$summary_file"
    echo "Mean image dimensions:" >> "$summary_file"
    identify -format "%w %h\n" "$dir"/train/* 2>/dev/null | \
        awk '{w+=$1; h+=$2; n++} END {if(n>0) printf "Width: %.1f, Height: %.1f\n", w/n, h/n; else print "N/A"}' >> "$summary_file"

    log "Summary written to $summary_file"
}

# Parse Arguments 
while [[ $# -gt 0 ]]; do
    case "$1" in
        --input)  INPUT_DIR="$2"; shift 2 ;;
        --output) OUTPUT_DIR="$2"; shift 2 ;;
        --split)  SPLIT="$2"; shift 2 ;;
        --resize) RESIZE="$2"; shift 2 ;;
        --copy)   MODE="copy"; shift ;;
        --move)   MODE="move"; shift ;;
        -h|--help) show_help; exit 0 ;;
        *) echo "Unknown option: $1"; show_help; exit 1 ;;
    esac
done

# Main 
if [[ -z "$INPUT_DIR" ]]; then
    echo "Error: --input directory required."
    show_help
    exit 1
fi

log "Starting dataset preparation pipeline..."
log "Input: $INPUT_DIR | Output: $OUTPUT_DIR | Split: $SPLIT | Resize: ${RESIZE:-none} | Mode: $MODE"

mkdir -p "$OUTPUT_DIR"

log "Normalizing filenames..."
normalize_filenames "$INPUT_DIR"

split_dataset "$INPUT_DIR" "$OUTPUT_DIR"

resize_images "$OUTPUT_DIR/train"
resize_images "$OUTPUT_DIR/val"
resize_images "$OUTPUT_DIR/test"

generate_summary "$OUTPUT_DIR"

log " Dataset preparation completed successfully!"