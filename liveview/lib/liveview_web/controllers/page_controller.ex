defmodule LiveviewWeb.PageController do
  use LiveviewWeb, :controller

  alias Liveview.Accounts
  alias Liveview.Accounts.User

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

  # your home action...
  def home(conn, _params) do
    render(conn, :home, layout: false)
  end

    @doc """
  Logs the user out by dropping the session,
  then redirects to the login page.
  """
  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You’ve been logged out.")
    |> redirect(to: ~p"/login")
  end
end
