defmodule Liveview.Accounts.UserAdmin do
  @behaviour Kaffy.ResourceAdmin

  # Customize the index table columns:
  def index(_schema) do
    [
      id:             %{label: "ID"},
      first_name:     %{label: "First Name"},
      last_name:      %{label: "Last Name"},
      email:          %{label: "Email"},
      inserted_at:    %{label: "Signed Up At"}
    ]
  end

  # Customize the new/edit form fields:
  def form_fields(_schema) do
    [
      first_name:            %{},
      last_name:             %{},
      email:                 %{},
      password:              %{type: :password},
      password_confirmation: %{type: :password}
    ]
  end
end
