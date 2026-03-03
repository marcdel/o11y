defmodule Mix.Tasks.O11y.InstallTest do
  use ExUnit.Case, async: true

  import Igniter.Test

  @mix_exs_with_phoenix """
  defmodule Test.MixProject do
    use Mix.Project

    def project do
      [
        app: :test,
        version: "0.1.0",
        elixir: "~> 1.17",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
    end

    def application do
      [
        mod: {Test.Application, []},
        extra_applications: [:logger]
      ]
    end

    defp deps do
      [
        {:phoenix, "~> 1.7"},
        {:plug_cowboy, "~> 2.5"},
        {:ecto, "~> 3.10"}
      ]
    end
  end
  """

  @application_module """
  defmodule Test.Application do
    use Application

    @impl true
    def start(_type, _args) do
      children = []
      opts = [strategy: :one_for_one, name: Test.Supervisor]
      Supervisor.start_link(children, opts)
    end
  end
  """

  @mix_exs_with_bandit """
  defmodule Test.MixProject do
    use Mix.Project

    def project do
      [
        app: :test,
        version: "0.1.0",
        elixir: "~> 1.17",
        start_permanent: Mix.env() == :prod,
        deps: deps()
      ]
    end

    def application do
      [
        mod: {Test.Application, []},
        extra_applications: [:logger]
      ]
    end

    defp deps do
      [
        {:phoenix, "~> 1.7"},
        {:bandit, "~> 1.0"},
        {:ecto, "~> 3.10"}
      ]
    end
  end
  """

  describe "core dependencies" do
    test "always adds opentelemetry deps" do
      test_project()
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_exporter, "~> 1.8"},
      """)
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_api, "~> 1.4"},
      """)
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry, "~> 1.5"}
      """)
    end
  end

  describe "conditional dependencies" do
    test "adds Phoenix instrumentation dep when Phoenix is present" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_phoenix,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_phoenix, "~> 2.0"},
      """)
    end

    test "adds Cowboy instrumentation dep when plug_cowboy is present" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_phoenix,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_cowboy, "~> 1.0"},
      """)
    end

    test "adds Cowboy instrumentation dep when bandit is present" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_bandit,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_cowboy, "~> 1.0"},
      """)
    end

    test "adds Ecto instrumentation dep when Ecto is present" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_phoenix,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("mix.exs", """
      + |      {:opentelemetry_ecto, "~> 1.0"},
      """)
    end

    test "does not add conditional deps when frameworks are absent" do
      igniter =
        test_project()
        |> Igniter.compose_task("o11y.install")

      d = diff(igniter)
      refute d =~ "opentelemetry_phoenix"
      refute d =~ "opentelemetry_cowboy"
      refute d =~ "opentelemetry_ecto"
    end
  end

  describe "--with-decorator flag" do
    test "adds decorator dep when flag is set" do
      test_project()
      |> Igniter.compose_task("o11y.install", ["--with-decorator"])
      |> assert_has_patch("mix.exs", """
      + |      {:open_telemetry_decorator, "~> 1.6"},
      """)
    end

    test "does not add decorator dep by default" do
      igniter =
        test_project()
        |> Igniter.compose_task("o11y.install")

      d = diff(igniter)
      refute d =~ "open_telemetry_decorator"
    end
  end

  describe "--exporter honeycomb flag" do
    test "configures Honeycomb exporter in dev config" do
      test_project()
      |> Igniter.compose_task("o11y.install", ["--exporter", "honeycomb"])
      |> assert_creates("config/dev.exs", """
      import Config

      config :opentelemetry_exporter,
        otlp_endpoint: "https://api.honeycomb.io:443",
        otlp_headers: [{"x-honeycomb-team", System.fetch_env!("HONEYCOMB_API_KEY")}]
      """)
    end

    test "configures Honeycomb exporter in runtime config" do
      test_project()
      |> Igniter.compose_task("o11y.install", ["--exporter", "honeycomb"])
      |> assert_creates("config/runtime.exs", """
      import Config

      config :opentelemetry_exporter,
        otlp_endpoint: "https://api.honeycomb.io:443",
        otlp_headers: [{"x-honeycomb-team", System.fetch_env!("HONEYCOMB_API_KEY")}]
      """)
    end
  end

  describe "configuration" do
    test "adds stdout exporter to dev config" do
      test_project()
      |> Igniter.compose_task("o11y.install")
      |> assert_creates("config/dev.exs", """
      import Config
      config :opentelemetry, traces_exporter: {:otel_exporter_stdout, []}
      """)
    end

    test "adds OTLP endpoint to runtime config" do
      test_project()
      |> Igniter.compose_task("o11y.install")
      |> assert_creates("config/runtime.exs", """
      import Config

      config :opentelemetry_exporter,
        otlp_endpoint: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318")
      """)
    end
  end

  describe "release notice" do
    test "emits notice about marking opentelemetry as temporary" do
      test_project()
      |> Igniter.compose_task("o11y.install")
      |> assert_has_notice(&(&1 =~ "opentelemetry" and &1 =~ ":temporary"))
    end
  end

  describe "Application.ex setup" do
    test "injects setup calls for Phoenix project with cowboy" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_phoenix,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("lib/test/application.ex", """
      + |    :opentelemetry_cowboy.setup()
      + |    OpentelemetryPhoenix.setup(adapter: :cowboy2)
      + |    OpentelemetryEcto.setup([:test, :repo])
      """)
    end

    test "uses bandit adapter when bandit is present" do
      test_project(
        files: %{
          "mix.exs" => @mix_exs_with_bandit,
          "lib/test/application.ex" => @application_module
        }
      )
      |> Igniter.compose_task("o11y.install")
      |> assert_has_patch("lib/test/application.ex", """
      + |    OpentelemetryPhoenix.setup(adapter: :bandit)
      """)
    end

    test "emits warning when no Application module found" do
      test_project()
      |> Igniter.compose_task("o11y.install")
      |> assert_has_warning(&(&1 =~ "No Application module found"))
    end
  end
end
