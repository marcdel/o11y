defmodule O11y.AttributeProcessor do
  @moduledoc """
  Functions for manipulating attribute names and values
  """
  import O11y.Attributes, only: [is_otlp_value: 1]

  alias O11y.SpanAttributes

  @attribute_namespace Application.compile_env(:o11y, :attribute_namespace)
  @filtered_attributes Application.compile_env(:o11y, :filtered_attributes, [])

  @doc """
  Turns structs and maps into lists of tuples and processes them recursively.
  """
  def process(attributes, opts \\ [])

  def process(attributes, opts) when is_list(attributes) do
    if attribute_list?(attributes) do
      process_attribute_list(attributes, opts)
    else
      attributes
    end
  end

  if Code.ensure_loaded?(Decimal) do
    def process(%Decimal{} = value, opts) do
      {key, opts} = Keyword.pop(opts, :prefix)
      process({key, Decimal.to_string(value)}, opts)
    end
  end

  def process(%Date{} = value, opts) do
    {key, opts} = Keyword.pop(opts, :prefix)
    process({key, Date.to_string(value)}, opts)
  end

  def process(%Time{} = value, opts) do
    {key, opts} = Keyword.pop(opts, :prefix)
    process({key, Time.to_string(value)}, opts)
  end

  def process(%NaiveDateTime{} = value, opts) do
    {key, opts} = Keyword.pop(opts, :prefix)
    process({key, NaiveDateTime.to_string(value)}, opts)
  end

  def process(%DateTime{} = value, opts) do
    {key, opts} = Keyword.pop(opts, :prefix)
    process({key, DateTime.to_string(value)}, opts)
  end

  def process(attributes, opts) when is_struct(attributes) or is_map(attributes) do
    attributes
    |> SpanAttributes.get()
    |> Enum.into([])
    |> process(opts)
  end

  def process({key, value}, opts) when is_otlp_value(value) do
    namespace = Keyword.get(opts, :namespace) || @attribute_namespace
    prefix = Keyword.get(opts, :prefix)

    key =
      key
      |> to_string()
      |> trim_leading()
      |> prefix(prefix)
      |> prefix(namespace)

    unless filtered_attribute?(key, opts) do
      {key, value}
    end
  end

  def process({key, value}, opts), do: process({key, inspect(value)}, opts)

  defp filtered_attribute?(key, opts) do
    filtered_attributes = filtered_attributes(opts)
    key = to_string(key)

    Enum.any?(filtered_attributes, fn filtered_attribute ->
      String.contains?(key, filtered_attribute)
    end)
  end

  defp filtered_attributes(opts) do
    filtered_attributes = Keyword.get(opts, :filtered_attributes) || @filtered_attributes
    Enum.map(filtered_attributes, &to_string/1)
  end

  defp prefix(name, prefix) when is_nil(prefix) or prefix == "" do
    name |> to_string() |> trim_leading()
  end

  defp prefix(name, prefix) do
    name = name |> to_string() |> trim_leading()
    prefix = prefix |> to_string() |> trim_leading()

    if String.starts_with?(name, prefix <> ".") do
      name
    else
      "#{prefix}.#{name}"
    end
  end

  defp trim_leading("_" <> name), do: name
  defp trim_leading(name), do: name

  defp attribute_list?(term) do
    Keyword.keyword?(term) or Enum.all?(term, &kv_tuple?/1)
  end

  defp kv_tuple?({key, _value}) when is_atom(key) or is_binary(key), do: true
  defp kv_tuple?(_term), do: false

  defp process_attribute_list(attributes, opts) do
    Enum.map(attributes, fn
      {k, v} when is_struct(v) or is_map(v) ->
        process(v, Keyword.put(opts, :prefix, k))

      {k, v} when is_list(v) ->
        if attribute_list?(v) do
          process_attribute_list(v, Keyword.put(opts, :prefix, k))
        else
          process({k, v}, opts)
        end

      {k, v} ->
        process({k, v}, opts)
    end)
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
  end
end
