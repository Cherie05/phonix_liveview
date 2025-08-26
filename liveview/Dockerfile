# ---------- Build stage ----------
FROM elixir:1.17 AS build
ENV MIX_ENV=prod LANG=C.UTF-8
WORKDIR /app

# Tools we need to build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Hex & Rebar (tune for slower networks)
RUN mix local.hex --force && mix local.rebar --force \
 && mix hex.config http_concurrency 1 \
 && mix hex.config http_timeout 180 \
 && mix hex.repo add hexpm https://repo.hex.pm

# Project files for deps resolution
COPY mix.exs mix.lock ./

# Use host-vendored deps to avoid Hex timeouts inside Docker
# Make sure you ran on host: MIX_ENV=prod mix deps.get
COPY deps ./deps
RUN mix deps.get --only prod --offline && mix deps.compile

# Copy the rest of the project
COPY . .

# Build assets via Hex-based tasks (Phoenix 1.7+); no npm required by default
RUN mix assets.deploy

# Compile and build release
RUN mix compile
RUN mix release

# ---------- Runtime stage ----------
FROM debian:bookworm-slim
ENV MIX_ENV=prod LANG=C.UTF-8
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl libstdc++6 curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/liveview ./

ENV PHX_SERVER=true PORT=4000
EXPOSE 4000

CMD ["bin/liveview", "start"]
