defmodule Quest.ParamHelper do
  def pad(list, to_length) when length(list) >= to_length, do: list
  def pad(list, to_length), do: pad(list ++ [nil], to_length)
end
