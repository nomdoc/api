defmodule API do
  @moduledoc false

  use Boundary,
    deps: [],
    exports: [
      # Contexts
      Auth,
      HandleNames,
      Users,

      # Model
      HandleName,
      RefreshToken,
      User,

      # Modules
      Pwned,
      RateLimiter,
      Recaptcha,
      Regex,
      Repo,
      Utils
    ]

  def model() do
    quote do
      use Ecto.Schema

      import API.Utils
      import Ecto.Changeset
      import Ecto.Query
      import EctoEnum

      alias Ecto.Changeset

      @primary_key {:id, :binary_id, autogenerate: true}
      @foreign_key_type :binary_id
      @timestamps_opts [type: :utc_datetime_usec]
      @type t :: %__MODULE__{}
    end
  end

  def context() do
    quote do
      import Ecto
      import Ecto.Query

      alias API.Repo
      alias Ecto.Changeset

      require Logger
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
