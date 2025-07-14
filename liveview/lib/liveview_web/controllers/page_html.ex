defmodule LiveviewWeb.PageHTML do
  use LiveviewWeb, :html

  # bring in form helpers: form_for, label, text_input, etc.
  import Phoenix.HTML.Form

  # bring in your error_tag/2
  import LiveviewWeb.ErrorHelpers

  # bring in content_tag, tag, csrf_meta_tag, etc.
  use PhoenixHTMLHelpers

  # alias your route helpers
  alias LiveviewWeb.Router.Helpers, as: Routes

  # compile all page_html/*.heex into matching functions
  embed_templates "page_html/*"
end
