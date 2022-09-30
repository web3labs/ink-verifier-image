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


tmpdir  := `mktemp -d`
buidir  := tmpdir / "contract-build"

package SRC_DIR DST_DIR=".dist":
  mkdir -p {{buidir}}
  mkdir -p {{DST_DIR}}
  rm -rf {{buidir}}/*
  cp -r {{SRC_DIR}} {{buidir}}/src
  mv {{buidir}}/src/target/ink/*.contract {{buidir}}/
  rm -rf {{buidir}}/src/target
  (cd {{buidir}} && zip -r - src/ *.contract) > {{DST_DIR}}/package.zip
  rm -rf {{tmpdir}}
  unzip -l {{DST_DIR}}/package.zip
