defmodule LiveviewWeb.HomeLive do
  use LiveviewWeb, :live_view
  alias Liveview.Accounts
  alias LiveviewWeb.HomeLiveHTML, as: HTML

  embed_templates "templates/*"


  alias Liveview.Catalog

  @impl true
  def mount(_params, _session, socket) do
    products = Catalog.list_products()
    {:ok, assign(socket, products: products), layout: false}
  end

  @impl true
  def mount(_params, session, socket) do
    case session["user_id"] do
      nil ->
        # no session → redirect
        {:ok, redirect(socket, to: ~p"/login")}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            # invalid user → redirect
            {:ok, redirect(socket, to: ~p"/login")}

          user ->
            # authenticated → assign and render
            socket =
              socket
              |> assign(:current_user, user)
              |> assign(:dropdown_open, false)
              |> assign(:temperature, 70)

            {:ok, socket, layout: false}
        end
    end
  end

  @impl true
  def render(assigns), do: HTML.home(assigns)
end
