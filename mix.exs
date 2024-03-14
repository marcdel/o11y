defmodule O11y.MixProject do
  use Mix.Project

  @version "0.1.2"
  @github_page "https://github.com/marcdel/o11y"

  def project do
    [
      app: :o11y,
      version: @version,
      name: "O11y",
      description: "Generalizable utilities for working with OpenTelemetry in Elixir.",
      homepage_url: @github_page,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      consolidate_protocols: Mix.env() == :prod,
      docs: docs(),
      deps: deps(),
      package: package()
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

  defp docs do
    [
      authors: ["Marc Delagrammatikas"],
      canonical: "http://hexdocs.pm/o11y",
      main: "O11y",
      logo: "o11y.png",
      source_ref: "v#{@version}"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false},
      {:ex_doc, "~> 0.31", only: :dev, runtime: false},
      {:opentelemetry_exporter, "~> 1.4", only: :test},
      {:opentelemetry_api, "~> 1.2"},
      {:opentelemetry, "~> 1.3", only: :test, runtime: false}
    ]
  end

  defp package do
    [
      files: ~w(mix.exs README.md lib),
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_page,
        "marcdel.com" => "https://www.marcdel.com",
        "OpenTelemetry Erlang" => "https://github.com/open-telemetry/opentelemetry-erlang"
      },
      maintainers: ["Marc Delagrammatikas"]
    ]
  end
end
