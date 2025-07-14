# lib/liveview_web/error_helpers.ex
defmodule LiveviewWeb.ErrorHelpers do
  # bring in content_tag/3, tag/2, etc.
  use PhoenixHTMLHelpers

  @doc """
  Generates inlined form error tags for a given field.
  """
  def error_tag(form, field) do
    form.errors
    |> Keyword.get_values(field)
    |> Enum.map(fn {msg, _opts} ->
      content_tag(:span, msg, class: "text-red-600 text-sm")
    end)
  end
end
