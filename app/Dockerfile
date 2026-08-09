# Step 1: Build the Go binary
FROM golang:1.22-alpine AS builder

WORKDIR /app

# Copy dependency files and download
COPY go.mod go.sum ./
RUN go mod download

# Copy source code and build
COPY . .
RUN go build -o hello-world .

# Step 2: Create minimal runtime image
FROM alpine:latest

# Copy the binary from builder
COPY --from=builder /app/hello-world /hello-world

# Expose port
EXPOSE 8080

# Run the application
CMD ["/hello-world"]
