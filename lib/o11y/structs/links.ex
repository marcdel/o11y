defmodule O11y.Links do
  @moduledoc false

  alias O11y.Link

  def from_record(:undefined), do: []

  def from_record({:links, _, _, _, _, events}) do
    Enum.map(events, &Link.from_record/1)
  end
end
