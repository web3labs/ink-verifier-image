FROM rust:1.64

RUN apt-get update

# Install packages
RUN apt-get install -y jq xxd zip

# Print versions
RUN rustup -vV
RUN cargo --version

WORKDIR /build

COPY scripts/build-contract.sh /usr/local/bin/build-contract
RUN chmod +x /usr/local/bin/build-contract

COPY scripts/verify-contract.sh /usr/local/bin/verify-contract
RUN chmod +x /usr/local/bin/verify-contract

COPY scripts/package-contract.sh /usr/local/bin/package-contract
RUN chmod +x /usr/local/bin/package-contract

ENTRYPOINT ["verify-contract"]
