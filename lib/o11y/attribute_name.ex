defmodule O11y.AttributeName do
  @moduledoc """
  Functions for manipulating attribute names
  """

  def trim_leading(name) when is_atom(name) do
    name |> Atom.to_string() |> trim_leading()
  end

  def trim_leading("_" <> name), do: name
  def trim_leading(name), do: name
end
