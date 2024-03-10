defmodule O11y do
  @moduledoc """
  A module to help with OpenTelemetry tracing.
  """

  require OpenTelemetry.Tracer, as: Tracer

  @doc """
  Sets the given attribute on the current span. If the value is not a valid OTLP type,
  it will be converted to a string with `inspect`.

  This method does not support structs to maps, regardless of whether the struct implements the O11y.SpanAttributes protocol.
  You need to use `set_attributes/1` for that.

  Example:

  ```elixir
  iex> O11y.set_attribute("key", "value")
  :ok
  ```

  Produces span attributes like:
  ```elixir
  {:attributes, 128, :infinity, 0, %{key: "value"}}
  ```
  """
  def set_attribute(key, value) do
    value = O11y.SpanAttributes.get(value)
    Tracer.set_attribute(key, value)
    :ok
  end

  @doc """
  Adds the given attributes as a list, map, or struct to the current span.
  If the value is a maps or struct, it will be converted to a list of key-value pairs.
  If the struct derives the O11y.SpanAttributes protocol, it will honor the except and only options.

  Example:

  ```elixir
  iex> O11y.set_attributes(%{id: 123, name: "Alice"})
  %{id: 123, name: "Alice"}
  ```

  Produces span attributes like:
  ```elixir
  {:attributes, 128, :infinity, 0, %{id: 123, name: "Alice"}}
  ```
  """
  def set_attributes(values) do
    values
    |> O11y.SpanAttributes.get()
    |> Tracer.set_attributes()

    values
  end

  @doc """
  Same as set_attributes/1, but with a prefix for all keys.

  Example:

  ```elixir
  iex> O11y.set_attributes("user", %{name: "Steve", age: 47})
  %{name: "Steve", age: 47}
  ```

  Produces span attributes like:
  ```elixir
  {:attributes, 128, :infinity, 0, %{"user.age" => 47, "user.name" => "Steve"}}
  ```
  """
  def set_attributes(prefix, values) do
    values
    |> O11y.SpanAttributes.get()
    |> Enum.map(fn {key, value} -> {"#{prefix}.#{key}", value} end)
    |> Tracer.set_attributes()

    values
  end

  @doc """
  Records an exception and sets the status of the current span to error.

  Example:

  ```elixir
  iex> O11y.record_exception(%RuntimeError{message: "something went wrong"})
  %RuntimeError{message: "something went wrong"}
  ```

  Produces a span like:
  ```elixir
  {:span, 28221055821181380594370570739471883760, 5895012157721301439, [],
    :undefined, "checkout", :internal, -576460751313205167, -576460751311430083,
    {:attributes, 128, :infinity, 0, %{}},
    {:events, 128, 128, :infinity, 0,
    [
      {:event, -576460751311694042, "exception",
       {:attributes, 128, :infinity, 0,
        %{
          "exception.message": "something went wrong",
          "exception.stacktrace": "...",
          "exception.type": "Elixir.RuntimeError"
        }}}
    ]}, {:links, 128, 128, :infinity, 0, []}, {:status, :error, ""}, 1, false,
    :undefined}
  ```
  """
  def record_exception(exception) do
    Tracer.record_exception(exception)
    Tracer.set_status(OpenTelemetry.status(:error))

    exception
  end

  @doc """
  This function is typically used to "inject" trace context information into http headers such that
  the trace can be continued in another service. However, it can also be used to link span in cases where
  OpenTelemetry.Ctx.attach/1 will not work (such as when the parent span has already ended or been removed from the dictionary).

  Example:
  ```elixir
  iex> res = Tracer.with_span "some_span", do: O11y.get_distributed_trace_ctx()
  iex> [{"traceparent", _}] = res
  ```
  """
  def get_distributed_trace_ctx, do: :otel_propagator_text_map.inject([])

  @doc """
  This is the counterpart to `get_distributed_trace_ctx/0`. It is used to "extract" trace context information from http headers.
  This context information is stored in a string so it can be passed around by other means as well.

  Example:
  ```elixir
  iex> O11y.attach_distributed_trace_ctx([traceparent: "00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01"])
  iex> O11y.attach_distributed_trace_ctx("00-0af7651916cd43dd8448eb211c80319c-b7ad6b7169203331-01")
  iex> O11y.attach_distributed_trace_ctx(nil)
  ```
  """
  def attach_distributed_trace_ctx(nil), do: nil

  def attach_distributed_trace_ctx(dist_trace_ctx) when is_list(dist_trace_ctx) do
    :otel_propagator_text_map.extract(dist_trace_ctx)
  end

  def attach_distributed_trace_ctx(dist_trace_ctx) when is_binary(dist_trace_ctx) do
    :otel_propagator_text_map.extract([{"traceparent", dist_trace_ctx}])
  end
end
