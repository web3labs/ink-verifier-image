#!/usr/bin/env bash
# ------------------------------------------------------------------
# Builds ink! contract source code and generates a compressed
# archive suitable for uploading to the source code verification service.
# ------------------------------------------------------------------
set -eu

TMP_STAGING="/tmp/.package"

# We pin the root source path to emit stable dir names
# on debug info (to `/build/package/src`).
# When/if cargo-contracts supports adding RUSTC_FLAGS we could
# use 'remap-path-prefix'
mkdir -p "$TMP_STAGING"
cp -r /build/* "$TMP_STAGING"
mkdir -p /build/package
mv "$TMP_STAGING" /build/package/src

# Build contract
SRC_ROOT=/build/package/src
. /usr/local/bin/build-contract

# Build verification package
PACKAGE_DST="/build/target/ink/package.zip"

mkdir -p /build/target/ink/
mv /build/package/src/target/ink /tmp/.ink
mv /tmp/.ink/*.contract /build/package
rm -rf /build/package/src/target
(cd /build/package && zip -r - src/ *.contract) > "$PACKAGE_DST"
rm -rf  /build/package

echo "Verification package in $PACKAGE_DST"
unzip -l "$PACKAGE_DST"
