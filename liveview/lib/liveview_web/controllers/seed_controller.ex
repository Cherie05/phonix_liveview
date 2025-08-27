defmodule LiveviewWeb.SeedController do
  use LiveviewWeb, :controller
  alias Liveview.Repo
  alias Liveview.Catalog.Product

  @uploads_dir Path.expand("./uploads/products")
  @seed_src    Path.expand("priv/seed_uploads/products")

  def seed(conn, %{"token" => token}) do
    expected = System.get_env("SEED_TOKEN") || ""

    if token != "" and token == expected do
      File.mkdir_p!(@uploads_dir)
      copy_sample_uploads!()
      inserted = seed_products_if_empty!()

      text(conn, "Seed ok. Copied uploads and inserted #{inserted} products (0 means already present).")
    else
      conn |> put_status(:forbidden) |> text("Forbidden. Set SEED_TOKEN env and pass ?token=...")
    end
  end

  def seed(conn, _params) do
    conn |> put_status(:bad_request) |> text("Missing token. Use /seed?token=YOUR_TOKEN")
  end

  defp copy_sample_uploads! do
    if File.exists?(@seed_src) do
      for f <- File.ls!(@seed_src) do
        File.cp!(Path.join(@seed_src, f), Path.join(@uploads_dir, f))
      end
    end
  end

  defp seed_products_if_empty! do
    # Insert only when table is empty (idempotent).
    if Repo.aggregate(Product, :count, :id) == 0 do
      now = DateTime.utc_now() |> DateTime.truncate(:second)

      items = [
        {"Blue T-Shirt", "Apparel", Decimal.new("19.99"), "blue-shirt.jpg"},
        {"Red Hoodie", "Apparel", Decimal.new("39.99"), "red-hoodie.jpg"},
        {"Running Shoes", "Footwear", Decimal.new("59.99"), "shoes.jpg"},
        {"Coffee Mug", "Home", Decimal.new("9.99"), "mug.jpg"},
        {"Wireless Mouse", "Electronics", Decimal.new("24.99"), "mouse.jpg"}
      ]

      Enum.reduce(items, 0, fn {name, cat, price, file}, acc ->
        attrs =
          if File.exists?(Path.join(@uploads_dir, file)) do
            %{
              name: name, category: cat, price: price,
              image: %Plug.Upload{filename: file, path: Path.join(@uploads_dir, file)},
              inserted_at: now, updated_at: now
            }
          else
            %{name: name, category: cat, price: price, inserted_at: now, updated_at: now}
          end

        case %Product{} |> Product.changeset(attrs) |> Repo.insert() do
          {:ok, _} -> acc + 1
          {:error, _} -> acc
        end
      end)
    else
      0
    end
  end
end
