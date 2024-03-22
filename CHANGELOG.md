# O11y

## v0.2.0

- ⚠️ Breaking Change ⚠️: The `O11y.set_attributes/2` function has changed. The first argument, `prefix` has moved into an options keyword list in order to accomodate the `namespace` option as well.

Before:
```elixir
O11y.set_attributes("my_prefix", %{key: "value"})
```

After:
```elixir
O11y.set_attributes(%{key: "value"}, prefix: "my_prefix")
```

- Attribute names that begin with an underscore now have the underscore removed before being added to the span. This allows you to add variables that are otherwise unused but have them be named normally in the span.

- Adds the ability to define a namespace to be prepended to attributes globally or on a per-attribute basis. This reduces the risk of attribute name collisions and helpfully keeps all of your custom attributes together in trace front ends.

- ⚠️ish change: Changes the behavior of `O11y.set_error/2` when given something other than a string or an exception struct. Previously it would log a warning and not set the error message. Now it will set the error message to the string representation of the given value.

## v0.1.4

- We now handle exceptions that do not define a `message` attribute on the struct e.g. `Jason.DecodeError` when calling `O11y.set_error`.

## v0.1.3

- We now log an error and do not attempt to set the error message if the message is not a string. Calling `Tracer.set_status` with anything else causes the span's status not to be updated correctly, and the error message to be lost anyway.
- Adds a `RecordDefinitions` module that you can `use` in order to have `span_ctx`, `span`, `link`, and `event` records available in your tests.
- Adds Elixir structs mathcing their OpenTelemetry counterparts for `Span`, `Link(s)`, and `Event(s)`, `Attributes`, and `Status`. These are used in tests, but are also available for use in your own code.
- Adds documentation and typespecs for the OpenTelemetry related structs. This was largely to cement my understanding, but should make it easier to understand what's going on when you're working with spans and traces as well.
- Updates to the latest versions of the `opentelemetry`, `opentelemetry_api`, and `opentelemetry_exporter` packages.

## v0.1.2

- Adds `O11y.start_span` and `O11y.end_span` helpers to wrap common behavior. The `start_span` function will immediately set the started span as current, and `end_span` will set the given parent back to the current. If you need to do fancy things (like starting a span and passing it to another process to use) you can fall back to `Tracer.start_span` and `Tracer.end_span` which have similar APIs.

```elixir
Tracer.with_span "checkout" do
 parent = O11y.start_span("calculate_tax")
 gnarly_calculations()
 O11y.end_span(parent)
end
```

## v0.1.1

- adds set_error helper functions

- handle distributed traces

- moves pid exporter setup into the using block of the test helper

  - this means that all users of the helper need to do is `use` it and all
    of the associated helper functions will work as expected. otherwise if
    you forget to add that setup you'll be left wondering why there are
    never any span messages in the mailbox.

- additional documentation

- adds expected_status and doctests for O11y

## v0.1.0

This first version just adds the set_attribute(s) functions and the ability to derive the SpanAttributes protocol for
your own structs.
