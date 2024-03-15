defmodule O11y.SpanTest do
  use ExUnit.Case, async: true
  use O11y.RecordDefinitions

  alias O11y.Span

  doctest O11y.Attributes
  doctest O11y.Event
  doctest O11y.Events
  doctest O11y.Link
  doctest O11y.Links
  doctest O11y.Span
  doctest O11y.Status

  describe "from_record/1" do
    test "can create a struct from a record" do
      span_record = span(name: "hello")
      %Span{} = span = Span.from_record(span_record)
      assert span.name == "hello"
    end

    test "can create a struct from a record with the bare minimum fields" do
      span_record =
        span(name: "hello", trace_id: 123, span_id: 456, start_time: 789, end_time: 101_112)

      %Span{} = span = Span.from_record(span_record)

      assert span.name == "hello"
      assert is_integer(span.trace_id)
      assert is_integer(span.span_id)
      assert is_integer(span.start_time)
      assert is_integer(span.end_time)
    end

    test "computes the duration in milliseconds" do
      span_record =
        span(
          name: "hello",
          start_time: -576_460_751_540_176_958,
          end_time: -576_460_751_538_429_167
        )

      %Span{} = span = Span.from_record(span_record)

      assert is_integer(span.duration_ms)
      assert span.duration_ms == 1
    end

    test "more thorough example" do
      span_record =
        {
          :span,
          36_028_033_703_494_123_531_935_328_165_008_164_641,
          3_003_871_636_294_788_166,
          [],
          9_251_127_051_694_223_323,
          "span3",
          :internal,
          -576_460_751_554_471_834,
          -576_460_751_554_453_625,
          {:attributes, 128, :infinity, 0, %{attr2: "value2"}},
          {:events, 128, 128, :infinity, 0,
           [
             {:event, -576_460_751_554_458_125, "event1",
              {:attributes, 128, :infinity, 0, %{attr3: "value3"}}}
           ]},
          {:links, 128, 128, :infinity, 0,
           [
             {:link, 15_885_629_928_321_603_655_903_684_450_721_700_386,
              4_778_191_783_967_788_040,
              {:attributes, 128, :infinity, 0, %{link_attr1: "link_value1"}}, []}
           ]},
          {:status, :error, "whoops!"},
          1,
          true,
          :undefined
        }

      span = Span.from_record(span_record)

      assert span.name == "span3"
      assert span.attributes == %{attr2: "value2"}

      assert [event] = span.events
      assert event.name == "event1"
      assert event.attributes == %{attr3: "value3"}
      assert event.native_time == -576_460_751_554_458_125

      assert [link] = span.links
      assert link.trace_id == 15_885_629_928_321_603_655_903_684_450_721_700_386
      assert link.span_id == 4_778_191_783_967_788_040
      assert link.attributes == %{link_attr1: "link_value1"}
      assert link.tracestate == []

      assert span.status.code == :error
      assert span.status.message == "whoops!"

      assert span.trace_flags == 1
      assert span.is_recording == true
      assert span.instrumentation_scope == :undefined
    end
  end
end
