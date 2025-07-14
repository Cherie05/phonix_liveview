defmodule LiveviewWeb.NavbarLive do
  use LiveviewWeb, :live_view

  # will compile any *.html.heex under navbar_live_html/
  embed_templates "templates/*"

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
