# config/runtime.exs
import Config

# Enable the Phoenix server when PHX_SERVER is set (release)
if System.get_env("PHX_SERVER") do
  config :liveview, LiveviewWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: postgresql://USER:PASS@HOST/DATABASE?sslmode=require
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :liveview, Liveview.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  # Allowed origins for LiveView socket checks
  allowed_origins =
    case System.get_env("ALLOWED_ORIGINS") do
      nil -> ["//#{host}", "//localhost:4000", "//127.0.0.1:4000"]
      "" -> ["//#{host}", "//localhost:4000", "//127.0.0.1:4000"]
      s -> String.split(s, ",", trim: true)
    end

  config :liveview, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # Render terminates TLS at the edge; generate HTTPS URLs externally while
  # listening on the provided $PORT internally.
  config :liveview, LiveviewWeb.Endpoint,
    url: [host: host, scheme: "https", port: 443],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base,
    check_origin: allowed_origins,
    adapter: Bandit.PhoenixAdapter
end
