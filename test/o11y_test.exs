defmodule O11yTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  setup [:otel_pid_reporter]

  describe "set_attribute" do
    test "appends the given attribute to the span" do
      Tracer.with_span "do_stuff" do
        O11y.set_attribute(:id, 123)
        O11y.set_attribute(:enabled?, true)
        O11y.set_attribute(:balance, 24.75)
      end

      expected = %{
        id: 123,
        enabled?: true,
        balance: 24.75
      }

      assert_span("do_stuff", attributes: expected)
    end
  end
end
