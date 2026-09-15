#!/usr/bin/env bash
# Mirror Istio images from Docker Hub to another registry (GHCR).
#
# Usage: mirror.sh <destination-hub> [version...]
#   Versions default to the entries in tags.txt.
#   Each version is mirrored as <version> and <version>-distroless.
#
# Requires crane (github.com/google/go-containerregistry) logged in to the
# destination registry.
set -euo pipefail

SOURCE_HUB="${SOURCE_HUB:-docker.io/istio}"
IMAGES=(pilot proxyv2)
VARIANTS=("" "-distroless")

dest_hub="${1:?usage: $0 <destination-hub> [version...]}"
shift

versions=()
if [[ $# -gt 0 ]]; then
  versions=("$@")
else
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"
    line="${line//[[:space:]]/}"
    [[ -n "$line" ]] && versions+=("$line")
  done < "$(dirname "$0")/tags.txt"
fi

if [[ ${#versions[@]} -eq 0 ]]; then
  echo "no versions to mirror" >&2
  exit 1
fi

failed=()
for version in "${versions[@]}"; do
  for image in "${IMAGES[@]}"; do
    for variant in "${VARIANTS[@]}"; do
      tag="${version}${variant}"
      src="${SOURCE_HUB}/${image}:${tag}"
      dst="${dest_hub}/${image}:${tag}"

      # HEAD requests don't count against the Docker Hub pull rate limit, so
      # comparing digests first keeps re-runs from spending pulls.
      if ! src_digest="$(crane digest "$src")"; then
        echo "::error::cannot resolve ${src}"
        failed+=("$src")
        continue
      fi
      if [[ "$(crane digest "$dst" 2>/dev/null || true)" == "$src_digest" ]]; then
        echo "skip ${dst} (already ${src_digest})"
        continue
      fi

      echo "copy ${src} -> ${dst}"
      if ! crane copy "$src" "$dst"; then
        echo "::error::failed to copy ${src}"
        failed+=("$src")
        continue
      fi
      if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
        echo "- \`${dst}\` (${src_digest})" >> "$GITHUB_STEP_SUMMARY"
      fi
    done
  done
done

if [[ ${#failed[@]} -gt 0 ]]; then
  printf 'failed to mirror:\n' >&2
  printf '  %s\n' "${failed[@]}" >&2
  exit 1
fi
