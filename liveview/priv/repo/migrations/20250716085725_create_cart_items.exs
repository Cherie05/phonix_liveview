defmodule Liveview.Repo.Migrations.CreateCartItems do
  use Ecto.Migration

  def change do
    create table(:cart_items) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :delete_all), null: false
      add :quantity, :integer, default: 1, null: false

      timestamps()
    end

    create index(:cart_items, [:user_id])
    create index(:cart_items, [:product_id])
    create unique_index(:cart_items, [:user_id, :product_id])
  end
end
