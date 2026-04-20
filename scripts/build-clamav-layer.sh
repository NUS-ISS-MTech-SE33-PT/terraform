#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd -- "${SCRIPT_DIR}/.." && pwd)
OUTPUT_DIR="${REPO_ROOT}/environments/prod/lambda/clamav_layer"
OUTPUT_ZIP="${OUTPUT_DIR}/clamav-layer.zip"
BUILD_IMAGE="${CLAMAV_LAYER_BUILD_IMAGE:-amazonlinux:2023}"
PLATFORM="${CLAMAV_LAYER_PLATFORM:-linux/amd64}"
CONTAINER_RUNTIME="${CLAMAV_LAYER_CONTAINER_RUNTIME:-docker}"

if ! command -v "${CONTAINER_RUNTIME}" >/dev/null 2>&1; then
  echo "Container runtime '${CONTAINER_RUNTIME}' is not available." >&2
  exit 1
fi

mkdir -p "${OUTPUT_DIR}"
rm -f "${OUTPUT_ZIP}"

"${CONTAINER_RUNTIME}" run --rm \
  --platform "${PLATFORM}" \
  -v "${OUTPUT_DIR}:/out" \
  "${BUILD_IMAGE}" \
  bash -lc '
    set -euo pipefail

    dnf install -y clamav clamav-update zip findutils

    mkdir -p /layer/bin /layer/lib64 /layer/certs /layer/share/clamav

    cp /usr/bin/clamscan /usr/bin/freshclam /layer/bin/
    cp -Lv /etc/pki/tls/certs/ca-bundle.crt /layer/certs/ca-bundle.crt
    printf "Virus database is downloaded at runtime into /tmp/clamav-db.\n" > /layer/share/clamav/README.txt

    copy_binary_dependencies() {
      local binary="$1"
      ldd "$binary" \
        | awk '\''/=> \// { print $3 } /^\// { print $1 }'\'' \
        | sort -u \
        | while read -r library; do
            [ -n "$library" ] || continue
            cp -Lv "$library" /layer/lib64/
          done
    }

    copy_binary_dependencies /usr/bin/clamscan
    copy_binary_dependencies /usr/bin/freshclam

    cd /layer
    zip -r /out/clamav-layer.zip .
  '

echo "Built ClamAV Lambda layer at ${OUTPUT_ZIP}"
