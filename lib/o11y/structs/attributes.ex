defmodule O11y.Attributes do
  @moduledoc """
  This is more of a convenience module since the attributes that the record wraps are a plain map.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/c1ccdffb11253f5da63146a6c014db41bb4b27cc/apps/opentelemetry_api/src/otel_attributes.erl#L37
  """

  def from_record(:undefined), do: %{}
  def from_record({:attributes, _, _, _, attributes}), do: attributes
  def to_record(attributes), do: {:attributes, 128, :infinity, 0, attributes}
end
