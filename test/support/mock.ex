defmodule Quest.Mock do
  import Mock

  # mock_list [{MODULE, :working}]
  defmacro mock_test(test_name, module_list, func) do
    quote do
      test unquote(test_name) do
        with_mocks(unquote(module_list) |> Enum.map(fn {module, state} -> {module, [], get_module_mocks(state, module)} end), unquote(func))
      end
    end
  end

  def as_message(content, channel_id \\ nil, server_id \\ nil), do: %Nostrum.Struct.Message{content: content, channel_id: channel_id, guild_id: server_id}

  @spec get_module_mocks(:working, Nostrum.Api | Nostrum.Consumer) :: [
          {:create_message, (any, any -> any)}
          | {:delete_message, (any, any -> any)}
          | {:start_link, (any -> any)},
          ...
        ]
  def get_module_mocks(:working, Nostrum.Api), do: [
    delete_message: fn(_s, _m) -> {:ok} end,
    create_message: fn(_c, m) -> {:ok, as_message(m)} end
  ]

  def get_module_mocks(:working, Nostrum.Consumer), do: [
    start_link: fn(_) -> :ignore end
  ]

  def get_module_mocks(:not_working, Quest.ServerManager), do: [
    init_server: fn(_) -> :error end
  ]

  def get_module_mocks(_, _), do: raise "Expected Defined State, Module Pair"
end
