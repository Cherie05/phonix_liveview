
# priv/repo/seeds.exs
alias Liveview.Repo
alias Liveview.Catalog.Product
import Ecto.Query

products = [
  %{name: "Blue T-Shirt", category: "Clothing", price: "19.99"},
  %{name: "Red Hoodie", category: "Clothing", price: "39.50"},
  %{name: "Running Shoes", category: "Footwear", price: "89.99"},
  %{name: "Coffee Mug", category: "Home", price: "12.00"},
  %{name: "Wireless Mouse", category: "Electronics", price: "25.00"}
]

for p <- products do
  attrs = Map.update!(p, :price, &Decimal.new/1)

  case Repo.get_by(Product, name: attrs.name) do
    nil ->
      %Product{}
      |> Product.changeset(attrs)
      |> Repo.insert!()
      IO.puts("Inserted product: #{attrs.name}")

    _existing ->
      IO.puts("Skipping (already exists): #{attrs.name}")
  end
end

IO.puts("Product seeding finished.")
EOF
