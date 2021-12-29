defmodule API.JobListingTest do
  @moduledoc false

  use API.DataCase, async: true

  alias API.Job
  alias API.JobListing

  describe "post_job/2" do
    test "creates a job." do
      recruiter = insert(:recruiter)

      assert {:ok, %Job{} = job} =
               JobListing.post_job(recruiter.entity_id, %{
                 employment_type: :full_time,
                 title: "Permanent GP Needed"
               })

      assert job.status == :draft
    end
  end

  describe "edit_job_basic_info/2" do
    test "updates job title and description." do
      job = insert(:job)

      assert {:ok, %Job{} = updated_job} =
               JobListing.edit_job_basic_info(job.id, %{
                 title: "General Medicine Doctor",
                 description: "A good job."
               })

      assert updated_job.title == "General Medicine Doctor"
      assert updated_job.description == "A good job."
    end
  end

  describe "edit_job_address/3" do
    test "updates job address." do
      job = insert(:job)
      coordinate = %{latitude: 4.209, longitude: 101.232}

      address = %{
        line_one: "123 Main Street",
        city: "Kuala Lumpur",
        state: "W.P. Kuala Lumpur",
        postal_code: "56100",
        country_code: "MY"
      }

      assert {:ok, %Job{} = updated_job} =
               JobListing.edit_job_address(job.id, coordinate, address)

      assert updated_job.address_latitude == coordinate.latitude
      assert updated_job.address_longitude == coordinate.longitude
      assert updated_job.address_line_one == address.line_one
      assert is_nil(updated_job.address_line_two)
      assert updated_job.address_city == address.city
      assert updated_job.address_state == address.state
      assert updated_job.address_postal_code == address.postal_code
      assert updated_job.address_country_code == address.country_code
    end
  end
end
