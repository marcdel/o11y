defmodule O11y.Event do
  @moduledoc """
  Struct version of the erlang record definition for an event.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/include/otel_span.hrl#L81
  """

  defstruct [:name, :native_time, :attributes]

  alias O11y.Attributes

  @type t() :: %__MODULE__{
          name: String.t(),
          native_time: integer(),
          attributes: Attributes.t()
        }

  @type event_record() :: {
          :event,
          system_time_native :: integer(),
          name :: String.t() | atom(),
          attributes :: Attributes.attributes_record()
        }

  @doc """
  Builds an event struct from the given record.

  ## Examples

  ```elixir
  iex> O11y.Event.from_record({:event, 1, "event_name", {:attributes, 128, :infinity, 0, %{key: "value"}}})
  %O11y.Event{
    name: "event_name",
    native_time: 1,
    attributes: %{key: "value"}
  }
  ```
  """
  @spec from_record(event_record()) :: t()
  def from_record({:event, native_time, name, attributes}) do
    %__MODULE__{
      name: name,
      native_time: native_time,
      attributes: Attributes.from_record(attributes)
    }
  end
end
