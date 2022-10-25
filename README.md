# Verifier Image for Ink!

Container image for Ink! smart contracts source code verification.

Features:
- Verification of source packages
- Verifiable source package generation

# Building

```
docker build . -t ink-verifier:develop
```

# Package Generation

To generate a verifiable source code package you can use the provided command line tool.

1. Install the command line tool from https://github.com/web3labs/ink-verifier/tree/main/cli
2. Change to the directory cointaing the smart contract source code
3. Execute the tool to generate the package

Example:

Change to the contract directory
```
❯ cd flipper
❯ tree -L 1
.
├── Cargo.lock
├── Cargo.toml
└── lib.rs
```
Execute the verifiable package generation tool
```
❯ build-verifiable-ink .
[omitted ouput...]
The contract was built in RELEASE mode.

Your contract artifacts are ready. You can find them in:
/build/package/src/target/ink

  - flipper.contract (code + metadata)
  - flipper.wasm (the contract's code)
  - metadata.json (the contract's metadata)
  adding: src/ (stored 0%)
  adding: src/Cargo.toml (deflated 65%)
  adding: src/Cargo.lock (deflated 74%)
  adding: src/lib.rs (deflated 67%)
  adding: flipper.contract (deflated 64%)
Verification package in /build/target/ink/package.zip
Archive:  /build/target/ink/package.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2022-10-25 08:44   src/
      976  2022-10-25 08:34   src/Cargo.toml
    17256  2022-10-25 08:34   src/Cargo.lock
     1366  2022-10-25 08:34   src/lib.rs
     3856  2022-10-25 08:44   flipper.contract
---------                     -------
    23454                     5 files
```
The verifiable package is generated
```
❯ tree -L 3
.
├── Cargo.lock
├── Cargo.toml
├── lib.rs
└── target
    └── ink
        └── package.zip
```

To avoid problems with file system permissions we recommend the use of [Podman](https://podman.io/) as container engine.
You can specify the container engine in the command line tool options:
```
❯ build-verifiable-ink --help 
A command line interface to generate verifiable source code packages.

Usage: build-verifiable-ink [OPTIONS] <SOURCE>

Arguments:
  <SOURCE>  Source directory, can be relative; e.g. '.'

Options:
  -t, --tag <TAG>            Ink! verifier image tag [default: develop]
      --engine <ENGINE>      Container engine [default: docker]
      --env-file <ENV_FILE>  Environment file
  -h, --help                 Print help information
  -V, --version              Print version information
```

# Source Code Verification

This section describes the verification process of generated verifiable source code packages.

## Pre-requisites

The image expects the following volume mappings:
|Mount Point|Description|
|-|-|
|/build|Contains the package to be verified|
|/opt/.cache|cached downloads directory|
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
  -v /opt/ink-builds/.cache:/opt/.cache \
  -v /opt/ink-builds/.cargo/registry:/usr/local/cargo/registry \
  -v /opt/ink-builds/.rustup:/usr/local/rustup \
  --rm ink-verifier:develop
```
