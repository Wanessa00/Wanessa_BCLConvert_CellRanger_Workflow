#!/usr/bin/env bash
set -euo pipefail

# Install Cell Ranger 10.1.0 without deleting an older installation.
#
# Usage:
#   bash 03_install_cellranger_10.1.sh /path/to/cellranger-10.1.0.tar.xz
#
# Obtain the tarball from the official 10x Genomics download page first.
# The direct download URL is license/session dependent and is not hard-coded.

TARBALL="${1:-}"
INSTALL_ROOT="/mnt/e/WSL/Linux-Ubuntu"
VERSION="10.1.0"
TARGET="${INSTALL_ROOT}/cellranger-${VERSION}"

if [[ -z "$TARBALL" ]]; then
  echo "ERROR: provide the Cell Ranger tarball path."
  echo "Example:"
  echo "  bash $0 /mnt/e/Downloads/cellranger-${VERSION}.tar.xz"
  exit 1
fi

if [[ ! -f "$TARBALL" ]]; then
  echo "ERROR: tarball not found: $TARBALL"
  exit 1
fi

mkdir -p "$INSTALL_ROOT"

if [[ -d "$TARGET" ]]; then
  echo "Cell Ranger ${VERSION} already exists at:"
  echo "  $TARGET"
else
  echo "Extracting $TARBALL into $INSTALL_ROOT"
  tar -xf "$TARBALL" -C "$INSTALL_ROOT"
fi

if [[ ! -x "${TARGET}/cellranger" ]]; then
  echo "ERROR: expected executable not found:"
  echo "  ${TARGET}/cellranger"
  exit 1
fi

echo "Testing installation..."
"${TARGET}/cellranger" --version

EXPORT_LINE="export PATH=${TARGET}:\$PATH"

if ! grep -Fqx "$EXPORT_LINE" "$HOME/.bashrc" 2>/dev/null; then
  echo "$EXPORT_LINE" >> "$HOME/.bashrc"
fi

export PATH="${TARGET}:$PATH"

echo
echo "Active Cell Ranger:"
which cellranger
cellranger --version

echo
echo "Older versions are intentionally preserved."
