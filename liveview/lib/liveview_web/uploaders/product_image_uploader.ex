defmodule Liveview.Uploaders.ProductImageUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original]

  # store files under "uploads/products/:id/"
  def storage_dir(version, {_file, %{id: id}}) do
    "uploads/products/#{id}/#{version}"
  end

  # only allow common image extensions
  def validate({%{file_name: name}, _}) do
    ~w(.jpg .jpeg .png .gif) |> Enum.member?(Path.extname(name))
  end
end
