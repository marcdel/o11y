defmodule O11y do
  @moduledoc false

  require OpenTelemetry.Tracer, as: Tracer

  def set_attribute(key, value) do
    value = O11y.SpanAttributes.get(value)
    Tracer.set_attribute(key, value)
  end

  def set_attributes(value) do
    value = O11y.SpanAttributes.get(value)
    Tracer.set_attributes(value)
  end
end
