# lib/liveview_web/live/carousel_live.ex
defmodule LiveviewWeb.CarouselLive do
  use LiveviewWeb, :live_view

  embed_templates "templates/*"

  @impl true
  def mount(_params, _session, socket) do
    slides = [
      %{file: "1.jpg", alt: "Wild Landscape"},
      %{file: "2.jpg", alt: "Camera"},
      %{file: "3.jpg", alt: "Exotic Fruits"}
    ]

    socket =
      socket
      |> assign(slides: slides, current: 0)

    if connected?(socket), do: Process.send_after(self(), :tick, 5_000)
    {:ok, socket}
  end

  @impl true
  def handle_info(:tick, socket) do
    next = rem(socket.assigns.current + 1, length(socket.assigns.slides))
    Process.send_after(self(), :tick, 5_000)
    {:noreply, assign(socket, current: next)}
  end

  @impl true
  def handle_event("prev", _params, socket) do
    len = length(socket.assigns.slides)
    prev = rem(socket.assigns.current - 1 + len, len)
    {:noreply, assign(socket, current: prev)}
  end

  @impl true
  def handle_event("next", _params, socket) do
    next = rem(socket.assigns.current + 1, length(socket.assigns.slides))
    {:noreply, assign(socket, current: next)}
  end

  @impl true
  def handle_event("indicator", %{"index" => idx_str}, socket) do
    idx = String.to_integer(idx_str)
    {:noreply, assign(socket, current: idx)}
  end

  @impl true
  def render(assigns), do: carousel(assigns)
end
