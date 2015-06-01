Mysqlex
=======

This is a wrapper around a newer mysql library for erlang:

https://github.com/mysql-otp

There are benchmarks for the mysql drivers:

* http://tjheeta.github.io/2015/05/31/elixir-and-erlang-mysql-drivers.html
* http://tjheeta.github.io/2015/05/30/benchmarking-elixir-postgres-mysql-ecto.html



## Usage

To use add the following to your mix.exs:

~~~
def deps do
  [{:mysqlex, github: "tjheeta/mysqlex" } ]
end
~~~

Profit:

~~~
iex(8)> {:ok, pid} = Mysqlex.Connection.start_link(username: "test", database: "test", password: "test", hostname: "10.0.3.82")
{:ok, #PID<0.1420.0>}
iex(9)> Mysqlex.Connection.query(pid, "CREATE TABLE posts (id serial, title text)")
{:ok,
 %Mysqlex.Result{columns: [], command: :create, last_insert_id: 0, num_rows: 0,
  rows: []}}
iex(10)> Mysqlex.Connection.query(pid, "CREATE TABLE posts (id serial, title text)")
{:error,
 %Mysqlex.Error{message: "1050 - Table 'posts' already exists", mysqlex: nil}}
iex(11)> Mysqlex.Connection.query(pid, "INSERT INTO posts (title) VALUES ('my title')")
{:ok,
 %Mysqlex.Result{columns: [], command: :insert, last_insert_id: 1, num_rows: 1,
  rows: []}}
iex(12)> Mysqlex.Connection.query(pid, "SELECT title FROM posts", [])
{:ok,
 %Mysqlex.Result{columns: ["title"], command: :select, last_insert_id: nil,
  num_rows: 1, rows: [{"my title"}]}}
iex(13)> Mysqlex.Connection.query(pid, "SELECT id FROM posts WHERE title like ?", ["%my%"])
{:ok,
 %Mysqlex.Result{columns: ["id"], command: :select, last_insert_id: nil,
  num_rows: 1, rows: [{1}]}}

~~~

To use with ecto, you'll have to patch it for now:

https://gist.github.com/tjheeta/800deab2b9e7b2b9651b
