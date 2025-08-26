import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# Enable the Phoenix server when PHX_SERVER env var is set (used in releases).
if System.get_env("PHX_SERVER") do
  config :liveview, LiveviewWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :liveview, Liveview.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  # host and port used for URL generation and for origin checks
  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :liveview, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  # Allowed origins for LiveView socket/transport checks.
  # By default allow localhost and 127.0.0.1 on port 4000.
  # You can override by setting ALLOWED_ORIGINS env var to a comma separated list,
  # e.g. ALLOWED_ORIGINS="//example.com,//sub.example.com:443"
  allowed_origins =
    case System.get_env("ALLOWED_ORIGINS") do
      nil -> ["//localhost:4000", "//127.0.0.1:4000"]
      "" -> ["//localhost:4000", "//127.0.0.1:4000"]
      s -> String.split(s, ",", trim: true)
    end

  config :liveview, LiveviewWeb.Endpoint,
    url: [host: host, port: port],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    check_origin: allowed_origins,
    adapter: Bandit.PhoenixAdapter
end
