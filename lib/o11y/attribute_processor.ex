defmodule O11y.AttributeProcessor do
  @moduledoc """
  Functions for manipulating attribute names and values
  """

  alias O11y.SpanAttributes

  @attribute_namespace Application.compile_env(:o11y, :attribute_namespace)

  @doc """
  Turns structs and maps into lists of tuples and processes them recursively.
  """
  def process(attributes, opts \\ [])

  def process(attributes, opts) when is_list(attributes) do
    if Keyword.keyword?(attributes) or Enum.all?(attributes, &is_tuple/1) do
      Enum.map(attributes, fn
        {k, v} when is_struct(v) or is_map(v) -> process(v, Keyword.put(opts, :prefix, k))
        {k, v} -> process({k, v}, opts)
      end)
      |> List.flatten()
    else
      attributes
    end
  end

  def process(attributes, opts) when is_struct(attributes) or is_map(attributes) do
    attributes
    |> SpanAttributes.get()
    |> Enum.into([])
    |> process(opts)
  end

  def process({key, value}, opts) do
    namespace = Keyword.get(opts, :namespace) || @attribute_namespace
    prefix = Keyword.get(opts, :prefix)

    key =
      key
      |> to_string()
      |> trim_leading()
      |> prefix(prefix)
      |> prefix(namespace)

    {key, value}
  end

  def prefix(name, prefix) when is_nil(prefix) or prefix == "" do
    name |> to_string() |> trim_leading()
  end

  def prefix(name, prefix) do
    name = name |> to_string() |> trim_leading()
    prefix = prefix |> to_string() |> trim_leading()

    if String.starts_with?(name, prefix <> ".") do
      name
    else
      "#{trim_leading(prefix)}.#{trim_leading(name)}"
    end
  end

  def trim_leading(name) when is_atom(name) do
    name |> to_string() |> trim_leading()
  end

  def trim_leading("_" <> name), do: name
  def trim_leading(name), do: name
end
