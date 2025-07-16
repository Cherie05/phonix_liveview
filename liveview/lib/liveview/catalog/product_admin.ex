defmodule Liveview.Catalog.ProductAdmin do
  @behaviour Kaffy.ResourceAdmin

  # columns in the index table
  def index(_schema) do
    [
      id:         %{label: "ID"},
      name:       %{label: "Name"},
      category:   %{label: "Category"},
      price:      %{label: "Price"},
      inserted_at: %{label: "Created At"}
    ]
  end

  # fields on the new/edit form
  def form_fields(_schema) do
    [
      name:       %{},
      category:   %{},
      price:      %{type: :decimal},
       image:      %{type: :file} 
    ]
  end
end
