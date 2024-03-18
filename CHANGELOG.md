# O11y

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
