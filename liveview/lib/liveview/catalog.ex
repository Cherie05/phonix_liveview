defmodule Liveview.Catalog do
  @moduledoc """
  The Catalog context, for products and shopping cart operations.
  """

  import Ecto.Query, warn: false
  alias Liveview.Repo
  alias Liveview.Catalog.{Product, CartItem}
  alias Liveview.Accounts.User

  @doc "Add a product to the user's cart (increment if already present)"
  def add_to_cart(%User{id: user_id}, product_id) do
    case Repo.get_by(CartItem, user_id: user_id, product_id: product_id) do
      nil ->
        %CartItem{}
        |> CartItem.changeset(%{user_id: user_id, product_id: product_id, quantity: 1})
        |> Repo.insert()

      %CartItem{} = item ->
        item
        |> CartItem.changeset(%{quantity: item.quantity + 1})
        |> Repo.update()
    end
  end

  @doc "List all cart items for a given user, preloading the product"
  def list_cart(%User{id: user_id}) do
    CartItem
    |> where([ci], ci.user_id == ^user_id)
    |> preload(:product)
    |> Repo.all()
  end

  @doc "Increment or decrement the quantity of a cart item by `delta`"
  def update_cart_item(%User{id: user_id}, product_id, delta) when is_integer(delta) do
    case Repo.get_by(CartItem, user_id: user_id, product_id: product_id) do
      nil ->
        {:error, :not_found}

      %CartItem{} = item ->
        new_qty = max(1, item.quantity + delta)

        item
        |> CartItem.changeset(%{quantity: new_qty})
        |> Repo.update()
    end
  end

  @doc "Remove an item from the cart"
  def remove_from_cart(%User{id: user_id}, product_id) do
    case Repo.get_by(CartItem, user_id: user_id, product_id: product_id) do
      nil ->
        {:error, :not_found}

      item ->
        Repo.delete(item)
    end
  end

  @doc "Count total quantity in cart"
  def count_cart_items(%User{id: user_id}) do
    CartItem
    |> where([ci], ci.user_id == ^user_id)
    |> select([ci], sum(ci.quantity))
    |> Repo.one()
    |> case do
      nil -> 0
      sum -> sum
    end
  end

  # --- Product CRUD ---

  @doc "List all products"
  def list_products do
    Repo.all(Product)
  end

  @doc "Get a single product by id"
  def get_product!(id), do: Repo.get!(Product, id)

  @doc "Create a product"
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  @doc "Update a product"
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc "Delete a product"
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc "Return a changeset for tracking product changes"
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
