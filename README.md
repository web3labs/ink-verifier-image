# Verifier Image for Ink!

Container image for Ink! smart contracts source code verification.

Features:
- Verification of source packages
- Verifiable source package generation

See [source code verification explainer](https://github.com/web3labs/ink-verifier/blob/main/docs/SOURCE_CODE_VERIFICATION_EXPLAINER.md) for further info.

# Building

```
docker build . -t ink-verifier:develop
```

# Package Generation

To generate a verifiable source code package you can use the provided command line tool.

1. Install the command line tool from https://github.com/web3labs/ink-verifier/tree/main/cli
2. Change to the directory cointaing the smart contract source code
3. Execute the tool to generate the package

## Example

> WARN: Reproducible builds only works w/ cargo-contract >= 2.0.0-alpha.4
> and contracts generated with that version.

To generate example ink! contract install the specific version of the cargo-contract tool:

```
❯ cargo install --git https://github.com/paritytech/cargo-contract \
                --locked --rev e2e804be3bab2a987f0441fb8025a5a82da1c10e \ 
                --force
```

Create the flipper contract:

```
❯ cargo contract new flipper
```

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
❯ build-verifiable-ink -t develop .
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

The command will generate a `package.zip` in `<your_source_dir>/target/ink` directory.

Please, copy it to a safe location.

You can extract the `<contract name>.contract` and `metadata.json` from the package archive as follows:

```
❯ unzip -qq -p target/ink/package.zip "*.contract" | jq -r ".source.wasm" | xxd -r -p > target/ink/flipper.wasm
❯ unzip -qq -p target/ink/package.zip "*.contract" > target/ink/metadata.json
```

The generated `.contract` file should be uploaded to the blockchain if you want to be able to verify your source code.

Upload example using cargo-contract tool:

```
❯ cargo contract upload -s '//Bob'
````

### Notes

To avoid problems with file system permissions we recommend the use of [Podman](https://podman.io/) as container engine.

You can specify the container engine in the command line tool options:
```
❯ build-verifiable-ink --help
A command line interface to generate verifiable source code packages.

Usage: build-verifiable-ink [OPTIONS] <SOURCE>

Arguments:
  <SOURCE>  Source directory, can be relative; e.g. '.'

Options:
  -i, --image <IMAGE>        Ink! verifier image name [default: ink-verifier]
  -t, --tag <TAG>            Ink! verifier image tag [default: latest]
      --engine <ENGINE>      Container engine [default: docker]
      --env-file <ENV_FILE>  Environment file
  -h, --help                 Print help information
  -V, --version              Print version information
```

# Source Code Verification

> As an end user you can use either the [Explorer UI](https://github.com/web3labs/epirus-substrate) or the [Source Code Verification Server](https://github.com/web3labs/ink-verifier-server) to verify your source code.

This section describes the verification process of generated verifiable source code packages using the container image.

## Pre-requisites

The image expects the following volume mappings:
|Mount Point|Description|
|-|-|
|/build|Contains the package to be verified|
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

### Notes

1. The `package.[zip|tgz|tar.gz]` and `pristine.wasm` must be named as indicated.
2. The `<name>.contract` file must include the `build_info` section and it is not generally available at the moment.
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
