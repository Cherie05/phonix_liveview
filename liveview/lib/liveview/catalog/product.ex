defmodule Liveview.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :category, :string
    field :price, :decimal
    field :image_url, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :category, :price, :image_url])
    |> validate_required([:name, :category, :price, :image_url])
  end
end
