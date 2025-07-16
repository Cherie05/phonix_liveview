defmodule LiveviewWeb.PageController do
  use LiveviewWeb, :controller

  alias Liveview.Accounts
  alias Liveview.Accounts.User
   alias Liveview.Catalog

  # run this before every action (or you can scope it to only :profile)
  plug :fetch_current_user

  # GET /signup
  def signup(conn, _params) do
    changeset = Accounts.change_user_registration(%User{})
    render(conn, :signup, changeset: changeset, layout: false)
  end

  # POST /signup
  def create_signup(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Welcome! Please log in.")
        |> redirect(to: ~p"/login")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :signup, changeset: changeset, layout: false)
    end
  end

  # GET /login
  def login(conn, _params) do
    render(conn, :login, error: nil, layout: false)
  end

  # POST /login
  def create_login(conn, %{"session" => %{"email" => email, "password" => pass}}) do
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

  # GET /home
  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

 # run before :cart to set conn.assigns.user
  plug :fetch_current_user when action in [:cart]

  # … your other actions …

  def cart(conn, _params) do
    user = conn.assigns.user

    # if nobody’s logged in, redirect to login
    if user == nil do
      conn
      |> put_flash(:error, "Please log in to view your cart.")
      |> redirect(to: ~p"/login")
    else
      # load cart items and compute total
      cart_items = Catalog.list_cart(user)
      total =
        cart_items
        |> Enum.reduce(Decimal.new(0), fn item, acc ->
          line_total = Decimal.mult(item.product.price, Decimal.new(item.quantity))
          Decimal.add(acc, line_total)
        end)

      render(conn, :cart,
        cart_items: cart_items,
        total: total,
        layout: false
      )
    end
  end

  def add_to_cart(conn, %{"id" => id}) do
  user = conn.assigns.current_user
  {:ok, _} = Catalog.add_to_cart(user, String.to_integer(id))
  redirect(conn, to: ~p"/cart")
end

def increment(conn, %{"id" => id}) do
   user = conn.assigns.user

  {:ok, _} = Catalog.update_cart_item(user, String.to_integer(id), +1)
  redirect(conn, to: ~p"/cart")
end

def decrement(conn, %{"id" => id}) do
   user = conn.assigns.user
  
  {:ok, _} = Catalog.update_cart_item(user, String.to_integer(id), -1)
  redirect(conn, to: ~p"/cart")
end

def remove_from_cart(conn, %{"id" => id}) do
  user = conn.assigns.user      # ← here, not :current_user
  {:ok, _} = Catalog.remove_from_cart(user, String.to_integer(id))

  conn
  |> put_flash(:info, "Removed from cart.")
  |> redirect(to: ~p"/cart")
end


  # POST /logout
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You’ve been logged out.")
    |> redirect(to: ~p"/login")
  end

  # GET /profile
  def profile(conn, _params) do
    render(conn, :profile, user: conn.assigns.user, layout: false)
  end

  # --------------------------------------------------
  # Private plug
  # --------------------------------------------------
  defp fetch_current_user(conn, _opts) do
    user =
      conn
      |> get_session(:user_id)
      |> case do
        nil -> nil
        id  -> Accounts.get_user!(id)
      end

    assign(conn, :user, user)
  end
end
