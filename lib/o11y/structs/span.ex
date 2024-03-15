defmodule O11y.Span do
  @moduledoc """
  Struct version of the erlang record definition for span

  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/include/otel_span.hrl

  ```elixir
  iex> span_record = {
    :span,
    230_767_895_094_221_212_207_434_514_454_409_384_028,
    11_664_055_003_178_746_420,
    [],
    :undefined,
    "login",
    :internal,
    -576_460_751_415_352_875,
    -576_460_751_415_250_041,
    {:attributes, 128, :infinity, 0,
     %{
       "email" => "user@email.com",
       "id" => 123,
       "name" => "Alice",
       "password" => "password"
     }},
    {:events, 128, 128, :infinity, 0, []},
    {:links, 128, 128, :infinity, 0, []},
    :undefined,
    1,
    false,
    :undefined
  }
  ```
  """

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

  alias O11y.Attributes
  alias O11y.Events
  alias O11y.Links
  alias O11y.Status

  defguard is_span_record(value) when is_tuple(value) and tuple_size(value) == 16

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

  defp duration(start_time, end_time) when is_integer(start_time) and is_integer(end_time) do
    System.convert_time_unit(end_time - start_time, :native, :millisecond)
  end

  defp duration(_, _), do: :undefined
end
