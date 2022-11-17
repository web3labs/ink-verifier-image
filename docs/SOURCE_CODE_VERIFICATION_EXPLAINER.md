# Source Code Verification Explainer

> 🐉 This image and the described mechanisms are not yet officially supported, therefore are experimental and subject to change. 🐉

Smart contracts allow users to interact with them without trusting third parties, such as developers or companies. Source code verification assures that a source code matches the binary bytecode deployed on a blockchain in a trustless way. However, source code verification does not ensure the correctness nor the security of a smart contract, which is carried on by "formal verification" techniques.

In the case of [Ink! smart contracts](https://use.ink/), to reproduce the build using the contracts cargo tool you need an equivalent build environment to generate the WASM blob for deployment and for verification. For that reason we provide [ink-verifier](https://github.com/web3labs/ink-verifier/), a container image supporting the generation of verifiable build packages and its verification.

The [ink-verifier-server](https://github.com/web3labs/ink-verifier-server) provides a convinient web API to run the verification process and to access its resulting artefacts.

