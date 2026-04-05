FAIL_FLAG=0
if ! command -v chezmoi &> /dev/null; then
    echo "Chezmoi is not in PATH."
    exit 1
fi
filediffs=()
mapfile -t filediffs < <(chezmoi status -x dirs ~/.claude | awk '{print $2}')
if [[ ${#filediffs[@]} -eq 0 ]]; then
    echo "No files to reconcile"
    exit 0
fi
for file in "${filediffs[@]}"; do
    echo "Reconciling: $file"
    if chezmoi re-add "$file"; then
        echo "Reconciled succeeded: $file"
    else
        echo "Reconcile failed: $file"
        FAIL_FLAG=1
    fi
done
exit $FAIL_FLAG
