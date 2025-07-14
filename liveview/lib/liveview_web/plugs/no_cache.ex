defmodule LiveviewWeb.Plugs.NoCache do
  @moduledoc """
  A Plug to disable browser caching so that after logout
  pressing “Back” always re‐requests the page (and can then
  redirect to login).
  """

  import Plug.Conn

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    conn
    |> put_resp_header("cache-control", "no-store, no-cache, must-revalidate")
    |> put_resp_header("pragma",        "no-cache")
  end
end
