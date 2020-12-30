defmodule ConfexConsul.MixProject do
  use Mix.Project

  def project do
    [
      app: :confex_consul,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      elixirc_options: [warnings_as_errors: true],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {ConfexConsul.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fuse, "~> 2.4"},
      {:confex, "~> 3.5"},
      {:consul_kv, "~> 0.1"},
      {:telemetry, "~> 0.4.2"},
      {:excoveralls, "~> 0.13.3", only: [:test]}
    ]
  end
end
