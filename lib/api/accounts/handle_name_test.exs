defmodule API.HandleNameTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.HandleName

  describe "changeset/2" do
    test "validates value is unique." do
      assert {:ok, %HandleName{}} =
               HandleName.changeset(%HandleName{}, %{value: "meow"})
               |> Repo.insert()

      assert {:error, %Changeset{} = changeset} =
               HandleName.changeset(%HandleName{}, %{value: "meow"})
               |> Repo.insert()

      assert errors_on(changeset)[:value] == ["has already been taken"]
    end
  end
end
