FROM rust:1.64

RUN apt-get update

# Install packages
RUN apt-get install -y jq xxd

# Print versions
RUN rustup -vV
RUN cargo --version

WORKDIR /build

COPY verify-contract.sh /usr/local/bin
RUN chmod +x /usr/local/bin/verify-contract.sh

ENTRYPOINT ["verify-contract.sh"]
