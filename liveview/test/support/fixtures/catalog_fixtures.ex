defmodule Liveview.CatalogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Liveview.Catalog` context.
  """

  @doc """
  Generate a product.
  """
  def product_fixture(attrs \\ %{}) do
    {:ok, product} =
      attrs
      |> Enum.into(%{
        category: "some category",
        image_url: "some image_url",
        name: "some name",
        price: "120.5"
      })
      |> Liveview.Catalog.create_product()

    product
  end
end
