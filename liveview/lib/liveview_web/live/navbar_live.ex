defmodule LiveviewWeb.NavbarLive do
  use LiveviewWeb, :live_view
  alias Liveview.Accounts

  # will compile any *.html.heex under navbar_live_html/
  embed_templates "templates/*"


  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:menu_open, false)
      |> assign_current_user(session)

    {:ok, socket}
  end

  defp assign_current_user(socket, %{"user_id" => id}) do
    case Accounts.get_user(id) do
      nil   -> socket
      user  -> assign(socket, :current_user, user)
    end
  end
  defp assign_current_user(socket, _), do: socket

  @impl true
  def handle_event("toggle_menu", _params, socket) do
    {:noreply, update(socket, :menu_open, &(!&1))}
  end


  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, menu_open: false), layout: false}
  end

  @impl true
  def handle_event("toggle_menu", _params, socket) do
    {:noreply, update(socket, :menu_open, &(!&1))}
  end

  @impl true
  def handle_event("close_menu", _params, socket) do
    {:noreply, assign(socket, menu_open: false)}
  end

  @impl true
  # renders navbar.html.heex → navbar(assigns)
  def render(assigns), do: navbar(assigns)
end
