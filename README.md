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
We include the `opentelemetry_api` package, but you'll need to add `opentelemetry` yourself in order to report spans and traces:

```elixir
def deps do
  [
    {:o11y, "~> 0.1.0"},
    {:opentelemetry, "~> 1.2"},
    {:opentelemetry_exporter, "~> 1.4"}
  ]
end
```

## Development

`make check` before you commit! If you'd prefer to do it manually:

* `mix do deps.get, deps.unlock --unused, deps.clean --unused` if you change dependencies
* `mix compile --warnings-as-errors` for a stricter compile
* `mix coveralls.html` to check for test coverage
* `mix credo` to suggest more idiomatic style for your code
* `mix dialyzer` to find problems typing might reveal… albeit *slowly*
* `mix docs` to generate documentation

