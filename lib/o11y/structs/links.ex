defmodule O11y.Links do
  @moduledoc """
  Struct version of the erlang record definition for the links record on a span.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry/src/otel_links.erl#L27
  """

  alias O11y.Link

  @type t() :: list(Link.t())

  @type links_record() ::
          {
            :links,
            count_limit :: integer(),
            count_limit :: integer(),
            attribute_value_length_limit :: integer() | :infinity,
            dropped :: integer(),
            list :: list(Link.link_record())
          }
          | :undefined

  @doc """
  Builds a list of link structs from the given record.

  ## Examples

  ```elixir
  iex> O11y.Links.from_record({:links, 128, 128, :infinity, 0, [{:link, 128, 128, {:attributes, 128, :infinity, 0, %{key: "value"}}, []}]})
  [%O11y.Link{
    trace_id: 128,
    span_id: 128,
    attributes: %{key: "value"},
    tracestate: []
  }]
  ```
  """
  @spec from_record(links_record()) :: t()
  def from_record(:undefined), do: []

  def from_record({:links, _, _, _, _, links}) do
    Enum.map(links, &Link.from_record/1)
  end

  def to_record(nil), do: :undefined
  def to_record(links), do: {:links, 128, 128, :infinity, 0, Enum.map(links, &Link.to_record/1)}
end
