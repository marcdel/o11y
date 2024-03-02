defmodule O11y.MixProject do
  use Mix.Project

  def project do
    [
      app: :o11y,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:opentelemetry_exporter, "~> 1.4", only: :test},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry, "~> 1.3", only: :test, runtime: false}
    ]
  end
end
