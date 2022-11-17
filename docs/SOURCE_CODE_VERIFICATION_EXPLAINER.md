# Source Code Verification Explainer

Smart contracts allow users to interact with them without trusting third parties, such as developers or companies. Source code verification assures that a source code matches the binary bytecode deployed on a blockchain in a trustless way. However, source code verification does not ensure the correctness nor the security of a smart contract, which is carried on by "formal verification" techniques.

In the case of Ink! smart contracts, to reproduce the build using the contracts cargo tool you need an equivalent build environment to generate the WASM blob for deployment and for verification. For that reason we provide [ink-verifier](https://github.com/web3labs/ink-verifier/), a container image supporting the generation of verifiable build packages and its verification.

> Note that this images and described mechanisms are not yet supported officially and therefore are subject to change.

# Generating Verifiable Builds

To generate a verifiable build you can use the [command line tool](https://github.com/web3labs/ink-verifier/tree/main/cli).
Alternatively, you can run the container yourself.

## Command Line Tool

### Pre-requisites

> WARN: Reproducible builds works works w/ cargo-contract 2.0.0-alpha.4
> and contracts generated with that version.

We provide some example contracts in /TBD/

To generate your own ink! contracts install the specific version of the cargo-contract tool:

```
cargo install --git https://github.com/paritytech/cargo-contract \
              --locked --rev e2e804be3bab2a987f0441fb8025a5a82da1c10e \ 
              --force
```

```
cargo contract new my-contract
```


### Install

```
cargo install --path .
```

### Run

Assuming that you are located in the source code directory of your contract

```
build-verifiable-ink -i ghcr.io/web3labs/ink-verifier .
```

After a while, you will have an output similar to:

```
[...]

Original wasm size: 19.6K, Optimized: 1.3K

The contract was built in RELEASE mode.

Your contract artifacts are ready. You can find them in:
/build/package/src/target/ink

  - flipper.contract (code + metadata)
  - flipper.wasm (the contract's code)
  - metadata.json (the contract's metadata)
  adding: src/ (stored 0%)
  adding: src/Cargo.toml (deflated 49%)
  adding: src/Cargo.lock (deflated 74%)
  adding: src/lib.rs (deflated 64%)
  adding: flipper.contract (deflated 60%)
Verification package in /build/target/ink/package.zip
Archive:  /build/target/ink/package.zip
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  2022-11-15 12:41   src/
      611  2022-11-15 12:34   src/Cargo.toml
    17838  2022-11-15 12:40   src/Cargo.lock
     2149  2022-11-15 12:34   src/lib.rs
     4280  2022-11-15 12:41   flipper.contract
---------                     -------
    24878                     5 files
```

The command will generate a `package.zip` in `<your_source_dir>/target/ink` directory.

Please, copy it to a safe location.

You can extract the `<contract name>.contract` and `metadata.json` from the package archive as follows:

```
unzip -qq -p target/ink/package.zip "*.contract" | jq -r ".source.wasm" | xxd -r -p > target/ink/flipper.wasm
unzip -qq -p target/ink/package.zip "*.contract" > target/ink/metadata.json
```

The generated `.contract` file should be uploaded to the blockchain if you want to be able to verify your source code.

Upload example using cargo-contract tool:

```
cargo contract upload -s '//Bob'
````

# Verifying Source Code

Assuming that you have uploaded the contract emitted from the "verifiable build" and you have the `code hash` and the `chain name` (e.g. "local", "rococoContracts", "shibuya", ...).

You can use either the [Explorer UI](https://github.com/web3labs/epirus-substrate) or the [Source Code Verification Server](https://github.com/web3labs/ink-verifier-server) to verify your source code.
