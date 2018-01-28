defmodule Mysqlex.Mixfile do
  use Mix.Project

  def project() do
    [app: :mysqlex,
     version: "0.0.2",
     elixir: "~> 1.0",
     description: description(),
     package: package(),
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp description() do
     """
     An Ecto-compatible wrapper around the mysql-otp library. https://github.com/mysql-otp/mysql-otp
     """
  end

  defp package() do
    [contributors: ["TJ"],
     maintainers: ["TJ"],
     licenses: ["Apache 2.0"],
     links: %{"GitHub" => "https://github.com/tjheeta/mysqlex"}
    ]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application() do
    [applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps() do
    [
      {:mysql, "~> 1.3.1"},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
