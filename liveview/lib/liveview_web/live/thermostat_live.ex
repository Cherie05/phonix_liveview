defmodule LiveviewWeb.ThermostatLive do
  use LiveviewWeb, :live_view

  # ⬇️ nothing but the macro and the pattern
  embed_templates "templates/*"

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, temperature: 68), layout: false}
  end

  @impl true
  def handle_event("inc_temperature", _params, socket) do
    {:noreply, update(socket, :temperature, &(&1 + 1))}
  end

  # The file “thermostat.html.heex” turns into a function named `thermostat/1`
  @impl true
  def render(assigns), do: thermostat(assigns)
end
