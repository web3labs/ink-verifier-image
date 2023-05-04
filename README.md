# 🦑 Verifier Image for ink!

> 🐉🐉 This image and the described mechanisms are not yet officially supported, therefore are experimental and subject to change.

Container image for ink! smart contracts source code verification.

Features:
- Verification of source packages
- Verifiable source package generation

See [ink! Verifier explainer](https://github.com/web3labs/ink-verifier-server/blob/main/docs/INK_VERIFIER_EXPLAINER.md) for further info on how the image is used in the ink! Verifier Server for a full verification workflow.

**Table of Contents**
- [Building the Verifier Image](#building-the-verifier-image)
- [Reproducible Build](#reproducible-build)
  - [Building with Command Line Tool](#building-with-command-line-tool)
  - [Building with Container Image Directly](#building-with-container-image-directly)
- [Source Code Verification](#source-code-verification)
  - [Pre-requisites](#pre-requisites)
  - [Running a Verification](#running-a-verification)
- [Caveats](#caveats)

## Building the Verifier Image

To build the image locally

```
docker build . -t ink-verifier:develop
```

## Reproducible Build

> 🐉🐉 Reproducible builds only works w/ cargo-contract >= 2.0.0
> and contracts generated with that version.

You can build your contract by running the image directly but we also provide a handy command line tool. In the following section we will explain how to generate your verifiable contract package using both methods.

### Building with Command Line Tool

1. Install the command line tool [here](./cli/README.md#install)
2. Change to the directory cointaing the smart contract source code
3. Execute the tool to generate the package

#### Example <!-- omit from toc --> 

To generate the example ink! contract install the [cargo-contract](https://github.com/paritytech/cargo-contract) tool. Please, read the [installation section](https://github.com/paritytech/cargo-contract#installation) from the README.

Create the flipper contract:

```
cargo contract new flipper
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

Execute the verifiable package generation tool. Check out the `build-verifiable-ink` [documentation](./cli/README.md#run) for more detailed running instructions.
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

You can extract the `<contract name>.contract`, `metadata.json` and `<contract name>.wasm` from the package archive as follows:

```
❯ unzip -qq -p target/ink/package.zip "*.contract" > target/ink/flipper.contract
❯ unzip -qq -p target/ink/package.zip "*.contract" | jq "del(.source.wasm)" > target/ink/metadata.json
❯ unzip -qq -p target/ink/package.zip "*.contract" | jq -r ".source.wasm" | xxd -r -p > target/ink/flipper.wasm
```

The generated `.contract` file should be uploaded to the blockchain if you want to be able to verify your source code.

Upload and instantiate example using cargo-contract tool:

```
cargo contract instantiate \
--constructor new \
--args false \
--suri //Alice
````

### Building with Container Image Directly

You can run the image directly specifying environment variables with `-e` or `--env` flag.

```
docker run -i -t --rm --entrypoint package-contract \
    -v </path/to/contract>:/build \
    -e CARGO_CONTRACT_VERSION=2.0.2 \
    -i ink-verifier:develop
```

Environment variables supported (and their default values):
```
BUILD_MODE=Release
CARGO_CONTRACT_VERSION=2.0.2
RUST_TOOLCHAIN=1.66.1-x86_64-unknown-linux-gnu
KEEP_DEBUG_SYMBOLS=false
OPTIMIZATION_PASSES=Z
```

ℹ️ Ensure that the ink crate in your `Cargo.toml` is pointing to a version that is compatible with the cargo-contract version used to build the contract. If not, the build will fail! 

## Source Code Verification

> As an end user you can use either the [Explorer UI](https://github.com/web3labs/epirus-substrate) or the [Source Code Verification Server](https://github.com/web3labs/ink-verifier-server) to verify your source code.

This section describes the verification process of generated verifiable source code packages using the container image.

### Pre-requisites

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

#### Notes <!-- omit from toc --> 

1. The `package.[zip|tgz|tar.gz]` and `pristine.wasm` must be named as indicated.
2. The `<name>.contract` file must include the `build_info` section. See [caveats](#caveats) for more information.

### Running a Verification

```
docker run \
  -v /opt/ink-builds/rococo/0x51606b677cc203a561cd0cfbba708024feb85f46fe42238afc55a115785e1f95:/build \
  -v /opt/ink-builds/.cache:/opt/.cache \
  -v /opt/ink-builds/.cargo/registry:/usr/local/cargo/registry \
  -v /opt/ink-builds/.rustup:/usr/local/rustup \
  --rm ink-verifier:develop
```

## Caveats

The mechanism for reproducible builds is very new and experimental. Therefore, there are some caveats that should be taken note of.

To ensure an identical build environment to perform a reproducible build, the ink! team has added the `build_info` entry in generated contract metadata since cargo-contract [v2.0.0-alpha.5](https://github.com/paritytech/cargo-contract/releases/tag/v2.0.0-alpha.5). It should be noted though, that installing `v2.0.0-alpha.5` from crates.io will result in dependencies such as `contract-metadata` and `contract-transcode` to install `v2.0.0-beta`. This is because the dependencies are specified as `^2.0.0-alpha.5` (see crates [dependencies](https://crates.io/crates/cargo-contract/2.0.0-alpha.5/dependencies)). This is not a problem in itself but contracts built with this version can only be deployed on networks that have migrated to [Weights V2](https://github.com/paritytech/polkadot/pull/6091).
