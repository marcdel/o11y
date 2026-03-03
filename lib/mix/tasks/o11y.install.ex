defmodule Mix.Tasks.O11y.Install.Docs do
  @moduledoc false
  def shortdoc, do: "Installs o11y and OpenTelemetry dependencies into your project"
  def example, do: "mix igniter.install o11y"
end

if Code.ensure_loaded?(Igniter) do
  defmodule Mix.Tasks.O11y.Install do
    @shortdoc Mix.Tasks.O11y.Install.Docs.shortdoc()

    @moduledoc """
    #{@shortdoc}

    ## Example

    ```bash
    #{Mix.Tasks.O11y.Install.Docs.example()}
    ```

    ## Options

    * `--with-decorator` - Also install `open_telemetry_decorator`
    * `--exporter honeycomb` - Configure exporters to send to Honeycomb (reads API key from `HONEYCOMB_API_KEY` env var)
    """

    use Igniter.Mix.Task

    alias Igniter.Code.Common
    alias Igniter.Code.Function
    alias Igniter.Project.Application
    alias Igniter.Project.Config
    alias Igniter.Project.Deps
    alias Igniter.Project.Module
    alias Mix.Tasks.O11y.Install.Docs

    @impl Igniter.Mix.Task
    def info(_argv, _composing_task) do
      %Igniter.Mix.Task.Info{
        group: :o11y,
        example: Docs.example(),
        schema: [with_decorator: :boolean, exporter: :string],
        defaults: [with_decorator: false]
      }
    end

    @impl Igniter.Mix.Task
    def igniter(igniter) do
      opts = igniter.args.options
      app_name = Application.app_name(igniter)

      igniter
      |> add_core_deps()
      |> add_conditional_deps()
      |> maybe_add_decorator(opts)
      |> configure_dev(opts)
      |> configure_runtime(opts)
      |> add_release_notice(app_name)
      |> setup_application(app_name)
    end

    defp add_core_deps(igniter) do
      igniter
      |> Deps.add_dep({:opentelemetry, "~> 1.5"})
      |> Deps.add_dep({:opentelemetry_api, "~> 1.4"})
      |> Deps.add_dep({:opentelemetry_exporter, "~> 1.8"})
    end

    defp add_conditional_deps(igniter) do
      igniter
      |> maybe_add_phoenix_dep()
      |> maybe_add_cowboy_dep()
      |> maybe_add_ecto_dep()
    end

    defp maybe_add_phoenix_dep(igniter) do
      if Deps.has_dep?(igniter, :phoenix) do
        Deps.add_dep(igniter, {:opentelemetry_phoenix, "~> 2.0"})
      else
        igniter
      end
    end

    defp maybe_add_cowboy_dep(igniter) do
      if Deps.has_dep?(igniter, :plug_cowboy) or Deps.has_dep?(igniter, :bandit) do
        Deps.add_dep(igniter, {:opentelemetry_cowboy, "~> 1.0"})
      else
        igniter
      end
    end

    defp maybe_add_ecto_dep(igniter) do
      if Deps.has_dep?(igniter, :ecto) do
        Deps.add_dep(igniter, {:opentelemetry_ecto, "~> 1.0"})
      else
        igniter
      end
    end

    defp maybe_add_decorator(igniter, opts) do
      if Keyword.get(opts, :with_decorator, false) do
        Deps.add_dep(igniter, {:open_telemetry_decorator, "~> 1.6"})
      else
        igniter
      end
    end

    defp configure_dev(igniter, opts) do
      if Keyword.get(opts, :exporter) == "honeycomb" do
        igniter
        |> Config.configure_new(
          "dev.exs",
          :opentelemetry_exporter,
          [:otlp_endpoint],
          {:code, quote(do: "https://api.honeycomb.io:443")}
        )
        |> Config.configure_new(
          "dev.exs",
          :opentelemetry_exporter,
          [:otlp_headers],
          {:code, quote(do: [{"x-honeycomb-team", System.fetch_env!("HONEYCOMB_API_KEY")}])}
        )
      else
        Config.configure_new(
          igniter,
          "dev.exs",
          :opentelemetry,
          [:traces_exporter],
          {:code, quote(do: {:otel_exporter_stdout, []})}
        )
      end
    end

    defp configure_runtime(igniter, opts) do
      if Keyword.get(opts, :exporter) == "honeycomb" do
        igniter
        |> Config.configure_new(
          "runtime.exs",
          :opentelemetry_exporter,
          [:otlp_endpoint],
          {:code, quote(do: "https://api.honeycomb.io:443")}
        )
        |> Config.configure_new(
          "runtime.exs",
          :opentelemetry_exporter,
          [:otlp_headers],
          {:code, quote(do: [{"x-honeycomb-team", System.fetch_env!("HONEYCOMB_API_KEY")}])}
        )
      else
        Config.configure_new(
          igniter,
          "runtime.exs",
          :opentelemetry_exporter,
          [:otlp_endpoint],
          {:code,
           quote(do: System.get_env("OTEL_EXPORTER_OTLP_ENDPOINT", "http://localhost:4318"))}
        )
      end
    end

    defp add_release_notice(igniter, app_name) do
      Igniter.add_notice(igniter, """
      Remember to mark :opentelemetry as a temporary application in your release config:

          releases: [
            #{app_name}: [
              applications: [opentelemetry: :temporary]
            ]
          ]
      """)
    end

    defp setup_application(igniter, app_name) do
      app_module = Application.app_module(igniter)

      if app_module do
        setup_calls = build_setup_calls(igniter, app_name)
        inject_setup_calls(igniter, app_module, setup_calls)
      else
        Igniter.add_warning(igniter, """
        No Application module found. Add the following setup calls to the top of your
        Application.start/2 function, before the children list:

        #{manual_setup_instructions(igniter, app_name)}
        """)
      end
    end

    defp build_setup_calls(igniter, app_name) do
      calls = []

      calls =
        if Deps.has_dep?(igniter, :plug_cowboy) or Deps.has_dep?(igniter, :bandit) do
          calls ++ [":opentelemetry_cowboy.setup()"]
        else
          calls
        end

      calls =
        if Deps.has_dep?(igniter, :phoenix) do
          adapter = if Deps.has_dep?(igniter, :bandit), do: :bandit, else: :cowboy2
          calls ++ ["OpentelemetryPhoenix.setup(adapter: :#{adapter})"]
        else
          calls
        end

      calls =
        if Deps.has_dep?(igniter, :ecto) do
          calls ++ ["OpentelemetryEcto.setup([:#{app_name}, :repo])"]
        else
          calls
        end

      Enum.reverse(calls)
    end

    defp inject_setup_calls(igniter, _app_module, []), do: igniter

    defp inject_setup_calls(igniter, app_module, setup_calls) do
      Module.find_and_update_module!(igniter, app_module, fn zipper ->
        case Function.move_to_def(zipper, :start, 2) do
          {:ok, zipper} ->
            {:ok, add_missing_setup_calls(zipper, setup_calls)}

          _ ->
            {:warning,
             """
             Could not find a `start/2` function in your Application module.
             Please add the following setup calls manually:

             #{Enum.join(setup_calls, "\n")}
             """}
        end
      end)
    end

    defp add_missing_setup_calls(zipper, setup_calls) do
      Enum.reduce(setup_calls, zipper, fn call, acc ->
        if already_has_call?(acc, call) do
          acc
        else
          Common.add_code(acc, call, placement: :before)
        end
      end)
    end

    defp already_has_call?(zipper, call) do
      case Common.move_to(zipper, fn z ->
             source = Sourceror.Zipper.node(z) |> Macro.to_string()
             String.contains?(source, String.trim(call))
           end) do
        {:ok, _} -> true
        :error -> false
      end
    end

    defp manual_setup_instructions(igniter, app_name) do
      lines = []

      lines =
        if Deps.has_dep?(igniter, :plug_cowboy) or Deps.has_dep?(igniter, :bandit) do
          lines ++ ["    :opentelemetry_cowboy.setup()"]
        else
          lines
        end

      lines =
        if Deps.has_dep?(igniter, :phoenix) do
          adapter = if Deps.has_dep?(igniter, :bandit), do: :bandit, else: :cowboy2
          lines ++ ["    OpentelemetryPhoenix.setup(adapter: :#{adapter})"]
        else
          lines
        end

      lines =
        if Deps.has_dep?(igniter, :ecto) do
          lines ++ ["    OpentelemetryEcto.setup([:#{app_name}, :repo])"]
        else
          lines
        end

      Enum.join(lines, "\n")
    end
  end
else
  defmodule Mix.Tasks.O11y.Install do
    @shortdoc Mix.Tasks.O11y.Install.Docs.shortdoc()

    @moduledoc """
    #{@shortdoc}

    This task requires the `igniter` package to be installed.
    """

    use Mix.Task

    def run(_argv) do
      Mix.shell().error("""
      The task 'o11y.install' requires igniter. Please install igniter and try again.

      For more information, see: https://hexdocs.pm/igniter/readme.html#installation
      """)

      exit({:shutdown, 1})
    end
  end
end
