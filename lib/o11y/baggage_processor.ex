defmodule O11y.BaggageProcessor do
  @moduledoc """
  Adds any attributes stored in baggage in the current context to each span that is processed.

  ## Configuration

  In your project's config.exs (or runtime.exs or w/e):
  ```elixir
  config(:opentelemetry, :processors, [{O11y.BaggageProcessor, %{}}])
  ```

  If there's already a processor configured, you can add this one to the list:
  ```elixir
  config(:opentelemetry, :processors, [
    {O11y.BaggageProcessor, %{}},
    otel_batch_processor: %{exporter: {:opentelemetry_exporter, %{}}}
  ])
  ```

  ## Examples

  ```elixir
  iex> OpenTelemetry.Baggage.set("user_id", user.id)
  ...> # later in the request
  iex> Tracer.with_span "checkout" do
  ...>   # this span will include the user_id attribute automatically
  ...> end
  ```
  """

  @behaviour :otel_span_processor

  alias O11y.Span

  # what do we need to do with this?
  @type config :: any()

  @type span :: OpenTelemetry.span()
  @type ctx :: :otel_ctx.t()
  @type attrs :: OpenTelemetry.attributes_map()
  @type on_end_result :: true | :dropped | {:error, :invalid_span} | {:error, :no_export_buffer}

  @spec on_start(ctx(), span(), config()) :: span()
  def on_start(ctx, span, _config) do
    baggage_attributes =
      ctx
      |> OpenTelemetry.Baggage.get_all()
      |> Enum.map(fn {key, {value, _metadata}} -> {key, value} end)
      |> Enum.into(%{})

    add_attributes(span, baggage_attributes)
  rescue
    _ -> span
  end

  @spec on_end(span(), config()) :: on_end_result()
  def on_end(_span, _config), do: true

  @spec force_flush(config()) :: :ok | {:error, term()}
  def force_flush(_config), do: :ok

  @spec add_attributes(span(), attrs()) :: span()
  defp add_attributes(span_record, baggage_attributes) do
    span = Span.from_record(span_record)
    new_attributes = Map.merge(baggage_attributes, span.attributes)
    updated_span = Map.put(span, :attributes, new_attributes)
    Span.to_record(updated_span)
  end
end
