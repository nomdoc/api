defmodule API.Repo do
  @moduledoc false

  use Ecto.Repo,
    otp_app: :api,
    adapter: Ecto.Adapters.Postgres

  import Ecto.Query

  require Logger

  @spec transact((... -> {:ok, term()} | {:error, term()}), Keyword.t()) ::
          {:ok, term()} | {:error, term()}
  def transact(fun, opts \\ []) do
    transaction(
      fn repo ->
        fun_arity = Function.info(fun, :arity)

        fun_arity
        |> case do
          {:arity, 0} -> fun.()
          {:arity, 1} -> fun.(repo)
        end
        |> case do
          {:ok, result} -> result
          {:error, reason} -> repo.rollback(reason)
        end
      end,
      opts
    )
  end

  @type pagination_opts :: [
          after: binary(),
          before: binary(),
          limit: pos_integer(),
          maximum_limit: pos_integer(),
          sort_direction: :asc | :desc
        ]

  @doc """
  Fetches all the results matching the query within the cursors.

  ## Options
  * `:after` - Fetch the records after this cursor.
  * `:before` - Fetch the records before this cursor.
  * `:limit` - Limits the number of records returned per page. Note that this
  number will be capped by `:maximum_limit`. Defaults to `50`.
  * `:maximum_limit` - Sets a maximum cap for `:limit`. This option can be useful when `:limit`
  is set dynamically (e.g from a URL param set by a user) but you still want to
  enfore a maximum. Defaults to `500`.
  * `:sort_direction` - The direction used for sorting. Defaults to `:asc`.
  """
  @spec paginate(Ecto.Queryable.t(), [atom()], pagination_opts(), Keyword.t()) ::
          {:ok, API.Pagination.t()} | {:error, :invalid_pagination_cursor}
  def paginate(queryable, cursor_fields, opts \\ [], repo_opts \\ []) do
    defaults = [limit: 25, cursor_fields: cursor_fields, include_total_count: false]
    opts = Keyword.merge(defaults, opts)

    try do
      page = Paginator.paginate(queryable, opts, __MODULE__, repo_opts)

      {:ok,
       %API.Pagination{
         edges:
           Enum.map(page.entries, fn entry ->
             %{
               cursor: Paginator.cursor_for_record(entry, cursor_fields),
               node: entry
             }
           end),
         page_info: %{
           has_previous_page: not is_nil(page.metadata.before),
           has_next_page: not is_nil(page.metadata.after),
           start_cursor: page.metadata.before,
           end_cursor: page.metadata.after
         }
       }}
    rescue
      e in ArgumentError ->
        Logger.error(Exception.format(:error, e, __STACKTRACE__))

        {:error, :invalid_pagination_cursor}
    end
  end

  @spec total_count(Ecto.Queryable.t(), atom(), Keyword.t()) :: {:ok, number()}
  def total_count(queryable, primary_key_field \\ :id, opts \\ []) do
    result =
      queryable
      |> exclude(:preload)
      |> exclude(:select)
      |> exclude(:order_by)
      |> select([e], struct(e, [primary_key_field]))
      |> subquery()
      |> select(count("*"))
      |> one(opts)

    {:ok, result}
  end
end
