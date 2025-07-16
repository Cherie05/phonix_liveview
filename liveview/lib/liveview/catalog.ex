defmodule Liveview.Catalog do
  @moduledoc """
  The Catalog context.
  """

  import Ecto.Query, warn: false
  alias Liveview.Repo

  alias Liveview.Catalog.Product
   alias Liveview.Catalog.CartItem


    @doc "Add a product to the user's cart (increment if already present)"
  def add_to_cart(%Liveview.Accounts.User{id: user_id}, product_id) do
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

  @doc "List a user's cart items, preloading products"
  def list_cart(user) do
    CartItem
    |> where(user_id: ^user.id)
    |> preload(:product)
    |> Repo.all()
  end

  @doc "Remove an item from the cart"
  def remove_from_cart(%Liveview.Accounts.User{} = user, product_id) do
    Repo.get_by(CartItem, user_id: user.id, product_id: product_id)
    |> case do
      nil   -> {:error, :not_found}
      item  -> Repo.delete(item)
    end
  end


  @doc """
  Returns the list of products.

  ## Examples

      iex> list_products()
      [%Product{}, ...]

  """
  def list_products do
    Repo.all(Product)
  end

  @doc """
  Gets a single product.

  Raises `Ecto.NoResultsError` if the Product does not exist.

  ## Examples

      iex> get_product!(123)
      %Product{}

      iex> get_product!(456)
      ** (Ecto.NoResultsError)

  """
  def get_product!(id), do: Repo.get!(Product, id)

  @doc """
  Creates a product.

  ## Examples

      iex> create_product(%{field: value})
      {:ok, %Product{}}

      iex> create_product(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_product(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def count_cart_items(%Liveview.Accounts.User{id: user_id}) do
  from(ci in CartItem, where: ci.user_id == ^user_id, select: sum(ci.quantity))
  |> Repo.one()
  |> case do
    nil -> 0
    sum -> sum
  end
end


  @doc """
  Updates a product.

  ## Examples

      iex> update_product(product, %{field: new_value})
      {:ok, %Product{}}

      iex> update_product(product, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_product(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a product.

  ## Examples

      iex> delete_product(product)
      {:ok, %Product{}}

      iex> delete_product(product)
      {:error, %Ecto.Changeset{}}

  """
  def delete_product(%Product{} = product) do
    Repo.delete(product)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking product changes.

  ## Examples

      iex> change_product(product)
      %Ecto.Changeset{data: %Product{}}

  """
  def change_product(%Product{} = product, attrs \\ %{}) do
    Product.changeset(product, attrs)
  end
end
