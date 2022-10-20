#!/usr/bin/env bash
set -eu

build_mode=${BUILD_MODE:-Release}
cargo_contract_version=${CARGO_CONTRACT_VERSION:-1.4.0}
rustc_version=${RUSTC_VERSION:-nightly-2022-07-25}
optimization_passes=${OPTIMIZATION_PASSES:-Z}
binaryen_version=${BINARYEN_VERSION:-109}

echo "Build Info

- build_mode: ${build_mode}
- cargo_contract_version: ${cargo_contract_version}
- rustc_version: ${rustc_version}
- optimization_passes: ${optimization_passes}
- binaryen_version: ${binaryen_version}
"

# 1. Install binaryen

BINARYEN_DST="/opt/.cache/binaryen/${binaryen_version}"

if [ ! -f "${BINARYEN_DST}/wasm-opt" ]; then
  echo "Installing binaryen ${binaryen_version}"

  mkdir -p $BINARYEN_DST
  curl -s "https://github.com/WebAssembly/binaryen/releases/download/version_${binaryen_version}/binaryen-version_${binaryen_version}-x86_64-linux.tar.gz" -L | tar -xz -C /tmp
  mv "/tmp/binaryen-version_${binaryen_version}/bin/wasm-opt" $BINARYEN_DST
fi

# Activate proper wasm-opt version
ln -sfvT "${BINARYEN_DST}/wasm-opt" /usr/local/bin/wasm-opt
wasm-opt --version

# 2. Setup toolchain

rustup toolchain install "${rustc_version}"
rustup target add wasm32-unknown-unknown --toolchain "${rustc_version}"
rustup component add rust-src --toolchain "${rustc_version}"

# Install dylint-link
cargo install cargo-dylint dylint-link

# Install ink! cargo-contract tool
cargo install --version "${cargo_contract_version}" cargo-contract

# 3. Build contract

SRC_ROOT="${SRC_ROOT:-/build}"
BUILD_PARAMS="--skip-linting"

if [ $build_mode == "Release" ]; then
  # release is a boolean flag
  BUILD_PARAMS="${BUILD_PARAMS} --release"
fi

BUILD_PARAMS="${BUILD_PARAMS} --optimization-passes ${optimization_passes}"

echo "SRC_ROOT=$SRC_ROOT"
echo "BUILD_PARAMS=$BUILD_PARAMS"

cd $SRC_ROOT

cargo +"${rustc_version}" contract build ${BUILD_PARAMS}