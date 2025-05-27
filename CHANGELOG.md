# O11y

## v0.2.12

- Removes `opentelemetry` as a runtime dependency.

## v0.2.11

- Adds `O11y.BaggageProcessor` module which, when configured as a span processor, will include any attributes added to the baggage to all spans created in that context.
- Adds `O11y.set_global_attribute/2` and `O11y.set_global_attributes/1` functions to add attributes to the baggage.
- Updates the credo, decimal, and ex_doc dependencies.
- Adds `opentelemetry` as a runtime dependency because the baggage processor needs to implement the `otel_span_processor` behavior which is defined by the SDK.
  - ⚠️This may mean that you need to override/remove your `opentelemetry` dependency if you're using a different version than the one that `o11y` is using. ⚠️

## v0.2.10

- Adds `filtered_attributes` configuration option to allow for filtering out attributes from spans. This is useful for removing sensitive data from spans before they are sent to a trace backend.

```elixir
config :o11y, :filtered_attributes, ["password", "secret", "token", "email"]
```

## v0.2.9

- Handle named keyword lists in `O11y.set_attributes/2` by prefixing the keys with the given name

```elixir
O11y.set_attributes(config: [key: "value"])
%{"config.key" => "value"}
```

## v0.2.8

- Update to opentelemetry 1.5.0, opentelemetry_api 1.4.0, and opentelemetry_exporter 1.8.0.
- Update various other dev dependencies.

## v0.2.7

- O11y.record_exception handles non-exceptions gracefully. It adds an error to the span and logs a warning.

## v0.2.6

- Handle date and time values in `O11y.set_attributes/2` and `O11y.set_attribute/2` by converting them to strings.
- Handle `Ecto` changesets in `O11y.set_attributes/2` and `O11y.set_attribute/2` by concatenating their errors and including other relevant attributes.

## v0.2.5

- Handles `Decimal` values in `O11y.set_attributes/2` and `O11y.set_attribute/2` by converting them to strings.

## v0.2.4

- `AttributeProcessor.process` now inspects non-otlp type attribute values. e.g. result tuples were being dropped by the exporter and should now be converted to strings.

## v0.2.3

- Adds `O11y.add_event/2` to add an event to the current span. Given attributes are treated like `O11y.set_attributes/2`.
- Document how `O11y.set_attributes/2` can be used in pipes.
- A ✌🏼 refactor ✌🏼 to move the attribute processing logic into the AttributeProcessor module to simplify the O11y module functions.
  - ⚠️ This actually led to an improvement(?) wherein calling `O11y.set_attribute/1` with a map/struct will cause those map/struct attributes to be prefixed with the given attribute name.
  - Previously these values would have been discarded. Now `O11y.set_attributes(%{key: "value"}, prefix: "my_prefix")` and `O11y.set_attribute("my_prefix", %{key: "value"})` are equivalent.

## v0.2.2

- Now handles attribute lists (lists of key/value tuples) in `O11y.set_attributes/2`.
- Adjusted the `is_otlp_value` guard to match the `attribute_value` type from `opentelemetry.erl`, minus `tuple()`. Tuple values are dropped by Honeycomb, and possibly other UIs, so we'll continue to `inspect` them for now.

## v0.2.1

- Now handles keyword lists in `O11y.set_attributes/2`.
- Adds rescues in set_attribute(s) functions to prevent crashes when given invalid data.

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
