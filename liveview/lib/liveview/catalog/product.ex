defmodule Liveview.Catalog.Product do
  use Ecto.Schema
  import Ecto.Changeset
  use Waffle.Ecto.Schema

  schema "products" do
    field :name, :string
    field :category, :string
    field :price, :decimal
    field :image, Liveview.Uploaders.ProductImageUploader.Type


    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :category, :price])
    |> cast_attachments(attrs, [:image])
    |> validate_required([:name, :category, :price])
  end
end
