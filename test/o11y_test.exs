defmodule O11yTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  setup [:otel_pid_reporter]

  defmodule User do
    @derive O11y.SpanAttributes
    defstruct [:id, :name]
  end

  describe "set_attribute" do
    test "appends the given attribute to the span" do
      Tracer.with_span "do_stuff" do
        O11y.set_attribute(:id, 123)
        O11y.set_attribute(:enabled?, true)
        O11y.set_attribute(:balance, 24.75)
        O11y.set_attribute(:type, :admin)
      end

      expected = %{
        id: 123,
        enabled?: true,
        balance: 24.75,
        type: ":admin"
      }

      assert_span("do_stuff", attributes: expected)
    end

    test "can't handle derived structs yet" do
      Tracer.with_span "login" do
        O11y.set_attribute(:user, %User{id: 123, name: "Alice"})
      end

      assert_span("login", attributes: %{})
    end
  end

  describe "set_attributes" do
    test "appends struct attributes prepended with the given name" do
      Tracer.with_span "login" do
        O11y.set_attributes(%User{id: 123, name: "Alice"})
      end

      expected = %{
        id: 123,
        name: "Alice"
      }

      assert_span("login", attributes: expected)
    end
  end
end
