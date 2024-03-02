defmodule O11yTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  setup [:otel_pid_reporter]

  describe "set_attribute" do
    test "appends the given attribute to the span" do
      Tracer.with_span "do_stuff" do
        O11y.set_attribute(:id, 123)
      end

      assert_span("do_stuff", attributes: %{id: 123})
    end
  end
end
