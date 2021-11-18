defmodule APIWeb.ErrorViewTest do
  @moduledoc false

  use APIWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert %{code: :not_found, message: "Resource not found.", status_code: 404} =
             render(APIWeb.ErrorView, "404.json", [])
  end

  test "renders 500.json" do
    assert %{code: :internal_server_error, message: "Internal server error", status_code: 500} =
             render(APIWeb.ErrorView, "500.json", [])
  end
end
