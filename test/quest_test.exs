defmodule QuestTest do
  use ExUnit.Case
  doctest Quest

  test "greets the world" do
    assert Quest.hello() == :world
  end
end
