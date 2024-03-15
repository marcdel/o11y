defmodule O11y.Link do
  @moduledoc false

  defstruct [:trace_id, :span_id, :attributes, :tracestate]

  alias O11y.Attributes

  def from_record({:link, trace_id, span_id, attributes, tracestate}) do
    %__MODULE__{
      trace_id: trace_id,
      span_id: span_id,
      attributes: Attributes.from_record(attributes),
      # idk what the hell: https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/src/otel_tracestate.erl#L39
      tracestate: tracestate
    }
  end
end
