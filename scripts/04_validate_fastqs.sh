#!/usr/bin/env bash
set -euo pipefail

# Validate the rescued FASTQs before Cell Ranger.
#
# Usage:
#   bash 04_validate_fastqs.sh /mnt/e/BaseSpace/Wanessa/02_rescue_I1_7bp

FASTQ_ROOT="${1:-/mnt/e/BaseSpace/Wanessa/02_rescue_I1_7bp}"

declare -a SAMPLES=("P11" "DMem" "P11_O" "O")

if [[ ! -d "$FASTQ_ROOT" ]]; then
  echo "ERROR: FASTQ root does not exist: $FASTQ_ROOT"
  exit 1
fi

echo "FASTQ root: $FASTQ_ROOT"
echo

find_fastq() {
  local sample="$1"
  local read="$2"
  find "$FASTQ_ROOT" -type f -name "${sample}_S*_L001_${read}_001.fastq.gz" -print
}

for sample in "${SAMPLES[@]}"; do
  echo "=== ${sample} ==="

  mapfile -t r1 < <(find_fastq "$sample" "R1")
  mapfile -t r2 < <(find_fastq "$sample" "R2")

  if [[ "${#r1[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one R1 for $sample; found ${#r1[@]}"
    printf '  %s\n' "${r1[@]:-}"
    exit 1
  fi

  if [[ "${#r2[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one R2 for $sample; found ${#r2[@]}"
    printf '  %s\n' "${r2[@]:-}"
    exit 1
  fi

  ls -lh "${r1[0]}" "${r2[0]}"

  echo "Checking gzip integrity for R1..."
  gzip -t "${r1[0]}"

  echo "Checking gzip integrity for R2..."
  gzip -t "${r2[0]}"

  echo "OK: $sample"
  echo
done

echo "=== Undetermined files retained for QC only ==="
find "$FASTQ_ROOT" -type f -name 'Undetermined*.fastq.gz' -print || true

echo
echo "All four rescued sample pairs passed gzip integrity checks."
