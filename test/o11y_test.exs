defmodule O11yTest do
  use ExUnit.Case
  doctest O11y

  test "greets the world" do
    assert O11y.hello() == :world
  end
end
