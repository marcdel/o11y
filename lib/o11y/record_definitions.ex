defmodule O11y.RecordDefinitions do
  @moduledoc """
  This is a convenience module for defining the records from the OpenTelemetry Erlang library.

  Pull it in and use it like:

  ```elixir
  defmodule SomeTest do
    use ExUnit.Case, async: true
    use O11y.RecordDefinitions

    test "building spans for some reason" do
      span_record = span(name: "do it!", trace_id: 123, span_id: 456)
      dbg(span_record)
    end
  end
  ```
  """
  defmacro __using__(_) do
    quote do
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
    end
  end
end
