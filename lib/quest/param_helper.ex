defmodule Quest.ParamHelper do
  def pad(list, to_length) when length(list) >= to_length, do: list
  def pad(list, to_length), do: pad(list ++ [nil], to_length)

  defp push_ignoring_nil(list, nil), do: list
  defp push_ignoring_nil(list, val), do: [val | list]
  def truncate(list), do: List.foldl(list, [], fn x, acc -> push_ignoring_nil(acc, x) end)
end
