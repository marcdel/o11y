defmodule O11y.Span do
  @moduledoc """
  Struct version of the erlang record definition for span, along with its dependent entities.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/include/otel_span.hrl#L19
  """

  alias O11y.Attributes
  alias O11y.Event
  alias O11y.Events
  alias O11y.Link
  alias O11y.Links
  alias O11y.Status

  defstruct [
    :trace_id,
    :span_id,
    :tracestate,
    :parent_span_id,
    :name,
    :kind,
    :start_time,
    :end_time,
    :duration_ms,
    :attributes,
    :events,
    :links,
    :status,
    :trace_flags,
    :is_recording,
    :instrumentation_scope
  ]

  @type t() :: %__MODULE__{
          trace_id: integer() | :undefined,
          span_id: integer() | :undefined,
          tracestate: list(tuple()),
          parent_span_id: integer() | :undefined,
          name: String.t() | atom(),
          kind: atom(),
          start_time: integer() | :undefined,
          end_time: integer() | :undefined,
          duration_ms: integer() | :undefined,
          attributes: Attributes.t() | :undefined,
          events: [Event.t()],
          links: [Link.t()],
          status: Status.t() | :undefined,
          trace_flags: integer() | :undefined,
          is_recording: boolean() | :undefined,
          instrumentation_scope: term() | :undefined
        }

  @type span_kind() :: :internal | :server | :client | :producer | :consumer

  @type span_record() :: {
          :span,
          trace_id :: integer() | :undefined,
          span_id :: integer() | :undefined,
          tracestate :: list(tuple()),
          parent_span_id :: integer() | :undefined,
          name :: String.t() | atom(),
          kind :: span_kind() | :undefined,
          start_time :: integer() | :undefined,
          end_time :: integer() | :undefined,
          attributes :: Attributes.attributes_record(),
          events :: Events.events_record(),
          links :: Links.links_record(),
          status :: Status.status_record(),
          trace_flags :: integer() | :undefined,
          is_recording :: boolean() | :undefined,
          instrumentation_scope :: term() | :undefined
        }

  @doc """
  Guard definition for the from_record function.
  """
  defguard is_span_record(value) when is_tuple(value) and tuple_size(value) == 16

  @doc """
  Builds a Span struct with all its properties filled out from the given record.

  ## Examples:

  ```elixir
  iex> span_record =
  iex> {
  ...>   :span,
  ...>   36028033703494123531935328165008164641,
  ...>   3003871636294788166,
  ...>   [],
  ...>   9251127051694223323,
  ...>   "span3",
  ...>   :internal,
  ...>   -576460751554471834,
  ...>   -576460751554453625,
  ...>   {:attributes, 128, :infinity, 0, %{attr2: "value2"}},
  ...>   {:events, 128, 128, :infinity, 0,
  ...>     [
  ...>       {:event, -576460751554458125, "event1",
  ...>       {:attributes, 128, :infinity, 0, %{attr3: "value3"}}}
  ...>     ]},
  ...>   {:links, 128, 128, :infinity, 0,
  ...>     [
  ...>       {:link, 15885629928321603655903684450721700386,
  ...>       4778191783967788040,
  ...>       {:attributes, 128, :infinity, 0, %{link_attr1: "link_value1"}}, []}
  ...>     ]},
  ...>   {:status, :error, "whoops!"},
  ...>   1,
  ...>   true,
  ...>   :undefined
  ...> }
  iex> Span.from_record(span_record)
  iex> %O11y.Span{
  ...>   trace_id: 36028033703494123531935328165008164641,
  ...>   span_id: 3003871636294788166,
  ...>   tracestate: [],
  ...>   parent_span_id: 9251127051694223323,
  ...>   name: "span3",
  ...>   kind: :internal,
  ...>   start_time: -576460751554471834,
  ...>   end_time: -576460751554453625,
  ...>   duration_ms: 0,
  ...>   attributes: %{attr2: "value2"},
  ...>   events: [
  ...>     %O11y.Event{
  ...>       name: "event1",
  ...>       native_time: -576460751554458125,
  ...>       attributes: %{attr3: "value3"}
  ...>     }
  ...>   ],
  ...>   links: [
  ...>     %O11y.Link{
  ...>       trace_id: 15885629928321603655903684450721700386,
  ...>       span_id: 4778191783967788040,
  ...>       attributes: %{link_attr1: "link_value1"},
  ...>       tracestate: []
  ...>     }
  ...>   ],
  ...>   status: %O11y.Status{code: :error, message: "whoops!"},
  ...>   trace_flags: 1,
  ...>   is_recording: true,
  ...>   instrumentation_scope: :undefined
  ...> }
  ```
  """
  @spec from_record(span_record()) :: t()
  def from_record(span_record) when is_span_record(span_record) do
    {
      :span,
      trace_id,
      span_id,
      tracestate,
      parent_span_id,
      name,
      kind,
      start_time,
      end_time,
      attributes,
      events,
      links,
      status,
      trace_flags,
      is_recording,
      instrumentation_scope
    } = span_record

    %__MODULE__{
      trace_id: trace_id,
      span_id: span_id,
      tracestate: tracestate,
      parent_span_id: parent_span_id,
      name: name,
      kind: kind,
      start_time: start_time,
      end_time: end_time,
      duration_ms: duration(start_time, end_time),
      attributes: Attributes.from_record(attributes),
      events: Events.from_record(events),
      links: Links.from_record(links),
      status: Status.from_record(status),
      # Deals with sampling, etc.
      trace_flags: trace_flags,
      is_recording: is_recording,
      # https://github.com/open-telemetry/opentelemetry-specification/blob/main/specification/glossary.md#instrumentation-scope
      instrumentation_scope: instrumentation_scope
    }
  end

  def to_record(span_struct) do
    {
      :span,
      span_struct.trace_id,
      span_struct.span_id,
      span_struct.tracestate,
      span_struct.parent_span_id,
      span_struct.name,
      span_struct.kind,
      span_struct.start_time,
      span_struct.end_time,
      Attributes.to_record(span_struct.attributes),
      Events.to_record(span_struct.events),
      Links.to_record(span_struct.links),
      Status.to_record(span_struct.status),
      span_struct.trace_flags,
      span_struct.is_recording,
      span_struct.instrumentation_scope
    }
  end

  defp duration(start_time, end_time) when is_integer(start_time) and is_integer(end_time) do
    System.convert_time_unit(end_time - start_time, :native, :millisecond)
  end

  defp duration(_, _), do: :undefined
end
