defmodule Liveview.Catalog do
  @moduledoc """
  The Catalog context, for products, shopping cart, and orders.
  """

  import Ecto.Query, warn: false
  alias Ecto.Multi
  alias Liveview.Repo

  alias Liveview.Accounts.User
  alias Liveview.Catalog.{Product, CartItem, Order, OrderItem}

  @doc "Count total quantity in a user's cart"
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

  # --- Cart operations ---

  @doc "Add a product to the user's cart (or increment if already present)"
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

  @doc "Clear all items from the user's cart"
  def clear_cart(%User{id: user_id}) do
    CartItem
    |> where([ci], ci.user_id == ^user_id)
    |> Repo.delete_all()
  end

  # --- Order operations ---

  @doc """
  Create an Order from the user's cart:
    1. calculate subtotal, shipping, and total
    2. insert an `orders` row
    3. insert one `order_items` per cart item
    4. clear the cart
  Returns `{:ok, %{order: order, order_items: items}}` or `{:error, step, reason, changes}`.
  """
  def create_order_from_cart(%User{id: user_id} = user) do
    items = list_cart(user)

    subtotal =
      items
      |> Enum.reduce(Decimal.new(0), fn ci, acc ->
        Decimal.add(acc, Decimal.mult(ci.product.price, Decimal.new(ci.quantity)))
      end)

    shipping = Decimal.new(0)
    total    = Decimal.add(subtotal, shipping)

    Multi.new()
    |> Multi.insert(:order, Order.changeset(%Order{}, %{
         user_id:  user_id,
         subtotal: subtotal,
         shipping: shipping,
         total:    total
       }))
    |> Multi.run(:order_items, fn repo, %{order: order} ->
         items
         |> Enum.map(fn ci ->
              OrderItem.changeset(%OrderItem{}, %{
                order_id:   order.id,
                product_id: ci.product_id,
                unit_price: ci.product.price,
                quantity:   ci.quantity
              })
            end)
         |> Enum.reduce_while({:ok, []}, fn changeset, {:ok, acc} ->
              case repo.insert(changeset) do
                {:ok, item} -> {:cont, {:ok, [item | acc]}}
                {:error, reason} -> {:halt, {:error, reason}}
              end
            end)
       end)
    |> Multi.delete_all(:clear_cart,
         from(ci in CartItem, where: ci.user_id == ^user_id)
       )
    |> Repo.transaction()
  end

  @doc "List all orders for a user, newest first, with their items and products preloaded."
  def list_user_orders(%User{id: uid}) do
    Order
    |> where([o], o.user_id == ^uid)
    |> order_by(desc: :inserted_at)
    |> preload(order_items: [:product])
    |> Repo.all()
  end

  # --- Product CRUD ---

  @doc "List all products"
  def list_products, do: Repo.all(Product)

  @doc "Get a single product by id, or raise if not found"
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
