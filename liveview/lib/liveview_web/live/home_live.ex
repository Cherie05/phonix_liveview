defmodule LiveviewWeb.HomeLive do
  use LiveviewWeb, :live_view

  alias Liveview.Accounts
  alias Liveview.Catalog
  alias Liveview.Catalog.CartItem
  alias LiveviewWeb.HomeLiveHTML, as: HTML

  embed_templates "templates/*"

  @impl true
  def mount(_params, session, socket) do
    case session["user_id"] do
      nil ->
        # not logged in → send to login
        {:ok, push_redirect(socket, to: ~p"/login"), layout: false}

      user_id ->
        case Accounts.get_user(user_id) do
          nil ->
            # invalid session → send to login
            {:ok, push_redirect(socket, to: ~p"/login"), layout: false}

          user ->
            # load products and cart
            products = Catalog.list_products()
            cart     = Catalog.list_cart(user)

            socket =
              socket
              |> assign(:current_user, user)
              |> assign(:products, products)
              |> assign(:cart, cart)

            {:ok, socket, layout: false}
        end
    end
  end

  @impl true
  def handle_event("add_to_cart", %{"product_id" => pid}, %{assigns: %{current_user: user}} = socket) do
    pid = String.to_integer(pid)

    case Catalog.add_to_cart(user, pid) do
      {:ok, _item} ->
        # refresh cart
        new_cart = Catalog.list_cart(user)

        {:noreply,
         socket
         |> assign(:cart, new_cart)
         |> put_flash(:info, "Added to cart!")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not add to cart")}
    end
  end

  def handle_event("add_to_cart", %{"product_id" => pid}, %{assigns: %{current_user: user}} = socket) do
  pid = String.to_integer(pid)

  case Catalog.add_to_cart(user, pid) do
    {:ok, _item} ->
      # refresh cart_count
      new_count = Catalog.count_cart_items(user)

      # broadcast to "cart:USER_ID" topic
      Phoenix.PubSub.broadcast(
        Liveview.PubSub,
        "cart:#{user.id}",
        {:cart_updated, new_count}
      )

      # also update this LiveView’s own assigns if you render a cart list here
      {:noreply,
       socket
       |> assign(:cart_count, new_count)
       |> put_flash(:info, "Added to cart!")}
    {:error, _} ->
      {:noreply, put_flash(socket, :error, "Could not add to cart")}
  end
end

  @impl true
  def render(assigns), do: HTML.home(assigns)
end
