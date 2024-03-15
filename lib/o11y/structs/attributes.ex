defmodule O11y.Attributes do
  @moduledoc """
  This is more of a convenience module since the attributes that the record wraps are a plain map.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/c1ccdffb11253f5da63146a6c014db41bb4b27cc/apps/opentelemetry_api/src/otel_attributes.erl#L37
  """

  @type t() :: map()
  @type attributes_record() :: {
          :attributes,
          count_limit :: integer(),
          value_length_limit :: integer() | :infinity,
          dropped :: integer(),
          map :: map()
        }

  @doc """
  Builds a map from the given attribute record.

  ## Examples

  ```elixir
  iex> O11y.Attributes.from_record({:attributes, 128, :infinity, 0, %{key: "value"}})
  %{key: "value"}
  ```
  """
  @spec from_record(attributes_record()) :: t()
  def from_record(:undefined), do: %{}
  def from_record({:attributes, _, _, _, attributes}), do: attributes

  @spec to_record(t()) :: attributes_record()
  def to_record(attributes), do: {:attributes, 128, :infinity, 0, attributes}
end
