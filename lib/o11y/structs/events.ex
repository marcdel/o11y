defmodule O11y.Events do
  @moduledoc """
  Struct version of the erlang record definition for the events record on a span.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/src/otel_events.erl#L27
  """

  alias O11y.Event

  @type t() :: list(Event.t())

  @type events_record() ::
          {
            :events,
            count_limit :: integer(),
            attribute_per_event_limit :: integer(),
            attribute_value_length_limit :: integer() | :infinity,
            dropped :: integer(),
            list :: list(Event.event_record())
          }

  def from_record(:undefined), do: []

  @doc """
  Builds a list of event structs from the given record.

  ## Examples

  ```elixir
  iex> O11y.Events.from_record({:events, 128, 128, :infinity, 0, [{:event, 1, "event_name", {:attributes, 128, :infinity, 0, %{key: "value"}}}]})
  [%O11y.Event{
    name: "event_name",
    native_time: 1,
    attributes: %{key: "value"}
  }]
  ```
  """
  @spec from_record(events_record()) :: t()
  def from_record({:events, _, _, _, _, events}) do
    Enum.map(events, &Event.from_record/1)
  end
end
