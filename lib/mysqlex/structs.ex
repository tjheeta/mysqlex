defmodule Mysqlex.Result do
  @moduledoc """
  Result struct returned from any successful query. Its fields are:

    * `command` - An atom of the query command, for example: `:select` or
                  `:insert`;
    * `columns` - The column names;
    * `rows` - The result set. A list of tuples, each tuple corresponding to a
               row, each element in the tuple corresponds to a column;
    * `num_rows` - The number of fetched or affected rows;
  """

  @type t :: %__MODULE__{
    command:  atom,
    columns:  [String.t] | nil,
    rows:     [tuple] | nil,
    last_insert_id: integer,
    num_rows: integer}

  defstruct [:command, :columns, :rows, :last_insert_id, :num_rows]
end

defmodule Mysqlex.Error do
  defexception [:message, :mysqlex]

  def message(e) do
    IO.inspect(e)
    kw = e.mysqlex
    msg = "(#{kw[:code]}): #{kw[:message]}"
    msg || e.message
  end
end
