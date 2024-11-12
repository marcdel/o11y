defmodule O11y do
  @moduledoc """
  A module to help with OpenTelemetry tracing.
  """

  require Logger
  require OpenTelemetry.Tracer, as: Tracer

  alias O11y.AttributeProcessor

  @attribute_namespace Application.compile_env(:o11y, :attribute_namespace)

  @doc """
  ⚠️ Felt cute, might delete later ⚠️

  Calls `Tracer.with_span` with the given name and options.
  The main benefit is that you don't need to require `Tracer` in your module, but without
  the require we have to take an anonymous function instead of a do block 😞.

  ## Examples:

  ```elixir
  iex> O11y.with_span "checkout", fn ->
  iex>   O11y.set_attribute(:id, 123)
  iex> end
  ```

  ```elixir
  iex> O11y.with_span "login", %{attributes: %{id: 123}}, fn ->
  iex>   :ok
  iex> end
  ```
  """
  def with_span(name, start_opts \\ %{}, block) do
    {namespace, opts} = Map.pop(start_opts, :namespace)
    namespace = namespace || @attribute_namespace

    attributes =
      start_opts
      |> Map.get(:attributes, %{})
      |> AttributeProcessor.process(namespace: namespace)

    Tracer.with_span name, Map.put(opts, :attributes, attributes) do
      block.()
    end
  end

  @doc """
  Starts a new span and makes it the current active span of the current process.

  This is a little tricky because it actually returns the parent span, not the new span.
  However, this is because we want to be able to end the span and set the current span back to the parent which is not the default behavior.
  The API `end_span` function doesn't take a span to end anyway (though it seems like it should)
  so you sort of use this as I would expect the actual API to work and get similar behavior to `with_span`

  ## Examples:

  ```elixir
  iex> Tracer.with_span "checkout" do
  iex>  parent = O11y.start_span("calculate_tax")
  iex>  # gnarly_calculations()
  iex>  O11y.end_span(parent)
  iex> end
  ```
  """
  @spec start_span(String.t(), Keyword.t()) :: OpenTelemetry.span_ctx() | :undefined
  def start_span(name, opts \\ []) do
    parent_span = Tracer.current_span_ctx()
    span = Tracer.start_span(name, opts)
    Tracer.set_current_span(span)

    parent_span
  end

  @doc """
  Ends the current span and marks the given parent span as current.

  ## Examples:

  ```elixir
  iex> span = O11y.start_span("checkout")
  iex> O11y.end_span(span)
  ```
  """
  @spec end_span(OpenTelemetry.span_ctx() | :undefined) :: OpenTelemetry.span_ctx() | :undefined
  def end_span(parent_span) do
    Tracer.end_span()
    Tracer.set_current_span(parent_span)
  end

  @doc """
  Calls `Tracer.add_event` with the given name and processed attributes.
  """
  def add_event(name, attributes \\ %{}, opts \\ []) do
    attrs = AttributeProcessor.process(attributes, opts)
    Tracer.add_event(name, attrs)
  end

  @doc """
  Sets the given attribute on the current span. If the value is not a valid OTLP type,
  it will be converted to a string with `inspect`.

  This method does not support structs to maps, regardless of whether the struct implements the O11y.SpanAttributes protocol.
  You need to use `set_attributes/1` for that.

  ## Examples:

  ```elixir
  iex> O11y.set_attribute("key", "value")
  :ok

  # Produces span attributes like:
  {:attributes, 128, :infinity, 0, %{key: "value"}}
  ```

  ```elixir
  iex> O11y.set_attribute("key", "value", namespace: "cool_app")
  :ok

  # Produces span attributes like:
  {:attributes, 128, :infinity, 0, %{"cool_app.key" => "value"}}
  ```

  Namespace can also be set globally via configuration like:
  ```elixir
  config :open_telemetry_decorator, :attribute_namespace, "app"
  ```
  """
  def set_attribute(key, value, opts \\ []) do
    [{key, value}]
    |> AttributeProcessor.process(opts)
    |> Tracer.set_attributes()

    :ok
  rescue
    _ -> :error
  end

  @doc """
  Adds the given attributes as a list, map, or struct to the current span.
  If the value is a maps or struct, it will be converted to a list of key-value pairs.
  If the struct derives the O11y.SpanAttributes protocol, it will honor the except and only options.

  ## Examples:

  ```elixir
  iex> O11y.set_attributes(%{id: 123, name: "Alice"})
  %{id: 123, name: "Alice"}

  # Produces span attributes like:
  {:attributes, 128, :infinity, 0, %{id: 123, name: "Alice"}}
  ```

  ```elixir
  iex> O11y.set_attributes(%{name: "Steve", age: 47}, prefix: "user")
  %{name: "Steve", age: 47}

  # Produces span attributes like:
  {:attributes, 128, :infinity, 0, %{"user.age" => 47, "user.name" => "Steve"}}
  ```

  ```elixir
  iex> O11y.set_attributes(%{name: "Steve", age: 47}, namespace: "app")
  %{name: "Steve", age: 47}

  # Produces span attributes like:
  {:attributes, 128, :infinity, 0, %{"app.age" => 47, "app.name" => "Steve"}}
  ```

  A prefix can be given that will be prepended to all keys in the attributes map.
  This can be useful to avoid key collisions, or when calling it in a pipeline (attributes are returned unchanged).
  ```elixir
  iex> login = fn user -> Map.put(user, :logged_in_at, DateTime.utc_now()) end
  ...> checkout = fn _user -> %{items: [:boogers, :farts], total: 420.69} end
  ...> user = %{name: "Steve", age: 47}
  ...>
  ...> user
  ...> |> O11y.set_attributes(prefix: "user")
  ...> |> login.()
  ...> |> O11y.set_attributes(prefix: "authed_user")
  ...> |> checkout.()
  ...> |> O11y.set_attributes(prefix: "cart")
  ```

  Namespace can also be set globally via configuration like:
  ```elixir
  config :open_telemetry_decorator, :attribute_namespace, "app"
  ```
  """
  def set_attributes(values, opts \\ [])

  def set_attributes(values, opts) do
    values
    |> AttributeProcessor.process(opts)
    |> Tracer.set_attributes()

    values
  rescue
    _ -> values
  end

  @doc """
  Records an exception and sets the status of the current span to error.

  ## Examples:

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
  def record_exception(exception) when is_exception(exception) do
    Tracer.record_exception(exception)
    set_error(exception)

    exception
  end

  def record_exception(error) do
    Logger.warning("O11y.record_exception/1 expects an exception, but got: #{inspect(error)}")
    set_error(error)

    error
  end

  @doc """
  Sets the status of the current span to error
  """
  def set_error do
    Tracer.set_status(OpenTelemetry.status(:error))
  end

  @doc """
  Sets the status of the current span to error, and sets an error message.

  # Examples:

  ```elixir
  iex> O11y.set_error("something went wrong")
  "something went wrong"
  ```

  ```elixir
  iex> O11y.set_error(%RuntimeError{message: "something went wrong"})
  %RuntimeError{message: "something went wrong"}
  ```

  ```elixir
  iex> O11y.set_error(%Jason.DecodeError{position: 0, token: nil, data: ""})
  %Jason.DecodeError{position: 0, token: nil, data: ""}
  ```
  """
  def set_error(message) when is_binary(message) do
    Tracer.set_status(:error, message)
    message
  end

  def set_error(exception) when is_exception(exception) do
    Tracer.set_status(:error, Exception.message(exception))
    exception
  end

  def set_error(message) do
    Tracer.set_status(:error, inspect(message))
    message
  end

  @doc """
  This function is typically used to "inject" trace context information into http headers such that
  the trace can be continued in another service. However, it can also be used to link span in cases where
  OpenTelemetry.Ctx.attach/1 will not work (such as when the parent span has already ended or been removed from the dictionary).

  ## Examples:
  ```elixir
  iex> res = Tracer.with_span "some_span", do: O11y.get_distributed_trace_ctx()
  iex> [{"traceparent", _}] = res
  ```
  """
  def get_distributed_trace_ctx, do: :otel_propagator_text_map.inject([])

  @doc """
  This is the counterpart to `get_distributed_trace_ctx/0`. It is used to "extract" trace context information from http headers.
  This context information is stored in a string so it can be passed around by other means as well.

  ## Examples:
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
