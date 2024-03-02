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
  defmacro __deriving__(module, struct, options) do
    fields = Map.keys(struct) -- [:__exception__, :__struct__]
    only = Keyword.get(options, :only, fields)
    except = Keyword.get(options, :except, [])

    filtered_fields =
      fields
      |> Enum.reject(&(&1 in except))
      |> Enum.filter(&(&1 in only))

    quote do
      defimpl O11y.SpanAttributes, for: unquote(module) do
        def get(var!(struct)) do
          Map.take(var!(struct), unquote(filtered_fields))
        end
      end
    end
  end

  defguard is_otlp_value(value)
           when is_binary(value) or is_integer(value) or is_boolean(value) or is_float(value)

  def get(thing) when is_otlp_value(thing), do: thing
  def get(thing), do: inspect(thing)
end
