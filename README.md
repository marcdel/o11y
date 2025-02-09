<h1>
  <img src="o11y.png" alt="O11y Logo" width="50" style="vertical-align: middle;" />
  <span style="vertical-align: middle;">O11y</span>
</h1>


[![Build status badge](https://github.com/marcdel/o11y/workflows/CI/badge.svg)](https://github.com/marcdel/o11y/actions)
[![Hex.pm version badge](https://img.shields.io/hexpm/v/o11y.svg)](https://hex.pm/packages/o11y)
[![Hex.pm downloads badge](https://img.shields.io/hexpm/dt/o11y.svg)](https://hex.pm/packages/o11y)

Convenience functions and other things to (hopefully) make your life easier when working with OpenTelemetry in Elixir.

## Installation

Add `o11y` to your list of dependencies in `mix.exs`.
We include the `opentelemetry_api` package, but you'll need to add `opentelemetry`, and `opentelemetry_exporter` yourself in order to report spans and traces:

```elixir
def deps do
  [
    {:o11y, "~> 0.2"},
    {:opentelemetry, "~> 1.5"},
    {:opentelemetry_exporter, "~> 1.8"}
  ]
end
```

💡 Note: if you use [open_telemetry_decorator](https://github.com/marcdel/open_telemetry_decorator), `o11y` will already be included as a transitive dependency.

Then follow the directions for the exporter of your choice to send traces to [zipkin](https://github.com/open-telemetry/opentelemetry-erlang/tree/main/apps/opentelemetry_zipkin), [honeycomb](https://www.honeycomb.io/), etc.

### Honeycomb Example

`config/runtime.exs`
```elixir
api_key = System.fetch_env!("HONEYCOMB_KEY")

config :opentelemetry_exporter,
  otlp_endpoint: "https://api.honeycomb.io:443",
  otlp_headers: [{"x-honeycomb-team", api_key}]
```

## Usage

The [docs](https://hexdocs.pm/o11y/O11y.html) are a great place to start, but below are examples of the most common use cases.

### Basic Example

In this example we use `Trace.with_span/2` to create a span named "worker.do_work" and then use the two set_attribute(s) functions to... set attributes on it.

```elixir
defmodule MyApp.Worker do
  require OpenTelemetry.Tracer, as: Tracer

  def do_work(arg1, arg2) do
    Tracer.with_span "Worker.do_work" do
      O11y.set_attributes(%{arg1: arg1, arg2: arg2})
      # ...doing work
      O11y.set_attribute(:result, "something")
    end
  end
end
```

📝 Note that, where possible, the functions in `O11y` return the value they're given so they can be used in pipelines.

```elixir
%User{email: "alice@aol.com", password: "hunter2"}
|> O11y.set_attributes(prefix: :user)
|> login_user()
|> O11y.set_attributes(prefix: :logged_in_user)
```

### Exception Handling

In this example we use `O11y.record_exception/2`, which does a number of things:
- Sets the span's `status_code` to `ERROR`
- Sets the span's `status_message` to the exception's message
- Adds `exception.message` and `exception.stack_trace` attributes
- Adds a separate `exception` span event

Note that we're only rescuing in order to record the exception, so we also reraise with the original stacktrace.

```elixir
try do
  # ...doing work
rescue
  e ->
    O11y.record_exception(e)
    reraise e, __STACKTRACE__
end
```

### Error Handling

You may want to indicate that an error occurred in a span in cases where an exception is not raised. For this we'll use `O11y.set_error/1`, which will set the `status_code` and `status_message` attributes.

```elixir
case do_some_work() do
  {:ok, _} -> :ok
  error -> O11y.set_error(error)
end
```

### Events

Events are essentially structured log lines that can be associated to a span. They can be used as checkpoints during the span's lifetime, or to indicate that something notable happened (or failed to happen). Attributes given in the second argument are processed in the same way as attributes given to `O11y.set_attribute(s)`.

```elixir
O11y.add_event("Something happened", %{some: "context", what: "happened"})
```

### Baggage

Baggage is a way to pass data between spans in a trace. You can add attributes to the baggage using `O11y.set_global_attribute` and `O11y.set_global_attributes`.
The `O11y.BaggageProcessor` module will include any attributes added to the baggage to all spans created in that context.

```elixir
config(:opentelemetry, :processors, [{O11y.BaggageProcessor, %{}}])
```

```elixir
O11y.set_global_attribute(:user_id, 123)
```

## Configuration

### Attribute Namespace
You can set a global attribute namespace, which will prefix all attributes added to spans with the given value. This reduces the risk of attribute name collisions and helpfully keeps all of your custom attributes together in trace front ends.

```elixir
config :o11y, :attribute_namespace, "app"
```

```elixir
O11y.set_attributes(%{key: "value"})
%{"app.key" => "value"}
```

### Filtered Attributes
You can set a global list of attribute names that should be filtered out (names can be strings or atoms). Any attributes whose name contains one of the values in this list will be removed from the span. 

```elixir
config :o11y, :filtered_attributes, ["secret", "token", :password, "email"]
```

## Development

`make check` before you commit! If you'd prefer to do it manually:

* `mix do deps.get, deps.unlock --unused, deps.clean --unused` if you change dependencies
* `mix compile --warnings-as-errors` for a stricter compile
* `mix coveralls.html` to check for test coverage
* `mix credo` to suggest more idiomatic style for your code
* `mix dialyzer` to find problems typing might reveal… albeit *slowly*
* `mix docs` to generate documentation
