# ---------- Build stage ----------
FROM elixir:1.17 AS build
ENV MIX_ENV=prod LANG=C.UTF-8
WORKDIR /app

# Tools needed to build
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git ca-certificates curl \
 && rm -rf /var/lib/apt/lists/*

# Hex & Rebar (tuned for slow networks)
RUN mix local.hex --force && mix local.rebar --force \
 && mix hex.config http_concurrency 1 \
 && mix hex.config http_timeout 180 \
 && mix hex.repo add hexpm https://repo.hex.pm

# Project files for deps resolution
COPY mix.exs mix.lock ./

# (Optional but helpful) Use host-vendored deps to avoid Hex timeouts inside Docker
# If you didn't vendor deps, comment the next two lines and rely on online resolve.
COPY deps ./deps
RUN mix deps.get --only prod --offline && mix deps.compile

# Copy the rest of the project
COPY . .

# Build static assets (Phoenix 1.7+)
RUN mix assets.deploy

# Compile + build release
RUN mix compile
RUN mix release

# ---------- Runtime stage ----------
FROM debian:bookworm-slim
ENV MIX_ENV=prod LANG=C.UTF-8
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    openssl libstdc++6 curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Create a writable uploads dir (ephemeral on Render free tier)
RUN mkdir -p /app/uploads

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/liveview ./

# Phoenix server on, PORT comes from platform (Render sets it)
ENV PHX_SERVER=true
EXPOSE 4000

CMD ["bin/liveview", "start"]
