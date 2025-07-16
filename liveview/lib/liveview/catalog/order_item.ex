defmodule Liveview.Catalog.OrderItem do
  use Ecto.Schema
  import Ecto.Changeset

  alias Liveview.Catalog.{Order, Product}

  schema "order_items" do
    belongs_to :order,   Order
    belongs_to :product, Product

    field :unit_price, :decimal
    field :quantity,   :integer

    timestamps()
  end

  def changeset(item, attrs) do
    item
    |> cast(attrs, [:order_id, :product_id, :unit_price, :quantity])
    |> validate_required([:order_id, :product_id, :unit_price, :quantity])
  end
end
