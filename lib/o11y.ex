defmodule O11y do
  @moduledoc false

  require OpenTelemetry.Tracer, as: Tracer

  def set_attribute(key, value) do
    Tracer.set_attribute(key, value)
  end
end
