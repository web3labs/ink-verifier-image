FROM rust:1.66

WORKDIR /build

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    # Install dependencies
    apt-get install -y clang lld libclang-dev jq xxd zip; \
    # Print versions
    rustup show; \
    cargo --version; \
    # Link clang
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100; \
    # Clean up
    apt-get autoremove -y; \
	apt-get clean; \
    rm -rf /var/lib/apt/lists/*

# Configure linker by target
COPY config/config.toml /root/.cargo/config

# Install scripts
COPY scripts/* /usr/local/bin/

RUN chmod +x /usr/local/bin/*-contract

ENTRYPOINT ["verify-contract"]
