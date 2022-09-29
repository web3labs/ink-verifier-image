FROM rust:1.64

RUN apt-get update

# Install jq
RUN apt-get install -y jq xxd

# Download sccache and verify checksum
ADD https://github.com/mozilla/sccache/releases/download/v0.3.0/sccache-v0.3.0-x86_64-unknown-linux-musl.tar.gz /tmp/sccache.tar.gz
RUN sha256sum /tmp/sccache.tar.gz | egrep '(e6cd8485f93d683a49c83796b9986f090901765aa4feb40d191b03ea770311d8)'

# Extract and install sccache
RUN tar -xf /tmp/sccache.tar.gz
RUN mv sccache-*/sccache /usr/local/bin/sccache
RUN chmod +x /usr/local/bin/sccache

# Print versions
RUN sccache --version
RUN rustup -vV
RUN cargo --version

WORKDIR /build

# Use sccache by default
ENV RUSTC_WRAPPER=sccache

COPY verify-contract.sh /usr/local/bin
RUN chmod +x /usr/local/bin/verify-contract.sh

ENTRYPOINT ["verify-contract.sh"]
