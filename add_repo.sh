#!/usr/bin/env bash
# Copy one or more GitHub repos into this repo, each as its own folder.
#
# Usage:
#   ./add_repo.sh <repo-url> [<repo-url> ...]
#   ./add_repo.sh https://github.com/campusx-official/langchain-retrievers
#
# Each repo is copied (without its git history) into a folder named after the
# repo, listed in README.md, committed, and pushed to origin.
set -euo pipefail

cd "$(dirname "$0")"

if [ $# -eq 0 ]; then
  echo "Usage: $0 <repo-url> [<repo-url> ...]" >&2
  exit 1
fi

added=0
for url in "$@"; do
  url="${url%/}"
  url="${url%.git}"
  name="$(basename "$url")"

  if [ -e "$name" ]; then
    echo "Skipping $name: folder already exists"
    continue
  fi

  echo "Adding $name from $url"
  tmp="$(mktemp -d)"
  git clone --quiet --depth 1 "$url" "$tmp/$name"
  rm -rf "$tmp/$name/.git"
  mv "$tmp/$name" "$name"
  rm -rf "$tmp"

  echo "- [$name]($name/) — source: $url" >> README.md
  git add "$name" README.md
  git commit --quiet -m "Add $name from $url"
  added=$((added + 1))
done

if [ "$added" -gt 0 ] && git remote get-url origin >/dev/null 2>&1; then
  git push --quiet origin HEAD
  echo "Pushed $added new folder(s)"
fi
