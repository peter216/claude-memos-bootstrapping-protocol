#!/bin/bash
##
## Reconcile files in a chezmoi-managed directory by running chezmoi re-add.
## Usage: chezmoi_reconcile.sh <directory> [--dry-run]
##

set -euo pipefail

TARGET_DIR="${1:-}"
DRY_RUN=0
[[ "${2:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ -z "$TARGET_DIR" ]]; then
    echo "Error: directory argument is required" >&2
    echo "Usage: $(basename "$0") <directory> [--dry-run]" >&2
    exit 1
fi

if ! command -v chezmoi &> /dev/null; then
    echo "Chezmoi is not in PATH." >&2
    exit 1
fi

filediffs=()
mapfile -t filediffs < <(chezmoi status -x dirs "$TARGET_DIR" | awk '{print $2}')

if [[ ${#filediffs[@]} -eq 0 ]]; then
    echo "No files to reconcile in $TARGET_DIR"
    exit 0
fi

FAIL_FLAG=0
for file in "${filediffs[@]}"; do
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "Would reconcile: $file"
    else
        echo "Reconciling: $file"
        if chezmoi re-add "$file"; then
            echo "Reconcile succeeded: $file"
        else
            echo "Reconcile failed: $file" >&2
            FAIL_FLAG=1
        fi
    fi
done

exit $FAIL_FLAG
