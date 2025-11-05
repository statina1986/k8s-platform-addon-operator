# ---------- Stage 1: Build rabbitmqadmin from source ----------
ARG ARCH
FROM ${ARCH}alpine:3.22

# Install required build tools
RUN apk --update --no-cache add curl gcc musl-dev pkgconfig openssl openssl-dev openssl-libs-static

RUN curl -s https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Build and install the binary
RUN cargo install rabbitmqadmin --root /out

RUN rustup self uninstall -y