#!/bin/bash
set -euo pipefail

FORCE=false
if [[ "${1:-}" == "--force" ]]; then
    FORCE=true
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/claude"
TARGET_DIR="$HOME/.claude"

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

echo "Bootstrapping claude dotfiles..."
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
[[ "$FORCE" == true ]] && echo "Force mode: enabled"
echo

find "$SOURCE_DIR" -type f | while read -r file; do
    rel_path="${file#$SOURCE_DIR/}"
    target_file="$TARGET_DIR/$rel_path"
    target_dir="$(dirname "$target_file")"

    if [[ ! -d "$target_dir" ]]; then
        echo "Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi

    if [[ -L "$target_file" ]]; then
        existing_link="$(readlink "$target_file")"
        if [[ "$existing_link" == "$file" ]]; then
            echo "Already linked: $rel_path"
            continue
        else
            echo "Removing stale symlink: $target_file -> $existing_link"
            rm "$target_file"
        fi
    elif [[ -e "$target_file" ]]; then
        if [[ "$FORCE" == true ]]; then
            echo "Removing existing file (--force): $target_file"
            rm "$target_file"
        else
            echo "Warning: $target_file exists and is not a symlink, skipping (use --force to overwrite)"
            continue
        fi
    fi

    echo "Linking: $rel_path"
    ln -s "$file" "$target_file"
done

echo
echo "Done!"
