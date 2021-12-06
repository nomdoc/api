defmodule API.JobListingsTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Job
  alias API.JobListings

  describe "create_job/2" do
    test "creates a job." do
      recruiter = insert(:recruiter)

      assert {:ok, %Job{} = job} =
               JobListings.create_job(recruiter.entity_id, %{
                 employment_type: :full_time,
                 title: "Permanent GP Needed"
               })

      assert job.status == :draft
    end
  end
end
