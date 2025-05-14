# Etap 1: Budowanie aplikacji Go z użyciem obrazu bazowego Golang
FROM golang:1.24.3 AS builder

# Ustawienie katalogu roboczego wewnątrz obrazu
WORKDIR /app

# Skopiowanie wszystkich plików projektu do obrazu
COPY . .

# Kompilacja binarki Go w trybie statycznym (niezależna od bibliotek systemowych)
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o weather

# Etap 2: Utworzenie końcowego obrazu z Alpine
FROM alpine

# Dodanie metadanych o autorze obrazu zgodnie ze standardem OCI
LABEL org.opencontainers.image.authors="Agnieszka Marzęda"

# Instalacja certyfikatów SSL (potrzebnych do HTTPS) i curl (do healthchecka)
RUN apk add --no-cache ca-certificates curl

# Skopiowanie skompilowanej aplikacji Go z etapu build do obrazu końcowego
COPY --from=builder /app/weather /weather

# Skopiowanie szablonów HTML do katalogu wewnątrz obrazu
COPY --from=builder /app/templates /templates

# Udostępnienie portu 8080 (aplikacja nasłuchuje na tym porcie)
EXPOSE 8080

# Dodanie mechanizmu sprawdzania stanu zdrowia kontenera (healthcheck)
# co 30 sekund sprawdza, czy aplikacja odpowiada na HTTP GET / na porcie 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080 || exit 1

# Ustawienie domyślnego polecenia uruchamiającego aplikację
ENTRYPOINT ["/weather"]
