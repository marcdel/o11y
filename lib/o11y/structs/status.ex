defmodule O11y.Status do
  @moduledoc false

  defstruct [:code, :message]

  def from_record(:undefined) do
    %__MODULE__{
      code: :undefined,
      message: ""
    }
  end

  def from_record({:status, code, message}) do
    %__MODULE__{
      code: code,
      message: message
    }
  end
end
