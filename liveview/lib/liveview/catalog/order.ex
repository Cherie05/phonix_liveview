defmodule Liveview.Catalog.Order do
  use Ecto.Schema
  import Ecto.Changeset

  alias Liveview.Accounts.User
  alias Liveview.Catalog.OrderItem

  schema "orders" do
    belongs_to :user, User
    has_many   :order_items, OrderItem

    field :subtotal, :decimal
    field :shipping, :decimal
    field :total,    :decimal

    timestamps()
  end

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:user_id, :subtotal, :shipping, :total])
    |> validate_required([:user_id, :subtotal, :shipping, :total])
  end
end
