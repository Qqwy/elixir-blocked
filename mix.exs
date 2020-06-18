defmodule Blocked.MixProject do
  @source_url "https://github.com/Qqwy/elixir-blocked"
  use Mix.Project

  def project do
    [
      app: :blocked,
      version: "0.9.1",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: @source_url,
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:git_cli, "~> 0.3"},
      {:tesla, "~> 1.3.0"},
      {:mint, "~> 1.0"},
      {:castore, "~> 0.1"},
      {:jason, ">= 1.0.0"},
      {:specify, "~> 0.7.0"},
      {:ex_doc, "~> 0.19", only: [:docs], runtime: false},
      # Inch CI documentation quality test.
      {:inch_ex, ">= 0.0.0", only: [:docs], runtime: false},
    ]
  end

  defp description do
    """
    Keep track of when hotfixes can be removed by showing compile-time warnings when issues are closed.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :blocked,
      files: ["lib", "mix.exs", "README*", "LICENSE"],
      maintainers: ["Wiebe-Marten Wijnja/Qqwy"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp docs do
    [
      main: "readme",
      logo: "media/blocked_logo.svg",
      extras: ["README.md"]
    ]
  end
end
