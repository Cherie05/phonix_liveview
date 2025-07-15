defmodule Liveview.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :category, :string
      add :price, :decimal
      add :image_url, :string

      timestamps(type: :utc_datetime)
    end
  end
end
