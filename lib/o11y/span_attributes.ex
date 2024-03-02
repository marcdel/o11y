defprotocol O11y.SpanAttributes do
  @moduledoc """
  Defines a protocol for returning opentelemetry span attributes from an object.
  """

  @doc """
  Returns the opentelemetry span attributes for the given object. You can use it similarly to Jason's @derive annotation:
    `@derive {Jason.Encoder, only: [....]}`

  Examples of outputs from the docs below:
    [{"/http/user_agent" "Mozilla/5.0 ..."}
     {"/http/server_latency", 300}
     {"abc.com/myattribute", True}
     {"abc.com/score", 10.239}]
  """
  @fallback_to_any true
  @spec get(any()) :: OpenTelemetry.attributes_map()
  def get(thing)
end

defimpl O11y.SpanAttributes, for: Any do
  defguard is_otlp_value(value)
           when is_binary(value) or is_integer(value) or is_boolean(value) or is_float(value)

  def get(thing) when is_otlp_value(thing), do: thing
  def get(thing), do: inspect(thing)
end
