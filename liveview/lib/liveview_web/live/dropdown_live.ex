defmodule LiveviewWeb.DropdownLive do
  use LiveviewWeb, :live_view

  # compile any *.html.heex in dropdown_live_html/
  embed_templates "templates/*"

  def mount(_params, _session, socket) do
  socket =
    socket
    |> assign(:dropdown_open, false)
    |> assign(:csrf_token, Plug.CSRFProtection.get_csrf_token())

  {:ok, socket, layout: false}
end


  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, dropdown_open: false)}
  end

  @impl true
  def handle_event("toggle", _params, socket) do
    {:noreply, update(socket, :dropdown_open, &(!&1))}
  end

  @impl true
  def handle_event("close", _params, socket) do
    {:noreply, assign(socket, :dropdown_open, false)}
  end

  @impl true
  # renders dropdown.html.heex → dropdown(assigns)
  def render(assigns), do: dropdown(assigns)
end
