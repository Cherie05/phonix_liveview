defmodule LiveviewWeb.PageController do
  use LiveviewWeb, :controller

  alias Liveview.Accounts
  alias Liveview.Accounts.User
  alias Liveview.Catalog

  # Always fetch the current user into `conn.assigns.user`
  plug :fetch_current_user

  # — Signup —

  def signup(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :signup, changeset: changeset, layout: false)
  end

  def create_signup(conn, %{"user" => params}) do
    case Accounts.register_user(params) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Welcome! Please log in.")
        |> redirect(to: ~p"/login")

      {:error, %Ecto.Changeset{} = cs} ->
        render(conn, :signup, changeset: cs, layout: false)
    end
  end

  # — Login —

  def login(conn, _), do: render(conn, :login, error: nil, layout: false)

  # Matches only when both are binaries
  def create_login(conn, %{"session" => %{"email" => email, "password" => pass}})
      when is_binary(email) and is_binary(pass) do
    case Accounts.authenticate_user(email, pass) do
      {:ok, user} ->
        conn
        |> put_session(:user_id, user.id)
        |> configure_session(renew: true)
        |> put_flash(:info, "Logged in successfully.")
        |> redirect(to: ~p"/home")

      {:error, :invalid_credentials} ->
        render(conn, :login, error: "Invalid email or password", layout: false)
    end
  end

  # Fallback if params are missing or wrong shape
  def create_login(conn, _), do:
    render(conn, :login, error: "Please enter both email and password", layout: false)

  # — Logout —

  def logout(conn, _), do:
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You’ve been logged out.")
    |> redirect(to: ~p"/login")

  # — Home —

  def home(conn, _), do: render(conn, :home, layout: false)


  # — Cart —

  def cart(conn, _params) do
    case conn.assigns.user do
      nil ->
        conn
        |> put_flash(:error, "Please log in to view your cart.")
        |> redirect(to: ~p"/login")

      user ->
        items = Catalog.list_cart(user)
        total =
          items
          |> Enum.reduce(Decimal.new(0), fn ci, acc ->
            Decimal.add(acc, Decimal.mult(ci.product.price, Decimal.new(ci.quantity)))
          end)

        render(conn, :cart, cart_items: items, total: total, layout: false)
    end
  end

  # — Checkout & Purchase —

  def checkout(conn, _params) do
    user = conn.assigns.user

    items = Catalog.list_cart(user)
    subtotal =
      Enum.reduce(items, Decimal.new(0), fn ci, acc ->
        Decimal.add(acc, Decimal.mult(ci.product.price, Decimal.new(ci.quantity)))
      end)
    shipping = Decimal.new(0)
    total    = Decimal.add(subtotal, shipping)

    render(conn, :checkout,
      cart_items: items,
      subtotal:   subtotal,
      shipping:   shipping,
      total:      total,
      layout:     false
    )
  end

  def complete_purchase(conn, _params) do
    user = conn.assigns.user

    case Catalog.create_order_from_cart(user) do
      {:ok, %{order: order}} ->
        conn
        |> put_status(:ok)
        |> json(%{status: "ok", order_id: order.id})

      {:error, _step, reason, _} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{status: "error", reason: inspect(reason)})
    end
  end

  # GET /profile
def profile(conn, _params) do
  case conn.assigns.user do
    %User{} = user ->
      render(conn, :profile, user: user, layout: false)

    nil ->
      conn
      |> put_flash(:error, "You must be logged in to view your profile.")
      |> redirect(to: ~p"/login")
  end
end

  # — Order History —

  def order_history(conn, _params) do
    case conn.assigns.user do
      %User{} = u ->
        orders = Catalog.list_user_orders(u)
        render(conn, :order_history, orders: orders, layout: false)

      nil ->
        conn
        |> put_flash(:error, "Please log in to view your order history.")
        |> redirect(to: ~p"/login")
    end
  end

  # — Private plug —

defp fetch_current_user(conn, _opts) do
  user =
    case get_session(conn, :user_id) do
      nil -> nil
      id  -> Accounts.get_user(id)
    end

  assign(conn, :user, user)
end
end
