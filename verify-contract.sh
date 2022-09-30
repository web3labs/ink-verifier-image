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

build_mode=$(json::read '.source.build_info.build_mode')
cargo_contract_version=$(json::read '.source.build_info.cargo_contract_version')
rustc_version=$(json::read '.source.build_info.rustc_version')
optimization_passes=$(json::read '.source.build_info.wasm_opt_settings.optimization_passes')
binaryen_version=$(json::read '.source.build_info.wasm_opt_settings.version')

echo "Build Info

- build_mode: ${build_mode}
- cargo_contract_version: ${cargo_contract_version}
- rustc_version: ${rustc_version}
- optimization_passes: ${optimization_passes}
- binaryen_version: ${binaryen_version}
"

# 5. Install binaryen

BINARYEN_DST="/root/.cache/binaryen/${binaryen_version}"

if [ ! -f "${BINARYEN_DST}/wasm-opt" ]; then
  echo "Installing binaryen ${binaryen_version}"

  mkdir -p $BINARYEN_DST
  curl -s "https://github.com/WebAssembly/binaryen/releases/download/version_${binaryen_version}/binaryen-version_${binaryen_version}-x86_64-linux.tar.gz" -L | tar -xz -C /tmp
  ## TODO checksum...
  mv "/tmp/binaryen-version_${binaryen_version}/bin/wasm-opt" $BINARYEN_DST
fi

# Activate proper wasm-opt version
ln -sfvT "${BINARYEN_DST}/wasm-opt" /usr/local/bin/wasm-opt
wasm-opt --version

# 6. Setup toolchain

echo "RUSTC_WRAPPER=$RUSTC_WRAPPER"

rustup toolchain install "${rustc_version}"
rustup target add wasm32-unknown-unknown --toolchain "${rustc_version}"
rustup component add rust-src --toolchain "${rustc_version}"

# Install dylint-link
cargo install cargo-dylint dylint-link

# Install ink! cargo-contract tool
cargo install "cargo-contract@${cargo_contract_version}"

# 7. Build contract

BUILD_PARAMS="--skip-linting"

if [ $build_mode == "Release" ]; then
  # release is a boolean flag
  BUILD_PARAMS="${BUILD_PARAMS} --release"
fi

BUILD_PARAMS="${BUILD_PARAMS} --optimization-passes ${optimization_passes}"

echo "BUILD_PARAMS=$BUILD_PARAMS"

cd /build/package/src

cargo +"${rustc_version}" contract build ${BUILD_PARAMS}

# 8. Verify against pristine

WASM_FILES=(/build/package/src/target/ink/*.wasm)
WASM_FILE="${WASM_FILES[0]}"

if ! echo "$SHA256_CONTRACT $WASM_FILE" | sha256sum -c -; then
  err $"Target WASM code checksum failed."
fi

echo "
✅ Contract successfully verified 🎉
"

exit 0
