# Build stage
FROM docker.io/library/rust:1.85-alpine AS builder

WORKDIR /usr/src/app
COPY . .

# Install build dependencies
RUN apk add --no-cache musl-dev openssl-dev pkgconfig

# Set environment variables for static linking
ENV OPENSSL_STATIC=1
ENV OPENSSL_DIR=/usr
ENV PKG_CONFIG_ALL_STATIC=1

# Build the application
RUN cargo build --release

# Runtime stage
FROM docker.io/library/alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates openssl

WORKDIR /usr/local/bin

# Copy the binary from builder stage
COPY --from=builder /usr/src/app/target/release/cloud-gauntlet-api .

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -u 1001 -S appuser -G appgroup

USER appuser

EXPOSE 3000

CMD ["./cloud-gauntlet-api"]
