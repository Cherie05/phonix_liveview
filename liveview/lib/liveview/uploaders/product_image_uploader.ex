defmodule Liveview.Uploaders.ProductImageUploader do
  use Waffle.Definition
  use Waffle.Ecto.Definition

  @versions [:original] # add :thumb if you want
  @exts ~w(.jpg .jpeg .png .webp .gif)

  def validate({file, _scope}) do
    ext =
      file.file_name
      |> Path.extname()
      |> String.downcase()

    ext in @exts
  end

  # Store under /app/uploads/products (served at /uploads by Plug.Static)
  def storage_dir(_version, {_file, _scope}), do: "uploads/products"

  # Optional prettier filenames
  def filename(_version, {file, _scope}) do
    base = file.file_name |> Path.basename(Path.extname(file.file_name))
    "#{base}-#{System.system_time(:millisecond)}"
  end
end
