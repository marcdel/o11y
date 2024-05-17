defmodule O11yTest do
  use ExUnit.Case, async: true
  use O11y.TestHelper

  doctest O11y

  defmodule Regular do
    defstruct [:id, :name, :email, :password]
  end

  defmodule User do
    @derive {O11y.SpanAttributes, only: [:id, :name]}
    defstruct [:id, :name, :email, :password]
  end

  describe "with_span" do
    test "forwards name and options to Tracer.with_span" do
      O11y.with_span("checkout", fn ->
        O11y.set_attribute(:id, 123)
      end)

      span = assert_span("checkout")
      assert span.attributes == %{"id" => 123}
    end

    test "namespaces attributes given in the start_opts" do
      O11y.with_span("login", %{attributes: %{id: 123}, namespace: "app"}, fn ->
        :ok
      end)

      span = assert_span("login")

      assert span.attributes == %{"app.id" => 123}
    end
  end

  describe "start_span" do
    test "starts a span with the given name" do
      O11y.start_span("checkout")
      Tracer.end_span()

      assert_span("checkout")
    end

    test "forwards opts to Tracer.start_span" do
      O11y.start_span("checkout", attributes: %{id: 123, name: "Alice"})
      Tracer.end_span()

      span = assert_span("checkout")
      assert span.attributes == %{id: 123, name: "Alice"}
    end

    test "sets the new span as current" do
      Tracer.with_span "checkout", status: :error do
        parent = Tracer.current_span_ctx()
        O11y.start_span("calculate_tax")
        child = Tracer.current_span_ctx()

        assert child != parent

        Tracer.end_span()
      end
    end

    test "returns the parent span to be passed to end_span" do
      Tracer.with_span "checkout", status: :error do
        expected = Tracer.current_span_ctx()
        parent = O11y.start_span("calculate_tax")

        assert parent == expected

        Tracer.end_span()
      end
    end
  end

  describe "end_span" do
    test "ends the current span" do
      O11y.start_span("checkout")
      |> O11y.end_span()

      assert_span("checkout")
    end

    test "sets the current span to the given parent span" do
      Tracer.with_span "checkout", status: :error do
        parent = O11y.start_span("calculate_tax")

        O11y.end_span(parent)
        assert parent == Tracer.current_span_ctx()
      end
    end

    test "returns the current (parent) span to match the Tracer.end_span interface" do
      Tracer.with_span "checkout", status: :error do
        parent = O11y.start_span("calculate_tax")

        assert O11y.end_span(parent) == parent
      end
    end
  end

  describe "add_event" do
    test "adds an event with the given name to the current span" do
      Tracer.with_span "checkout" do
        O11y.add_event("payment_received")
      end

      span = assert_span("checkout")
      assert [%{name: "payment_received"}] = span.events
    end

    test "namespaces attributes given to on the event" do
      Tracer.with_span "checkout" do
        O11y.add_event("payment_received", %{id: 123}, namespace: "app")
      end

      span = assert_span("checkout")
      assert [%{attributes: %{"app.id" => 123}}] = span.events
    end
  end

  describe "set_attribute" do
    test "appends the given attribute to the span" do
      Tracer.with_span "checkout" do
        O11y.set_attribute(:id, 123)
        O11y.set_attribute(:enabled?, true)
        O11y.set_attribute(:balance, 24.75)
        O11y.set_attribute(:type, :admin)
      end

      expected = %{"balance" => 24.75, "enabled?" => true, "id" => 123, "type" => :admin}

      span = assert_span("checkout")
      assert span.attributes == expected
    end

    test "prefixes map and struct keys with the given name" do
      Tracer.with_span "login" do
        O11y.set_attribute(:record, %{total: 10.0, items: 3})
        O11y.set_attribute(:user, %User{id: 123, name: "Alice"})

        O11y.set_attribute(:regular, %Regular{
          id: 123,
          name: "Alice",
          email: "alice@aol.com",
          password: "hunter2"
        })
      end

      span = assert_span("login")

      assert span.attributes == %{
               "record.items" => 3,
               "record.total" => 10.0,
               "regular.email" => "alice@aol.com",
               "regular.id" => 123,
               "regular.name" => "Alice",
               "regular.password" => "hunter2",
               "user.id" => 123,
               "user.name" => "Alice"
             }
    end

    test "returns nil values even though they're ignored" do
      Tracer.with_span "login" do
        O11y.set_attribute(:id, nil)
      end

      span = assert_span("login")
      assert span.attributes == %{"id" => nil}
    end

    test "nil attribute names are ignored" do
      Tracer.with_span "login" do
        O11y.set_attribute(nil, 123)
      end

      span = assert_span("login")
      assert span.attributes == %{}
    end

    test "trims leading underscores" do
      Tracer.with_span "login" do
        O11y.set_attribute(:_unused_var, 123)
        O11y.set_attribute("_more_unused", "abc")
      end

      span = assert_span("login")
      assert span.attributes == %{"unused_var" => 123, "more_unused" => "abc"}
    end

    test "namespaces attributes with the given value" do
      Tracer.with_span "login" do
        O11y.set_attribute(:id, 123, namespace: :user)
        O11y.set_attribute(:type, :admin, namespace: "app")
      end

      span = assert_span("login")
      assert span.attributes == %{"user.id" => 123, "app.type" => :admin}
    end

    test "avoids doubling up existing prefixes" do
      Tracer.with_span "login" do
        O11y.set_attribute("app.id", 123, namespace: "app")
        O11y.set_attribute("app_id", 456, namespace: "app")
      end

      span = assert_span("login")
      assert span.attributes == %{"app.id" => 123, "app.app_id" => 456}
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

      span = assert_span("login")
      assert span.attributes == expected
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

      span = assert_span("login")
      assert span.attributes == expected
    end

    test "adds struct attributes to the span" do
      Tracer.with_span "login" do
        O11y.set_attributes(%User{id: 123, name: "Alice"})
      end

      span = assert_span("login")
      assert span.attributes == %{"id" => 123, "name" => "Alice"}
    end

    test "keyword lists have all their keys added" do
      Tracer.with_span "login" do
        user = [id: 123, name: "Alice", email: "alice@email.com"]
        O11y.set_attributes(user)
      end

      expected = %{"email" => "alice@email.com", "id" => 123, "name" => "Alice"}

      span = assert_span("login")
      assert span.attributes == expected
    end

    test "keyword lists with structs handle structs as usual" do
      Tracer.with_span "login" do
        user = %User{id: 123, name: "Alice", email: "alice@email.com"}
        O11y.set_attributes(user: user, awesome: true)
      end

      expected = %{
        "awesome" => true,
        "user.id" => 123,
        "user.name" => "Alice"
      }

      span = assert_span("login")
      assert span.attributes == expected
    end

    test "attribute lists with structs handle structs as usual" do
      Tracer.with_span "login" do
        user = %User{id: 123, name: "Alice", email: "alice@email.com"}
        O11y.set_attributes([{"user", user}, {"awesome", true}])
      end

      expected = %{
        "awesome" => true,
        "user.id" => 123,
        "user.name" => "Alice"
      }

      span = assert_span("login")
      assert span.attributes == expected
    end

    test "lists of tuples with more/less than 2 elements are ignored" do
      Tracer.with_span "login" do
        O11y.set_attributes([{:user, 123, "Alice"}])
        O11y.set_attributes([{:not_awesome}])
      end

      span = assert_span("login")
      assert span.attributes == %{}
    end

    test "maps have all their keys added with a prefix" do
      Tracer.with_span "login" do
        user = [id: 123, name: "Alice", email: "alice@email.com"]
        O11y.set_attributes(user)
      end

      expected = %{"email" => "alice@email.com", "id" => 123, "name" => "Alice"}

      span = assert_span("login")
      assert span.attributes == expected
    end

    test "ignores values that do not have something that can be used as the key" do
      Tracer.with_span "login" do
        O11y.set_attributes([1, 2, 3])
        O11y.set_attributes({:error, "too sick bro"})
        O11y.set_attributes(:pink)
        O11y.set_attributes("boop")
        O11y.set_attributes(12)
        O11y.set_attributes(1.2)
        O11y.set_attributes(true)
      end

      span = assert_span("login")
      assert span.attributes == %{}
    end

    test "adds struct attributes prepended with the given prefix" do
      Tracer.with_span "login" do
        O11y.set_attributes(%User{id: 123, name: "Alice"}, prefix: :user)
      end

      span = assert_span("login")
      assert span.attributes == %{"user.id" => 123, "user.name" => "Alice"}
    end

    test "trims leading underscores" do
      Tracer.with_span "login" do
        O11y.set_attributes(%{id: 123, _name: "Alice"}, prefix: :_user)
        O11y.set_attributes(%{id: 123, _name: "Alice"})
      end

      span = assert_span("login")

      assert span.attributes == %{
               "user.id" => 123,
               "user.name" => "Alice",
               "id" => 123,
               "name" => "Alice"
             }
    end

    test "namespaces attributes with the given value" do
      Tracer.with_span "login" do
        O11y.set_attributes(%User{id: 123, name: "Alice"}, prefix: :user, namespace: :slack)
        O11y.set_attributes(%{type: "crud"}, namespace: "app")
      end

      span = assert_span("login")

      assert span.attributes == %{
               "slack.user.id" => 123,
               "slack.user.name" => "Alice",
               "app.type" => "crud"
             }
    end
  end

  describe "record_exception" do
    test "sets the span status to error" do
      Tracer.with_span "checkout" do
        O11y.record_exception(%RuntimeError{message: "something went wrong"})
      end

      span = assert_span("checkout")
      assert span.status.code == :error
      assert span.status.message == "something went wrong"
    end

    test "adds an exception event to the span" do
      Tracer.with_span "checkout" do
        O11y.record_exception(%RuntimeError{message: "something went wrong"})
      end

      span = assert_span("checkout")

      assert [event] = span.events
      assert event.name == "exception"
      assert %{"exception.message": "something went wrong"} = event.attributes
    end
  end

  describe "set_error" do
    test "sets the trace status to error" do
      Tracer.with_span "checkout" do
        O11y.set_error()
      end

      span = assert_span("checkout")
      assert span.status.code == :error
      assert span.status.message == ""
    end

    test "sets a message if given one" do
      Tracer.with_span "checkout" do
        O11y.set_error("something went wrong")
      end

      span = assert_span("checkout")
      assert span.status.code == :error
      assert span.status.message == "something went wrong"
    end

    test "sets a message to the exception message if given an exception" do
      Tracer.with_span "runtime error" do
        O11y.set_error(%RuntimeError{message: "something went wrong"})
      end

      span = assert_span("runtime error")
      assert span.status.code == :error
      assert span.status.message == "something went wrong"
    end

    defmodule Jason.DecodeError do
      defexception [:position, :token, :data]
      def message(_), do: "fancy error!"
    end

    test "handles exceptions with derived messages" do
      Tracer.with_span "jason error" do
        O11y.set_error(%Jason.DecodeError{position: 0, token: "asdasd", data: ""})
      end

      span = assert_span("jason error")
      assert span.status.code == :error
      assert span.status.message == "fancy error!"
    end

    test "inspects the value if given something other than a binary" do
      Tracer.with_span "checkout" do
        O11y.set_error([1, 2, 3])
      end

      span = assert_span("checkout")
      assert span.status.code == :error
      assert span.status.message == "[1, 2, 3]"
    end
  end

  describe "distributed_trace_ctx" do
    test "can attach trace context from disconnected remote trace" do
      ctx =
        Tracer.with_span "caller" do
          O11y.get_distributed_trace_ctx()
        end

      O11y.attach_distributed_trace_ctx(ctx)
      Tracer.with_span("callee", do: :ok)

      caller_span = assert_span("caller")
      callee_span = assert_span("callee")
      assert caller_span.trace_id == callee_span.trace_id
    end

    test "attach can take just the traceparent binary" do
      [{"traceparent", ctx}] = Tracer.with_span("caller", do: O11y.get_distributed_trace_ctx())

      O11y.attach_distributed_trace_ctx(ctx)
      Tracer.with_span("callee", do: :ok)

      caller_span = assert_span("caller")
      callee_span = assert_span("callee")
      assert caller_span.trace_id == callee_span.trace_id
    end
  end
end
