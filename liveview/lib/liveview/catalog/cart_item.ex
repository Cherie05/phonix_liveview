defmodule Liveview.Catalog.CartItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cart_items" do
    field :quantity, :integer, default: 1

    belongs_to :user, Liveview.Accounts.User
    belongs_to :product, Liveview.Catalog.Product

    timestamps()
  end

  @doc false
  def changeset(item, attrs) do
    item
    |> cast(attrs, [:user_id, :product_id, :quantity])
    |> validate_required([:user_id, :product_id, :quantity])
    |> unique_constraint([:user_id, :product_id], name: :cart_items_user_id_product_id_index)
  end
end
