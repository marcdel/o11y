defprotocol O11y.SpanAttributes do
  @moduledoc """
  Defines a protocol for returning opentelemetry span attributes from an object.
  The easiest way to use this is to use the `@derive` attribute on a struct as shown below,
  but you can also implement the protocol manually if you need to define custom behavior.

  With the basic derive, all fields in the struct will be returned as attributes:
  ```elixir
  defmodule Basic do
    @derive O11y.SpanAttributes
    defstruct [:id, :name]
  end
  ```

  You can also use the `only` and `except` options to include or exclude specific fields:
  ```elixir
  defmodule Only do
    @derive {O11y.SpanAttributes, only: [:id, :name]}
    defstruct [:id, :name, :email, :password]
  end
  ```

  ```elixir
  defmodule Except do
    @derive {O11y.SpanAttributes, except: [:email, :password]}
    defstruct [:id, :name, :email, :password]
  end
  ```

  Or you can manually implement the protocol for a struct:
  ```elixir
  defmodule Fancy do
    defstruct [:url, :token]
  end

  defimpl O11y.SpanAttributes, for: Fancy do
    def get(%{url: url, token: token}) do
      masked_token = token |> String.slice(-4, 4) |> String.pad_leading(String.length(token), "*")
      [{"url", url}, {"token", masked_token}]
    end
  end
  ```
  """

  @type otlp_value() :: String.t() | integer() | float() | boolean()

  @doc """
  Returns the opentelemetry span attributes for the given object as a list of tuples.
  """
  @fallback_to_any true
  @spec get(any()) :: OpenTelemetry.attributes_map() | otlp_value()
  def get(thing)
end

defimpl O11y.SpanAttributes, for: Any do
  import O11y.Attributes, only: [is_otlp_value: 1]

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

  def get(thing) when is_otlp_value(thing), do: thing

  # Structs that do not derive the protocol end up here and are turned into maps (which implement Enumerable)
  def get(%_{} = thing) when is_struct(thing), do: thing |> Map.from_struct() |> get()

  def get(thing) when is_map(thing), do: Enum.map(thing, fn {k, v} -> {to_string(k), v} end)

  def get(thing) when is_list(thing) do
    if Keyword.keyword?(thing) do
      Enum.map(thing, fn {k, v} -> {to_string(k), v} end)
    else
      inspect(thing)
    end
  end

  def get(thing), do: inspect(thing)
end
