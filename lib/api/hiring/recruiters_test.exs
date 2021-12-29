defmodule API.RecruitersTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Recruiter
  alias API.Recruiters

  describe "get_or_create/1" do
    test "creates a recruiter if not exists." do
      assert {:ok, %Recruiter{} = recruiter} = Recruiters.get_recruiter("user_123")

      recruiter = Repo.preload(recruiter, [:jobs])

      assert recruiter.new?
      assert recruiter.entity_id == "user_123"
      assert Enum.empty?(recruiter.jobs)
    end

    test "returns the user if user has already been created." do
      assert {:ok, %Recruiter{id: recruiter_id}} = Recruiters.get_recruiter("user_123")

      assert {:ok, %Recruiter{id: ^recruiter_id, new?: false}} =
               Recruiters.get_recruiter("user_123")
    end
  end
end
