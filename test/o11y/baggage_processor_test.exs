defmodule O11y.BaggageProcessorTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  describe "on_start" do
    test "adds baggage attributes to span" do
      OpenTelemetry.Baggage.set("key1", "value1")
      ctx = OpenTelemetry.Ctx.get_current()
      span_record = O11y.Span.to_record(%O11y.Span{name: "checkout"})
      config = %{}

      updated_span_record = O11y.BaggageProcessor.on_start(ctx, span_record, config)

      span = O11y.Span.from_record(updated_span_record)
      assert span.attributes == %{"key1" => "value1"}
    end

    test "merges the two attribute maps" do
      OpenTelemetry.Baggage.set("key1", "value1")
      ctx = OpenTelemetry.Ctx.get_current()
      attributes = %{"key2" => "value2"}
      span_record = O11y.Span.to_record(%O11y.Span{name: "checkout", attributes: attributes})
      config = %{}

      updated_span_record = O11y.BaggageProcessor.on_start(ctx, span_record, config)

      span = O11y.Span.from_record(updated_span_record)
      assert span.attributes == %{"key1" => "value1", "key2" => "value2"}
    end

    test "doesn't overwrite existing attributes on the span" do
      OpenTelemetry.Baggage.set("key", "new_value")
      ctx = OpenTelemetry.Ctx.get_current()
      attributes = %{"key" => "original_value"}
      span_record = O11y.Span.to_record(%O11y.Span{name: "checkout", attributes: attributes})
      config = %{}

      updated_span_record = O11y.BaggageProcessor.on_start(ctx, span_record, config)

      span = O11y.Span.from_record(updated_span_record)
      assert span.attributes == %{"key" => "original_value"}
    end

    test "rescues exceptions" do
      ctx = OpenTelemetry.Ctx.get_current()
      config = %{}

      span = O11y.BaggageProcessor.on_start(ctx, nil, config)
      assert span == nil
    end
  end
end
