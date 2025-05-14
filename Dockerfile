FROM golang:1.24.3 AS builder
WORKDIR /app
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o weather

FROM alpine

LABEL org.opencontainers.image.authors="Agnieszka Marzęda"

RUN apk add --no-cache ca-certificates curl

COPY --from=builder /app/weather /weather
COPY --from=builder /app/templates /templates

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

ENTRYPOINT ["/weather"]
