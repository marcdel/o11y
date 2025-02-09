defmodule O11y.Link do
  @moduledoc """
  Struct version of the erlang record definition for a link.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/include/otel_span.hrl#L74
  """

  alias O11y.Attributes

  defstruct [:trace_id, :span_id, :attributes, :tracestate]

  @type t() :: %__MODULE__{
          trace_id: integer(),
          span_id: integer(),
          attributes: Attributes.t(),
          # idk what the hell, i think it's a list of key-value pairs but the docs are very mysterious 👻
          # https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/src/otel_tracestate.erl#L39
          tracestate: list(tuple()) | :undefined
        }

  @type link_record() :: {
          :link,
          trace_id :: integer(),
          span_id :: integer(),
          attributes :: Attributes.attributes_record(),
          tracestate :: list(tuple()) | :undefined
        }

  @doc """
  Builds a link struct from the given record.

  ## Examples

  ```elixir
  iex> O11y.Link.from_record({:link, 128, 128, {:attributes, 128, :infinity, 0, %{key: "value"}}, []})
  %O11y.Link{
    trace_id: 128,
    span_id: 128,
    attributes: %{key: "value"},
    tracestate: []
  }
  ```
  """
  @spec from_record(link_record()) :: t()
  def from_record({:link, trace_id, span_id, attributes, tracestate}) do
    %__MODULE__{
      trace_id: trace_id,
      span_id: span_id,
      attributes: Attributes.from_record(attributes),
      tracestate: tracestate
    }
  end

  def to_record(%__MODULE__{trace_id: trace_id, span_id: span_id, attributes: attributes, tracestate: tracestate}) do
    {:link, trace_id, span_id, Attributes.to_record(attributes), tracestate}
  end
end
