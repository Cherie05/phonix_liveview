defmodule Liveview.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Start without the Endpoint; we’ll add it after optional migrations.
    children_without_endpoint = [
      LiveviewWeb.Telemetry,
      Liveview.Repo,
      {DNSCluster, query: Application.get_env(:liveview, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Liveview.PubSub},
      {Finch, name: Liveview.Finch}
    ]

    opts = [strategy: :one_for_one, name: Liveview.Supervisor]
    {:ok, sup_pid} = Supervisor.start_link(children_without_endpoint, opts)

    # Run DB migrations on boot if MIGRATE=true
    maybe_run_migrations()

    # Start Endpoint under the running supervisor
    case Supervisor.start_child(sup_pid, LiveviewWeb.Endpoint.child_spec([])) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      {:error, reason} -> raise "Failed to start endpoint: #{inspect(reason)}"
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
    Application.ensure_all_started(:logger)
    Application.ensure_all_started(:ecto_sql)

    repos = Application.fetch_env!(:liveview, :ecto_repos)

    Enum.each(repos, fn repo ->
      IO.puts("Running migrations for #{inspect(repo)}")
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
