defmodule Mysqlex.Connection do
  @moduledoc """
  Main API for Mysqlex. This module handles the connection to .
  """

  @timeout 5000

  defmacrop raiser(result) do
    quote do
      case unquote(result) do
        {:error, error} ->
          raise error
        result ->
          result
      end
    end
  end

  defp get_command(statement) when is_binary(statement) do
    statement |> String.split(" ", parts: 2) |> hd |> String.downcase |> String.to_atom
  end
  defp get_command(nil), do: nil

  defp keyword_list_parse(k) do
    Enum.map(k,
      fn(x) ->
        if is_binary(elem(x,1)) do
          { elem(x,0), String.to_char_list(elem(x,1))}
        else
          x
        end
      end
    )
  end

  ### PUBLIC API ###

  @doc """
  Start the connection process and connect to mariadb.

  ## Options

    * `:hostname` - Server hostname (default: MDBHOST env variable, then localhost);
    * `:port` - Server port (default: 3306);
    * `:sock_type` - Socket type (default: :tcp);
    * `:database` - Database (required);
    * `:username` - Username (default: MDBUSER env variable, then USER env var);
    * `:password` - User password (default MDBPASSWORD);
    * `:encoder` - Custom encoder function;
    * `:decoder` - Custom decoder function;
    * `:formatter` - Function deciding the format for a type;
    * `:parameters` - Keyword list of connection parameters;
    * `:timeout` - Connect timeout in milliseconds (default: 5000);
    * `:charset` - Database encoding (default: "utf8");
    * `:socket_options` - Options to be given to the underlying socket;

  ## Function signatures

      @spec encoder(info :: TypeInfo.t, default :: fun, param :: term) ::
            binary
      @spec decoder(info :: TypeInfo.t, default :: fun, bin :: binary) ::
            term
      @spec formatter(info :: TypeInfo.t) ::
            :binary | :text | nil
  """

  @spec start_link(Keyword.t) :: {:ok, pid} | {:error, Mysqlex.Error.t | term}

  def start_link(opts) do
    sock_type = (opts[:sock_type] || :tcp) |> Atom.to_string |> String.capitalize()
    sock_mod = ("Elixir.Mysqlex.Connection." <> sock_type) |> String.to_atom
    opts = opts
      |> Keyword.put_new(:username, System.get_env("MDBUSER") || System.get_env("USER"))
      |> Keyword.put_new(:password, System.get_env("MDBPASSWORD"))
      |> Keyword.put_new(:hostname, System.get_env("MDBHOST") || "localhost")
      # Some variable names need to be renamed for mysql driver
      # hostname -> host, username -> user, timeout -> connect_timeout
      |> Keyword.put_new(:host, opts[:hostname])
      |> Keyword.put_new(:user, opts[:username])
      |> Keyword.put_new(:connect_timeout, opts[:timeout] || @timeout)

    opts = keyword_list_parse(opts)
    # TODO - fix up the arguments to start_link to match :mysql
    # TODO - setup the charset? query(pid, "SET CHARACTER SET " <> (opts[:charset] || "utf8"))
    :mysql.start_link(opts)
  end

  @doc """
  Stop the process and disconnect.

  """
  @spec stop(pid, Keyword.t) :: :ok
  def stop(pid, opts \\ []) do
    Process.exit(pid, :normal)
  end

  @doc """
  Runs an (extended) query and returns the result as `{:ok, %Mysqlex.Result{}}`
  or `{:error, %Mysqlex.Error{}}` if there was an error. Parameters can be
  set in the query as `?` embedded in the query string. Parameters are given as
  a list of elixir values. See the README for information on how Mysqlex
  encodes and decodes elixir values by default. See `Mysqlex.Result` for the
  result data.

  A *type hinted* query is run if both the options `:param_types` and
  `:result_types` are given. One client-server round trip can be saved by
  providing the types to Mysqlex because the server doesn't have to be queried
  for the types of the parameters and the result.

  ## Options

    * `:timeout` - Call timeout (default: `#{@timeout}`)
    * `:param_types` - A list of type names for the parameters
    * `:result_types` - A list of type names for the result rows

  ## Examples

      Mysqlex.Connection.query(pid, "CREATE TABLE posts (id serial, title text)")

      Mysqlex.Connection.query(pid, "INSERT INTO posts (title) VALUES ('my title')")

      Mysqlex.Connection.query(pid, "SELECT title FROM posts", [])

      Mysqlex.Connection.query(pid, "SELECT id FROM posts WHERE title like ?", ["%my%"])

      Mysqlex.Connection.query(pid, "SELECT ? || ?", ["4", "2"],
                                param_types: ["text", "text"], result_types: ["text"])

  """
  @spec query(pid, iodata, list, Keyword.t) :: {:ok, Mysqlex.Result.t} | {:error, Mysqlex.Error.t}
  def query(pid, statement, params \\ [], opts \\ []) do
    # TODO - add parsing of options, eg. timeout
    cmd = get_command(statement)
    case :mysql.query(pid, statement, params) do
      {:ok, columns, rows} ->
        %Mysqlex.Result{columns: columns, command: cmd, rows: rows, num_rows: length(rows) }
      :ok -> 
        last_insert_id = :mysql.insert_id(pid)
        affected_rows = :mysql.affected_rows(pid)
        %Mysqlex.Result{columns: [], command: cmd, rows: [], num_rows: affected_rows, last_insert_id: last_insert_id  }
      # TODO - deal with error
      # ** (CaseClauseError) no case clause matching: {:error, {1146, "42S02", "Table 'test.domains1' doesn't exist"}}
      #    (mysqlex) lib/mysqlex/connection.ex:131: Mysqlex.Connection.query/4
    end
  end

  @doc """
  Runs an (extended) query and returns the result or raises `Mysqlex.Error` if
  there was an error. See `query/3`.
  """

  def query!(pid, statement, params \\ [], opts \\ []) do
    query(pid, statement, params, opts) |> raiser
  end

end

