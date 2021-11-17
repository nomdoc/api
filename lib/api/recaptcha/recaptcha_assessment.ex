defmodule API.RecaptchaAssessment do
  @moduledoc false

  use TypedStruct
  use Domo

  typedstruct do
    field :score, number(), enforce: true
    field :valid?, boolean(), enforce: true
    field :invalid_reason, binary()
  end
end
