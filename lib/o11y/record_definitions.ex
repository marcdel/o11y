defmodule O11y.RecordDefinitions do
  @moduledoc """
  This module is a convenience module for defining the records from the OpenTelemetry Erlang library.
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

      def status({:status, status, ""}), do: status
      def status({:status, status, message}), do: {status, message}

      def links({:links, _, _, _, links}), do: links
      def events({:events, _, _, _, _, events}), do: events

      # https://github.com/open-telemetry/opentelemetry-erlang/blob/c1ccdffb11253f5da63146a6c014db41bb4b27cc/apps/opentelemetry_api/src/otel_attributes.erl#L37
      def attributes({:attributes, _, _, _, attributes}), do: attributes
      def attributes_record(attributes), do: {:attributes, 128, :infinity, 0, attributes}
    end
  end
end
