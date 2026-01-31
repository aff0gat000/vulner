FROM golang:1.23-alpine AS builder

RUN apk add --no-cache git ca-certificates

WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download 2>/dev/null || true
COPY . .

RUN CGO_ENABLED=0 go build -trimpath -ldflags '-s -w' -o /vulner ./cmd/vulner

FROM alpine:3.20

RUN apk add --no-cache ca-certificates rpm

COPY --from=builder /vulner /usr/local/bin/vulner
COPY benchmarks/ /etc/vulner/benchmarks/

RUN adduser -D -H vulner
USER vulner

ENTRYPOINT ["vulner"]
CMD ["--help"]
