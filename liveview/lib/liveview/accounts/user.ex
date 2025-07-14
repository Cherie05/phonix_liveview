defmodule Liveview.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :first_name, :string
    field :last_name,  :string
    field :email,      :string
    field :password,   :string, virtual: true
    field :password_confirmation, :string, virtual: true
    field :password_hash, :string

    timestamps()
  end

  @doc """
  A changeset for registration, hashing the password.
  """
  def registration_changeset(user, attrs) do
    user
    |> cast(attrs, ~w(first_name last_name email password password_confirmation)a)
    |> validate_required(~w(first_name last_name email password password_confirmation)a)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 6)
    |> validate_confirmation(:password)
    |> unique_constraint(:email)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: pw}} = cs) do
    change(cs, password_hash: Argon2.hash_pwd_salt(pw))
  end
  defp put_pass_hash(cs), do: cs
end
