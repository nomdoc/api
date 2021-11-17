defmodule API.Workers.SendOrganizationInviteEmail do
  @moduledoc false

  use Oban.Worker,
    queue: :mailer,
    max_attempts: 3,
    unique: [fields: [:args, :worker], keys: [:organization_invite_id]]

  require Logger

  @spec schedule(binary(), API.OrganizationInvite.t()) :: :ok
  def schedule(email_address, %API.OrganizationInvite{} = org_invite) do
    if org_invite.new? do
      org_invite = API.Repo.preload(org_invite, organization: [:handle_name])

      params = %{
        organization_invite_id: org_invite.id,
        email_address: email_address,
        role: org_invite.role,
        organization_display_name: org_invite.organization.display_name,
        organization_handle_name: org_invite.organization.handle_name.value
      }

      params
      |> __MODULE__.new()
      |> Oban.insert!()
    end

    :ok
  end

  @impl Oban.Worker
  def perform(%Oban.Job{args: params}) do
    Logger.debug("""
    Sending email...
      To: #{params["email_address"]}
      Message: You've been invited to join @#{params["organization_handle_name"]} as #{params["role"]}
    """)

    :ok
  end
end
