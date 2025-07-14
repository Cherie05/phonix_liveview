defmodule Liveview.Accounts do
  @moduledoc "The Accounts context"

  import Ecto.Query, warn: false
  alias Liveview.Repo
  alias Liveview.Accounts.User

  @doc "Returns a user registration changeset"
  def change_user_registration(%User{} = user) do
    User.registration_changeset(user, %{})
  end

  @doc "Creates a new user"
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Checks email/password"
  def authenticate_user(email, pass) do
    case Repo.get_by(User, email: email) do
      %User{} = user ->
        if Argon2.verify_pass(pass, user.password_hash), do: {:ok, user}, else: {:error, :invalid_credentials}
      nil ->
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
    end
  end

   @doc """
  Fetches a user by ID. Returns `nil` if no such user exists.
  Accepts either an integer or a string ID from the session.
  """
  def get_user(id) when is_integer(id) do
    Repo.get(User, id)
  end

  def get_user(id) when is_binary(id) do
    case Integer.parse(id) do
      {int, ""} -> get_user(int)
      _ -> nil
    end
  end

  
end
