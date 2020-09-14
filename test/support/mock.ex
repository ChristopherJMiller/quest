defmodule Quest.Mock do
  import Mock

  alias Quest.Bot

  # mock_list [{MODULE, :working}]
  defmacro mock_test(test_name, module_list, func) do
    quote do
      test unquote(test_name) do
        with_mocks(unquote(module_list) |> Enum.map(fn {module, state} -> {module, [], get_module_mocks(state, module)} end), unquote(func))
      end
    end
  end

  def as_message(content, channel_id \\ nil, server_id \\ nil), do: %Nostrum.Struct.Message{id: 1, content: content, channel_id: channel_id, guild_id: server_id}
  def as_reaction_map(emoji, guild_id, channel_id, user_id), do: %{
    guild_id: guild_id,
    channel_id: channel_id,
    member: %{user: %{id: user_id}},
    user_id: user_id,
    emoji: %{name: emoji}
  }

  def bulk_call_msg([]), do: :done
  def bulk_call_msg([msg | rest]) do
    Bot.handle_event({:MESSAGE_CREATE, msg, nil})
    bulk_call_msg(rest)
  end

  def get_module_mocks(:working, Nostrum.Api), do: [
    delete_message: fn(_m) -> {:ok} end,
    delete_message: fn(_s, _m) -> {:ok} end,
    create_message: fn(c, m) -> {:ok, as_message(m, c)} end,
    edit_message: fn(_c, _p, m) -> {:ok, as_message(m)} end,
    create_reaction: fn(_c, _p, _r) -> {:ok} end,
    remove_guild_member_role: fn(_g, _u, _r) -> {:ok} end,
    add_guild_member_role: fn(_g, _u, _r) -> {:ok} end
  ]

  def get_module_mocks(:reactions_fail, Nostrum.Api), do: [
    delete_message: fn(_m) -> {:ok} end,
    delete_message: fn(_s, _m) -> {:ok} end,
    create_message: fn(c, m) -> {:ok, as_message(m, c)} end,
    edit_message: fn(_c, _p, m) -> {:ok, as_message(m)} end,
    create_reaction: fn(_c, _p, _r) -> {:error} end,
    remove_guild_member_role: fn(_g, _u, _r) -> {:ok} end,
    add_guild_member_role: fn(_g, _u, _r) -> {:ok} end
  ]

  def get_module_mocks(:delete_fails, Nostrum.Api), do: [
    delete_message: fn(_m) -> {:error} end,
    delete_message: fn(_s, _m) -> {:error} end,
    create_message: fn(c, m) -> {:ok, as_message(m, c)} end,
    edit_message: fn(_c, _p, m) -> {:ok, as_message(m)} end,
    create_reaction: fn(_c, _p, _r) -> {:ok} end,
    remove_guild_member_role: fn(_g, _u, _r) -> {:ok} end,
    add_guild_member_role: fn(_g, _u, _r) -> {:ok} end
  ]

  def get_module_mocks(:not_working, Nostrum.Api), do: [
    create_message: fn(_c, _m) -> :error end
  ]

  def get_module_mocks(:failed_insert, Quest.Repo), do: [
    insert: fn(_c) -> {:error, nil} end,
    delete: fn(_c) -> {:ok} end
  ]

  def get_module_mocks(:working, Nostrum.Consumer), do: [
    start_link: fn(_) -> :ignore end
  ]

  def get_module_mocks(:not_working, Quest.ServerManager), do: [
    init_server: fn(_) -> :error end,
    get_server_by_id: fn(_) -> nil end
  ]

  def get_module_mocks(_, _), do: raise "Expected Defined State, Module Pair"
end
