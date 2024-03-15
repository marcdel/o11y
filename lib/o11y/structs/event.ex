defmodule O11y.Event do
  @moduledoc false

  defstruct [:name, :native_time, :attributes]

  alias O11y.Attributes

  def from_record({:event, native_time, name, attributes}) do
    %__MODULE__{
      name: name,
      native_time: native_time,
      attributes: Attributes.from_record(attributes)
    }
  end
end
