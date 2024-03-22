defmodule O11y.AttributeProcessor do
  @moduledoc """
  Functions for manipulating attribute names
  """

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
