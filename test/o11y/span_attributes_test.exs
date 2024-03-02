defmodule O11y.SpanAttributesTest do
  use ExUnit.Case, async: true

  alias O11y.SpanAttributes

  describe "handles otlp and non-otlp type attributes" do
    test "strings, integers, booleans, and floats are passed through" do
      assert SpanAttributes.get(1) == 1
      assert SpanAttributes.get("1") == "1"
      assert SpanAttributes.get(true) == true
      assert SpanAttributes.get(1.0) == 1.0
    end

    test "inspect()s anything else" do
      assert SpanAttributes.get({:error, "too sick bro"}) == "{:error, \"too sick bro\"}"
      assert SpanAttributes.get(:pink) == ":pink"
      assert SpanAttributes.get(nil) == "nil"
      assert SpanAttributes.get([1, 2, 3, 4]) == "[1, 2, 3, 4]"
      assert SpanAttributes.get(%{id: 1}) == "%{id: 1}"
      assert SpanAttributes.get(%{"id" => 1}) == "%{\"id\" => 1}"
      assert SpanAttributes.get(self()) =~ ~r/#PID<\d+\.\d+\.\d+>/
      assert SpanAttributes.get(fn i -> i + 1 end) =~ ~r/#Function/
    end
  end

  describe "implementing the protocol in structs" do
    defmodule BasicModule do
      defstruct [:id, :name]

      defimpl O11y.SpanAttributes do
        def get(bm) do
          %{id: bm.id, name: bm.name}
        end
      end
    end

    test "derives the protocol for structs" do
      bm = %BasicModule{id: 1, name: "basic"}
      assert SpanAttributes.get(bm) == %{id: 1, name: "basic"}
    end
  end
end
