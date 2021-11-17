defmodule APIWeb.OAuthControllerTest do
  @moduledoc false

  use APIWeb.ConnCase

  describe "POST /oauth/authorize" do
    test "with 'login_token' response type and valid email address." do
      body =
        build_conn()
        |> post("/oauth/authorize",
          responseType: "login_token",
          email_address: "example@gmail.com"
        )
        |> json_response(200)

      assert body["emailAddress"] == "example@gmail.com"
    end

    test "with invalid email address." do
      body =
        build_conn()
        |> post("/oauth/authorize",
          responseType: "login_token",
          email_address: "invalid_email@blala"
        )
        |> json_response(422)

      assert body["code"] == "failed_validation"
      assert body["message"] == "Failed validation."
      assert body["statusCode"] == 422
      assert length(body["errors"]) == 1

      assert %{"field" => "emailAddress", "message" => "Email address is invalid."} =
               hd(body["errors"])
    end

    test "with unsupported response type." do
      body =
        build_conn()
        |> post("/oauth/authorize", responseType: "random_resp_type")
        |> json_response(422)

      assert body["code"] == "unsupported_response_type"
      assert body["message"] == "Please provide valid response type."
      assert body["statusCode"] == 422
    end
  end
end
