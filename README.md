# 🦑 Verifier Image for Ink!

> 🐉🐉 This image and the described mechanisms are not yet officially supported, therefore are experimental and subject to change.

Container image for Ink! smart contracts source code verification.

Features:
- Verification of source packages
- Verifiable source package generation

See [Ink! Verifier explainer](https://github.com/web3labs/ink-verifier-server/blob/main/docs/INK_VERIFIER_EXPLAINER.md) for further info on how the image is used in the Ink! Verifier Server for a full verification workflow.

# Building

To build the image locally

```
docker build . -t ink-verifier:develop
```

You can also pull the published image

```
docker pull ghcr.io/web3labs/ink-verifier:latest
```

# Reproducible Build

You can build your contract by running the image directly but we highly recommend to use the provided command line tool. Besides running the reproducible build, the tool also packages the relevant files into a handy `package.zip` file with the directory struture that is required for verification.

## Building with command line tool

1. Install the command line tool [here](./cli/README.md)
2. Change to the directory cointaing the smart contract source code
3. Execute the tool to generate the package

## Example

> 🐉🐉 Reproducible builds only works w/ cargo-contract >= 2.0.0-alpha.5
> and contracts generated with that version.

To generate example ink! contract install the specific version of the cargo-contract tool:

```
❯ cargo install --git https://github.com/paritytech/cargo-contract \
                --locked --rev e2e804be3bab2a987f0441fb8025a5a82da1c10e \ 
                --force
```

ℹ️ For the moment, we recommend installing cargo-contract as defined above rather than through [crates.io](https://crates.io/crates/cargo-contract). See the section [Caveats](#caveats) for more information.

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

Pull the docker image
```
docker pull ghcr.io/web3labs/ink-verifier:latest
```

Execute the verifiable package generation tool. Check out the `build-verifiable-ink` [documentation](./cli/README.md) for more detailed running instructions.
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

The command will generate a `package.zip` in `<your_source_dir>/target/ink` directory.

Please, copy it to a safe location.

You can extract the `<contract name>.wasm` and `metadata.json` from the package archive as follows:

```
❯ unzip -qq -p target/ink/package.zip "*.contract" | jq -r ".source.wasm" | xxd -r -p > target/ink/flipper.wasm
❯ unzip -qq -p target/ink/package.zip "*.contract" > target/ink/metadata.json
```

The generated `.contract` file should be uploaded to the blockchain if you want to be able to verify your source code.

Upload example using cargo-contract tool:

```
❯ cargo contract upload -s '//Bob'
````

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
2. The `<name>.contract` file must include the `build_info` section. See [caveats](#caveats) for more information.

## Running a Verification

```
docker run \
  -v /opt/ink-builds/rococo/0x51606b677cc203a561cd0cfbba708024feb85f46fe42238afc55a115785e1f95:/build \
  -v /opt/ink-builds/.cache:/opt/.cache \
  -v /opt/ink-builds/.cargo/registry:/usr/local/cargo/registry \
  -v /opt/ink-builds/.rustup:/usr/local/rustup \
  --rm ink-verifier:develop
```

# Caveats

The mechanism for reproducible builds is very new and experimental. Therefore, there are several caveats that should be taken note of.

To ensure an identical build environment to perform a reproducible build, the Ink! team has added the `build_info` entry in generated contract metadata since cargo-contract [v2.0.0-alpha.5](https://github.com/paritytech/cargo-contract/releases/tag/v2.0.0-alpha.5). It should be noted though, that installing `v2.0.0-alpha.5` from crates.io will result in dependencies such as `contract-metadata` and `contract-transcode` to install `v2.0.0-beta`. This is because the dependencies are specified as `^2.0.0-alpha.5` (see crates [dependencies](https://crates.io/crates/cargo-contract/2.0.0-alpha.5/dependencies)). This is not a problem in itself but contracts built with this version can only be deployed on networks that have migrated to [Weights V2](https://github.com/paritytech/polkadot/pull/6091).

In our reproducible build image we are installing cargo-contract from Github from the commit `e2e804be3bab2a987f0441fb8025a5a82da1c10e`. This is done specifically so that verifiable contracts can also be uploaded to our [local-testnet](https://github.com/web3labs/epirus-substrate/tree/main/local-testnet). Our local testnet is a fork of the [Substrate Contracts Node](https://github.com/paritytech/substrate-contracts-node) with a patch for finality with instant seal (see this [pull request](https://github.com/paritytech/substrate/pull/12106) for more information). The updated Substrate Contracts Node that supports Weights V2 does not work with our patch and thus, we have decided to keep with a lower version of cargo-contract. When `instant-seal-with-finality` is officially supported in Substrate Contracts Node, we will update the versions accordingly.
