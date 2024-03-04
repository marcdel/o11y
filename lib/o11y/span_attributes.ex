defprotocol O11y.SpanAttributes do
  @moduledoc """
  Defines a protocol for returning opentelemetry span attributes from an object.
  The easiest way to use this is to use the `@derive` attribute on a struct as shown below,
  but you can also implement the protocol manually if you need to define custom behavior.

    defmodule Basic do
      @derive O11y.SpanAttributes
      defstruct [:id, :name]
    end

    defmodule Only do
      @derive {O11y.SpanAttributes, only: [:id, :name]}
      defstruct [:id, :name, :email, :password]
    end

    defmodule Except do
      @derive {O11y.SpanAttributes, except: [:email, :password]}
      defstruct [:id, :name, :email, :password]
    end
  """

  @doc """
  Returns the opentelemetry span attributes for the given object as a list of tuples.
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
          |> Enum.map(fn {k, v} -> {to_string(k), v} end)
        end
      end
    end
  end

  defguard is_otlp_value(value)
           when is_binary(value) or is_integer(value) or is_boolean(value) or is_float(value)

  def get(thing) when is_otlp_value(thing), do: thing
  def get(%_{} = thing) when is_struct(thing), do: thing |> Map.from_struct() |> get()
  def get(thing) when is_map(thing), do: Enum.map(thing, fn {k, v} -> {to_string(k), v} end)
  def get(thing), do: inspect(thing)
end
