#!/usr/bin/env bash
set -eu

PRISTINE_CODE=/build/pristine.wasm

err() {
  printf >&2 "$*\n"
  exit 1
}

# 1. Decompress source tarball

TARGET=/build/package
ARCHIVES=(/build/package.*)
ARCHIVE="${ARCHIVES[0]}"

[[ -f $ARCHIVE ]] || err $"No archive found";
echo "Found archive $ARCHIVE, starting extraction..."

mkdir -p $TARGET
TYPE=$(file $ARCHIVE)
case $TYPE in
  *"gzip"*)  tar xzf "$ARCHIVE" -C "$TARGET";;
  *"bzip2"*) tar xjf "$ARCHIVE" -C "$TARGET";;
  *"Zip"*)   unzip "$ARCHIVE" -d "$TARGET";;
  *)         err $"Format not supported";;
esac

echo "Extraction complete"

# 2. Find contract metadata

CONTRACT_FILES=(/build/package/*.contract)
CONTRACT_FILE="${CONTRACT_FILES[0]}"
[[ -f $CONTRACT_FILE ]] || err $"No .contract file found";

# 3. Verify that WASM matches pristine code on-chain

SHA256_CONTRACT=$(jq -r ".source.wasm" "$CONTRACT_FILE" | xxd -r -p | sha256sum | cut -f 1 -d " ")

if ! echo "$SHA256_CONTRACT $PRISTINE_CODE" | sha256sum -c -; then
  err $"Pristine code checksum failed."
fi

# 4. Parse build info

function json::read() {
  local r=$(jq -r "$1" "$CONTRACT_FILE")
  echo "${r//[^a-zA-Z0-9\.\-_]/}"
}

if ! jq -e '.source | has("build_info")' "$CONTRACT_FILE"; then
  err $"Build info not present in metadata."
fi

BUILD_MODE=$(json::read '.source.build_info.build_mode')
CARGO_CONTRACT_VERSION=$(json::read '.source.build_info.cargo_contract_version')
RUSTC_VERSION=$(json::read '.source.build_info.rustc_version')
OPTIMIZATION_PASSES=$(json::read '.source.build_info.wasm_opt_settings.optimization_passes')
BINARYEN_VERSION=$(json::read '.source.build_info.wasm_opt_settings.version')

# 5. Build

SRC_ROOT=/build/package/src

. /usr/local/bin/build-contract

# 6. Verify against pristine

WASM_FILES=($SRC_ROOT/target/ink/*.wasm)
WASM_FILE="${WASM_FILES[0]}"

if ! echo "$SHA256_CONTRACT $WASM_FILE" | sha256sum -c -; then
  err $"Target WASM code checksum failed."
fi

echo "
✅ Contract successfully verified 🎉
"

exit 0
