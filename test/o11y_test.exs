defmodule O11yTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  setup [:otel_pid_reporter]

  defmodule Regular do
    defstruct [:id, :name, :email, :password]
  end

  defmodule User do
    @derive {O11y.SpanAttributes, only: [:id, :name]}
    defstruct [:id, :name, :email, :password]
  end

  describe "set_attribute" do
    test "appends the given attribute to the span" do
      Tracer.with_span "checkout" do
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

      assert_span("checkout", attributes: expected)
    end

    test "can't handle structs or maps" do
      Tracer.with_span "login" do
        O11y.set_attribute(:record, %{id: 1})
        O11y.set_attribute(:user, %User{id: 123, name: "Alice"})
        O11y.set_attribute(:user, %Regular{id: 123, name: "Alice"})
      end

      assert_span("login", attributes: %{})
    end
  end

  describe "set_attributes" do
    test "maps have all their keys added" do
      Tracer.with_span "login" do
        user = %{id: 123, name: "Alice", email: "user@email.com", password: "password"}
        O11y.set_attributes(user)
      end

      expected =
        %{
          "id" => 123,
          "name" => "Alice",
          "email" => "user@email.com",
          "password" => "password"
        }

      assert_span("login", attributes: expected)
    end

    test "non-derived structs have all their keys added" do
      Tracer.with_span "login" do
        user = %Regular{id: 123, name: "Alice", email: "user@email.com", password: "password"}
        O11y.set_attributes(user)
      end

      expected =
        %{
          "id" => 123,
          "name" => "Alice",
          "email" => "user@email.com",
          "password" => "password"
        }

      assert_span("login", attributes: expected)
    end

    test "adds struct attributes to the span" do
      Tracer.with_span "login" do
        O11y.set_attributes(%User{id: 123, name: "Alice"})
      end

      assert_span("login", attributes: %{"id" => 123, "name" => "Alice"})
    end

    test "appends struct attributes prepended with the given key" do
      Tracer.with_span "login" do
        O11y.set_attributes(:user, %User{id: 123, name: "Alice"})
      end

      assert_span("login", attributes: %{"user.id" => 123, "user.name" => "Alice"})
    end
  end
end
