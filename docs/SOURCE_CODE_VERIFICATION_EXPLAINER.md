# Source Code Verification Explainer

> 🐉🐉 This image and the described mechanisms are not yet officially supported, therefore are experimental and subject to change.

Smart contracts allow users to interact with them without trusting third parties, such as developers or companies. However, smart contracts are stored on-chain as bytecode and is not readable to humans. Without the original source code uploaded, it is impossible for users of the smart contract to know what it really does. At the same time, uploaded source code needs to be verified to make sure that it indeed corresponds to the contract that it claims to be. Source code verification is a process that assures uploaded source code matches the binary bytecode deployed on a blockchain in a trustless way. The Ink! Verifier provides such a service for Ink! smart contracts running on Substrate chains.

---

**Note:**

Source code verification does not ensure the correctness nor the security of a smart contract, which is carried out by "formal verification" techniques.

---

## Source Code Verification in Ink!

Smart contracts written in Ink! are compiled to Wasm and only the Wasm blobs are stored on-chain. Hence, the published source code needs to be compiled to output the exact same Wasm blob in order to be verified. This can be achieved through a deterministic build of the source code, which requires the build environment to be equivalent for both deployment and verification. For that reason we provide [ink-verifier](https://github.com/web3labs/ink-verifier/), a container image supporting the generation of verifiable build packages and its verification.

The Ink! Verifier image uses the official Rust Docker image as a base, on top of which it installs the rust toolchain and [cargo-contract](https://github.com/paritytech/cargo-contract) tool that will be used to build the source code. When a contract is built for deployment, the rust toolchain and cargo contract are installed from pre-defined versions¹. Upon compilation of the source code, cargo contract will generate a `.contract` file which contains the contract metadata and the compiled Wasm blob. During verification, the user will need to supply both the source code as well as this `.contract` file as a compressed archive. The Ink Verifier image then installs the rust toolchain and cargo contract version as specified in the contract metadata in order to reproduce an identical environment for compilation.

<sup>1 The cargo contract version is currently pinned to the Master branch of [cargo-contract](https://github.com/paritytech/cargo-contract) because there is yet a stable release which outputs the build environment parameters into the contract metadata after compilation. In the future, we plan to add support for users to choose the version of rust toolchain and cargo contract they wish to use.</sup>

---

**Note:**

It is essential that the source code is built with the container image for it to be verified due to the requirement for identical build environments in deterministic builds.

---

## Architecture

The Ink Verifier service is composed of three different components:
- [Ink! Verifier Image](https://github.com/web3labs/ink-verifier/) - the container image for performing deterministic builds
- [Ink! Verifier Server](https://github.com/web3labs/ink-verifier-server) - provides a convenient web API to run the verification process and to access its resulting artefacts
- [Explorer UI](https://github.com/web3labs/epirus-substrate/tree/main/explorer-ui) - front-end for user-friendly upload of source code packages and review of verification process

In the following sections we will explain in detail how these components work together.

### Source Code Verification Workflow

![Source Code Verification Workflow](https://drive.google.com/uc?id=1Z4NVCnXRkDVPro7I39rFdlJ2mtSdNPDc)

### Source Code Verification Display

## Owner-signed Metadata Upload

As explained in the sections [Source Code Verification in Ink!](#source-code-verification-in-ink) and [Source Code Verification Workflow](#source-code-verification-workflow), the verification process requires cargo contract version v2.0.0-alpha.4 and up in order to have the build environment information output to the contract metadata. This means that any contract written in ink! v4.0.0-alpha.4 and lower will not be able to verify their contracts. In order to provide better usability in the Explorer UI for these "older" contracts, we provide the option to upload only the contract metadata signed by the owner of the contract¹. This allows the Explorer to be able to decode the messages and events of the contract even without the source code.

It should be noted that this method is not trustless as there is no way of verifying that the uploaded metadata indeed corresponds to the contract. To reduce the potential for "vandalisation" or "trolling" of contracts, we only accept the uploaded metadata if it is signed by the owner of the contract. We assume here that the owner of the contract has few reasons to purposely upload a fake metadata.

<sup>1 We say "owner of the contract" for simplicity but in reality it refers to the owner of the code hash, or the pristine code on-chain to be precise. It should not be confused with the deployer of the contract instance.</sup>

## Additional Developer Tools

