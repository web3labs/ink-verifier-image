# Source Code Verification Explainer

Smart contracts allow users to interact with them without trusting third parties, such as developers or companies. Source code verification assures that a source code matches the binary bytecode deployed on a blockchain in a trustless way. However, source code verification does not ensure the correctness nor the security of a smart contract, which is carried on by "formal verification" techniques.

In the case of Ink! smart contracts, to reproduce the build using the contracts cargo tool you need an equivalent build environment to generate the WASM blob for deployment and for verification. For that reason we provide [ink-verifier](https://github.com/web3labs/ink-verifier/), a container image supporting the generation of verifiable build packages and its verification.

> Note that this images and described mechanisms are not yet supported officially and therefore are subject to change.

# Generating Verifiable Builds

To generate a verifiable build you can use the [command line tool](https://github.com/web3labs/ink-verifier/tree/main/cli).
Alternatively, you can run the container yourself.

