#!/usr/bin/env bash
set -euo pipefail

# Run Cell Ranger count sequentially for the four rescued 10x GEX libraries.
#
# The script discovers each BaseSpace-generated dataset directory by locating
# the corresponding R1 FASTQ. This avoids hard-coding BaseSpace's random
# dataset suffixes.
#
# Expected Cell Ranger: 10.1.0
# Reference: refdata-gex-GRCh38-2024-A
#
# BAM generation is disabled by default to reduce disk usage.
# Change CREATE_BAM=true if BAM files are required.

REF="/mnt/e/WSL/Linux-Ubuntu/refdata-gex-GRCh38-2024-A"
FASTQ_ROOT="/mnt/e/BaseSpace/Wanessa/02_rescue_I1_7bp"
OUT_ROOT="/mnt/e/BaseSpace/Wanessa/CellRanger_Wanessa"
CREATE_BAM="false"

declare -a SAMPLES=("P11" "DMem" "P11_O" "O")

mkdir -p "$OUT_ROOT"
mkdir -p "${OUT_ROOT}/logs"

echo "=== Environment ==="
echo "Cell Ranger:"
which cellranger
cellranger --version

echo
echo "Reference:"
echo "$REF"

if [[ ! -d "$REF" ]]; then
  echo "ERROR: reference directory not found."
  exit 1
fi

if [[ ! -d "$FASTQ_ROOT" ]]; then
  echo "ERROR: rescued FASTQ root not found: $FASTQ_ROOT"
  exit 1
fi

echo
echo "Hardware:"
echo "CPUs: $(nproc)"
free -h || true
df -h /mnt/e || true
echo

find_sample_r1() {
  local sample="$1"
  find "$FASTQ_ROOT" -type f -name "${sample}_S*_L001_R1_001.fastq.gz" -print
}

for sample in "${SAMPLES[@]}"; do
  mapfile -t R1_MATCHES < <(find_sample_r1 "$sample")

  if [[ "${#R1_MATCHES[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one rescued R1 for $sample; found ${#R1_MATCHES[@]}"
    printf '  %s\n' "${R1_MATCHES[@]:-}"
    exit 1
  fi

  FASTQ_DIR="$(dirname "${R1_MATCHES[0]}")"

  mapfile -t R2_MATCHES < <(
    find "$FASTQ_DIR" -maxdepth 1 -type f \
      -name "${sample}_S*_L001_R2_001.fastq.gz" -print
  )

  if [[ "${#R2_MATCHES[@]}" -ne 1 ]]; then
    echo "ERROR: expected exactly one R2 for $sample in $FASTQ_DIR; found ${#R2_MATCHES[@]}"
    printf '  %s\n' "${R2_MATCHES[@]:-}"
    exit 1
  fi

  echo "============================================================"
  echo "Sample:     $sample"
  echo "R1:         ${R1_MATCHES[0]}"
  echo "R2:         ${R2_MATCHES[0]}"
  echo "FASTQ dir:  $FASTQ_DIR"
  echo "Output:     ${OUT_ROOT}/${sample}"
  echo "============================================================"

  cd "$OUT_ROOT"

  if [[ -d "$sample" ]]; then
    echo "ERROR: output directory already exists: ${OUT_ROOT}/${sample}"
    echo "Cell Ranger will not overwrite an existing --id directory."
    echo "Review it manually before rerunning."
    exit 1
  fi

  cellranger count \
    --id="$sample" \
    --transcriptome="$REF" \
    --fastqs="$FASTQ_DIR" \
    --sample="$sample" \
    --create-bam="$CREATE_BAM" \
    2>&1 | tee "${OUT_ROOT}/logs/${sample}_cellranger.log"

  echo
  echo "Completed: $sample"
  echo "Web summary: ${OUT_ROOT}/${sample}/outs/web_summary.html"
  echo "Metrics:     ${OUT_ROOT}/${sample}/outs/metrics_summary.csv"
  echo
done

echo "All Cell Ranger count jobs completed."
