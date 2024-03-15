defmodule O11y.Events do
  @moduledoc false

  alias O11y.Event

  def from_record(:undefined), do: []

  def from_record({:events, _, _, _, _, events}) do
    Enum.map(events, &Event.from_record/1)
  end
end
