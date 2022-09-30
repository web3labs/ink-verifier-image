alias b := build-image
alias c := verify
alias p := package

default:
  @just --list

build-image:
  docker build . -t ink-verifier:develop

verify CODE_HASH BASE_DIR=`pwd` NETWORK="rococo":
  docker run \
    -v {{BASE_DIR}}/{{NETWORK}}/{{CODE_HASH}}:/build \
    -v {{BASE_DIR}}/.cache:/root/.cache \
    -v {{BASE_DIR}}/.cargo/registry:/usr/local/cargo/registry \
    -v {{BASE_DIR}}/.rustup:/usr/local/rustup \
    --rm ink-verifier:develop

package SRC_DIR DST_DIR=".dist" BUILD_DIR="/tmp/contract-build":
  mkdir -p {{BUILD_DIR}}
  mkdir -p {{DST_DIR}}
  rm -rf {{BUILD_DIR}}/*
  cp -r {{SRC_DIR}} {{BUILD_DIR}}/src
  mv {{BUILD_DIR}}/src/target/ink/*.contract {{BUILD_DIR}}/
  rm -rf {{BUILD_DIR}}/src/target
  (cd {{BUILD_DIR}} && zip -r - src/ *.contract) > {{DST_DIR}}/package.zip
  rm -rf {{BUILD_DIR}}
  unzip -l {{DST_DIR}}/package.zip
