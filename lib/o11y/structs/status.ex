defmodule O11y.Status do
  @moduledoc """
  Struct version of the erlang record definition for the status record on a span.

  The record is defined here:
  https://github.com/open-telemetry/opentelemetry-erlang/blob/main/apps/opentelemetry_api/include/opentelemetry.hrl#L76
  """

  defstruct [:code, :message]

  @type t() :: %__MODULE__{
          code: :unset | :ok | :error,
          message: String.t()
        }

  @type status_record() :: {
          :status,
          code :: :unset | :ok | :error,
          message :: String.t()
        }

  @doc """
  Builds a status struct from the given record.

  ## Examples

  ```elixir
  iex> O11y.Status.from_record({:status, :error, "whoops!"})
  %O11y.Status{
    code: :error,
    message: "whoops!"
  }
  ```
  """
  @spec from_record(status_record()) :: t()
  def from_record(:undefined) do
    %__MODULE__{
      code: :unset,
      message: ""
    }
  end

  def from_record({:status, code, message}) do
    %__MODULE__{
      code: code,
      message: message
    }
  end

  def to_record(nil), do: :undefined

  def to_record(%__MODULE__{code: code, message: message}) do
    {:status, code, message}
  end
end
