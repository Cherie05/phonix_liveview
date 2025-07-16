defmodule LiveviewWeb.NavbarLive do
  use LiveviewWeb, :live_view
  alias Liveview.Accounts
  alias Liveview.Catalog

  embed_templates "templates/*"

  @impl true
  def mount(_params, session, socket) do
    socket =
      socket
      |> assign(:menu_open, false)
      |> assign_current_user(session)

    # If there's a logged-in user, subscribe to their cart topic
    socket =
      case socket.assigns[:current_user] do
        %{id: user_id} = user ->
          if connected?(socket) do
            Phoenix.PubSub.subscribe(Liveview.PubSub, "cart:#{user_id}")
          end

          # Assign initial cart count
          count = Catalog.count_cart_items(user)
          assign(socket, cart_count: count)

        _ ->
          # No user → no cart items
          assign(socket, cart_count: 0)
      end

    {:ok, socket, layout: false}
  end

  @impl true
  def handle_event("toggle_menu", _params, socket) do
    {:noreply, update(socket, :menu_open, &(!&1))}
  end

  @impl true
  def handle_event("close_menu", _params, socket) do
    {:noreply, assign(socket, :menu_open, false)}
  end

  @impl true
  def handle_info({:cart_updated, new_count}, socket) do
    {:noreply, assign(socket, cart_count: new_count)}
  end

  defp assign_current_user(socket, %{"user_id" => id}) when not is_nil(id) do
    case Accounts.get_user(id) do
      nil -> socket
      user -> assign(socket, :current_user, user)
    end
  end
  defp assign_current_user(socket, _), do: socket

  @impl true
  def render(assigns), do: navbar(assigns)
end
