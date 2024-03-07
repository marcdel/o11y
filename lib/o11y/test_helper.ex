defmodule O11y.TestHelper do
  @moduledoc """
  Provides a few helper functions to make testing with OpenTelemetry easier.

  Example:

  ```elixir
  defmodule MyTest do
    use ExUnit.Case, async: true
    use O11y.TestHelper

    test "appends the given attribute to the span" do
      Tracer.with_span "checkout" do
        O11y.set_attribute(:id, 123)
      end

      assert_span("checkout", attributes: %{id: 123})
    end
  end
  ```
  """

  @doc """
  Sets up OpenTelemetry to use the pid exporter and ensures it is stopped after the test.
  When spans are exported, a message is sent to the test pid allowing you to `assert_receive` on a tuple with the span.

  This is already setup for you when you `use O11y.TestHelper`.
  ```elixir
  setup [:otel_pid_reporter]
  ```
  """
  @callback otel_pid_reporter(any()) :: any()

  # This is actually an erlang record, see the `defrecordp` macro below
  @type span_record() :: tuple()

  @doc """
  Asserts that a span with the given name was exported and optionally checks the status and attributes.

  Example:
  ```elixir
  assert_span("checkout", attributes: %{"id" => 123})
  assert_span("checkout", status: :error)
  ```

  It returns the matched span record so you can make additional assertions. The easiest way is to pattern match by creating a span record and bind the properties you want to assert on.
  You can use the included span, link, and event records to help with this, as well as the status, links, events, and attributes functions.

  Examples:
  ```elixir
  span(status: status, events: events) = assert_span("checkout")

  assert status(status) == :error
  assert [event(name: "exception", attributes: attributes)] = events(events)
  assert %{"exception.message": "something went wrong"} = attributes(attributes)
  ```
  """
  @callback assert_span(String.t(), Keyword.t()) :: span_record()

  @doc """
  Extracts the status atom from the status field on a span record.
  """
  @callback status(tuple()) :: atom()

  @doc """
  Extracts the links from a span record. Individual link records can be further inspected with the `link` function.
  """
  @callback links(tuple()) :: list()

  @doc """
  Extracts the events from a span record. Individual event records can be further inspected with the `event` function.
  """
  @callback events(tuple()) :: list()

  @doc """
  Extracts the attributes from a span record as a map.
  """
  @callback attributes(tuple()) :: map()

  defmacro __using__(_) do
    quote do
      @behaviour O11y.TestHelper

      require OpenTelemetry.Tracer, as: Tracer
      require Record

      setup [:otel_pid_reporter]

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
        assert_receive {:span,
                        span(
                          name: ^name,
                          status: status,
                          attributes: attrs,
                          events: _events
                        ) = span}

        if Keyword.has_key?(opts, :status) do
          expected_status = opts[:status]
          assert status(status) == expected_status
        end

        if Keyword.has_key?(opts, :attributes) do
          span_attributes = attributes(attrs)
          expected_attributes = opts[:attributes]
          assert span_attributes == expected_attributes
        end

        span
      end

      def status({:status, status, _}), do: status
      def links({:links, _, _, _, links}), do: links
      def events({:events, _, _, _, _, events}), do: events
      def attributes({:attributes, _, _, _, attributes}), do: attributes
    end
  end
end
