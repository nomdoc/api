defmodule APIWeb.OAuthControllerTest do
  @moduledoc false

  use APIWeb.ConnCase

  @token_endpoint "/oauth/token"

  describe "POST /oauth/token" do
    test "with unsupported grant type." do
      body =
        build_conn()
        |> post(@token_endpoint, grant_type: Faker.String.base64())
        |> json_response(422)

      assert body["code"] == "unsupported_grant_type"
      assert body["message"] == "Please provide valid grant type."
      assert body["statusCode"] == 422
    end
  end
end
