defmodule Liveview.Repo.Migrations.CreateOrdersAndOrderItems do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :user_id, references(:users, on_delete: :delete_all), null: false
      add :subtotal, :decimal, null: false
      add :shipping, :decimal, null: false
      add :total,    :decimal, null: false

      timestamps()
    end

    create table(:order_items) do
      add :order_id,   references(:orders, on_delete: :delete_all), null: false
      add :product_id, references(:products),                      null: false
      add :unit_price, :decimal,                                   null: false
      add :quantity,   :integer,                                   null: false

      timestamps()
    end

    create index(:orders, [:user_id])
    create index(:order_items, [:order_id])
  end
end
