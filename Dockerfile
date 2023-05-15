FROM docker.io/bitnami/minideb:bullseye as slimmed-rust

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_VERSION=1.69.0

# Minimal Rust dependencies.
RUN set -eux \
    && apt-get update && apt-get -y install wget g++ \
    && dpkgArch="$(dpkg --print-architecture)" \
    && case "${dpkgArch##*-}" in \
        amd64) rustArch='x86_64-unknown-linux-gnu' ;; \
        arm64) rustArch='aarch64-unknown-linux-gnu' ;; \
        *) echo >&2 "unsupported architecture: ${dpkgArch}"; exit 1 ;; \
    esac \
    && url="https://static.rust-lang.org/rustup/dist/${rustArch}/rustup-init" \
    && wget "$url" \
    && chmod +x rustup-init \
    && ./rustup-init -y --no-modify-path --profile minimal --component rust-src rustfmt --default-toolchain $RUST_VERSION  \
    && rm rustup-init \
    && chmod -R a+w $RUSTUP_HOME $CARGO_HOME \
    && rustup --version \
    && cargo --version \
    && rustc --version \
    && apt-get remove -y --auto-remove wget \
    && apt-get -y install gcc jq xxd zip file \
    && rm -rf /var/lib/apt/lists/*

################################################
FROM slimmed-rust as ink-verifier-image

WORKDIR /build

# Configure linker by target
COPY config/config.toml /root/.cargo/config

# Install scripts
COPY scripts/* /usr/local/bin/

RUN chmod +x /usr/local/bin/*-contract

ENTRYPOINT ["verify-contract"]
