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

  describe "deriving the protocol in structs" do
    defmodule Basic do
      @derive O11y.SpanAttributes
      defstruct [:id, :name]
    end

    defmodule Only do
      @derive {O11y.SpanAttributes, only: [:id, :name]}
      defstruct [:id, :name, :email, :password]
    end

    defmodule Except do
      @derive {O11y.SpanAttributes, except: [:email, :password]}
      defstruct [:id, :name, :email, :password]
    end

    test "returns all fields if no options are given" do
      assert SpanAttributes.get(%Basic{id: 1, name: "basic"}) == %{id: 1, name: "basic"}
    end

    test "returns only fields specified in the only option" do
      thing = %Only{id: 1, name: "only", email: "only@email.com", password: "secret"}
      assert SpanAttributes.get(thing) == %{id: 1, name: "only"}
    end

    test "returns all fields except those specified in the except option" do
      thing = %Except{id: 1, name: "except", email: "except@email.com", password: "secret"}
      assert SpanAttributes.get(thing) == %{id: 1, name: "except"}
    end
  end
end
