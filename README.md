# Ink Contracts Verifier

# Container Image

```
docker build . -t ink-verifier:develop
```

# Verification

## Pre-requisites

The image expects the following volume mappings:
|Mount Point|Description|
|-|-|
|/build|Contains the package to be verified|
|/root/.cache|sccache directory|
|/usr/local/cargo/registry|Cargo registry|
|/usr/local/rustup|Rustup caches and artifacts|

The layout of the verification build directory is as follows:
```
build
├── package.zip
└── pristine.wasm
```

Where `package.zip` is the compressed archive containing the source code files in the `src/`directory and the `<name>.contract` file at the root.

Example for the flipper contract
```
package
├── flipper.contract
└── src
    ├── Cargo.lock
    ├── Cargo.toml
    └── lib.rs
```

and (2) `pristine.wasm` is the WASM bytecode retrieved from the chain.

NOTE that the `package.[zip|tgz|tar.gz]` and `pristine.wasm` must be named as indicated.
NOTE that the `<name>.contract` file must include the `build_info` section and it is not generally available at the moment.
See https://github.com/paritytech/cargo-contract/issues/525  

## Running a Verification

```
docker run \
  -v /opt/ink-builds/rococo/0x51606b677cc203a561cd0cfbba708024feb85f46fe42238afc55a115785e1f95:/build \
  -v /opt/ink-builds/.cache:/root/.cache \
  -v /opt/ink-builds/.cargo/registry:/usr/local/cargo/registry \
  -v /opt/ink-builds/.rustup:/usr/local/rustup \
  --rm ink-verifier:develop
```
