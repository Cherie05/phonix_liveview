defmodule Liveview.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Build children list *without* the Endpoint. We'll add the Endpoint later
    # after we optionally run migrations.
    children_without_endpoint = [
      LiveviewWeb.Telemetry,
      Liveview.Repo,
      {DNSCluster, query: Application.get_env(:liveview, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Liveview.PubSub},
      {Finch, name: Liveview.Finch}
      # other workers (do NOT add LiveviewWeb.Endpoint here)
    ]

    opts = [strategy: :one_for_one, name: Liveview.Supervisor]

    # Start the supervisor (without Endpoint)
    {:ok, sup_pid} = Supervisor.start_link(children_without_endpoint, opts)

    # If MIGRATE=true, run migrations now (Repo is already started under the supervisor).
    maybe_run_migrations()

    # Start the Endpoint as a child under the running supervisor.
    # Use the endpoint child_spec to ensure proper config.
    case Supervisor.start_child(sup_pid, LiveviewWeb.Endpoint.child_spec([])) do
      {:ok, _pid} ->
        :ok

      {:error, {:already_started, _pid}} ->
        # If it somehow started already, ignore
        :ok

      {:error, reason} ->
        # bubble up unexpected errors
        raise "Failed to start endpoint: #{inspect(reason)}"
    end

    {:ok, sup_pid}
  end

  defp maybe_run_migrations do
    case System.get_env("MIGRATE") do
      "true" ->
        IO.puts("MIGRATE=true -> running migrations before endpoint starts")
        run_migrations()

      _ ->
        :ok
    end
  end

  defp run_migrations do
    # Ensure apps required for migrations are started
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:ecto_sql)

    repos = Application.fetch_env!(:liveview, :ecto_repos)

    Enum.each(repos, fn repo ->
      IO.puts("Running migrations for #{inspect(repo)}")
      # repo is already started under the supervisor, so just run migrations
      Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
      IO.puts("Migrations finished for #{inspect(repo)}")
    end)
  end

  @impl true
  def config_change(changed, _new, removed) do
    LiveviewWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
