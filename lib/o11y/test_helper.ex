defmodule O11y.TestHelper do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      require OpenTelemetry.Tracer, as: Tracer
      require Record

      # https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/include/opentelemetry.hrl
      @fields Record.extract(:span_ctx, from_lib: "opentelemetry_api/include/opentelemetry.hrl")
      Record.defrecordp(:span_ctx, @fields)

      # https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/include/otel_span.hrl
      @fields Record.extract(:span, from_lib: "opentelemetry/include/otel_span.hrl")
      Record.defrecordp(:span, @fields)

      @fields Record.extract(:link, from_lib: "opentelemetry/include/otel_span.hrl")
      Record.defrecordp(:link, @fields)

      @fields Record.extract(:event, from_lib: "opentelemetry/include/otel_span.hrl")
      Record.defrecordp(:event, @fields)

      def otel_pid_reporter(_) do
        Application.load(:opentelemetry)

        Application.put_env(:opentelemetry, :processors, [
          {
            :otel_batch_processor,
            %{scheduled_delay_ms: 1, exporter: {:otel_exporter_pid, self()}}
          }
        ])

        {:ok, _} = Application.ensure_all_started(:opentelemetry)

        on_exit(fn ->
          Application.stop(:opentelemetry)
          Application.unload(:opentelemetry)
        end)
      end

      def assert_span(name, opts \\ []) do
        assert_receive {:span, span(name: ^name, attributes: attrs)}

        if Keyword.has_key?(opts, :attributes) do
          attributes = opts[:attributes]
          assert attributes(attrs) == attributes
        end
      end

      def links({:links, _, _, _, links}), do: links
      def events({:events, _, _, _, events}), do: events
      def attributes({:attributes, _, _, _, attributes}), do: attributes
    end
  end
end
