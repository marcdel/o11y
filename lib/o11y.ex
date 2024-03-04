defmodule O11y do
  @moduledoc false

  require OpenTelemetry.Tracer, as: Tracer

  @doc """
  Sets the given attribute on the current span. If the value is not a valid OTLP type,
  it will be converted to a string with `inspect`.

  This method does not support structs to maps, regardless of whether the struct implements the O11y.SpanAttributes protocol.
  You need to use `set_attributes/1` for that.

  Example:

    iex> set_attribute("key", "value")
  """
  def set_attribute(key, value) do
    value = O11y.SpanAttributes.get(value)
    Tracer.set_attribute(key, value)
  end

  @doc """
  Adds the given attributes as a list, map, or struct to the current span.
  If the value is a maps or struct, it will be converted to a list of key-value pairs.
  If the struct derives the O11y.SpanAttributes protocol, it will honor the except and only options.

  Example:

    iex> set_attributes(%{key: "value"})
  """
  def set_attributes(values) do
    values = O11y.SpanAttributes.get(values)
    Tracer.set_attributes(values)
  end

  @doc """
  Same as set_attributes/1, but with a prefix for all keys.

  Example:

    iex> set_attributes("my_prefix", %{key: "value"})
  """
  def set_attributes(prefix, values) do
    values
    |> O11y.SpanAttributes.get()
    |> Enum.map(fn {key, value} -> {"#{prefix}.#{key}", value} end)
    |> Tracer.set_attributes()
  end
end
