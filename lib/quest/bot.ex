defmodule Quest.Bot do
  use Nostrum.Consumer
  import Quest.ParamHelper
  require Logger

  alias Nostrum.Api

  alias Quest.QuestManager
  alias Quest.PartyManager
  alias Quest.ServerManager

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def is_user_bot(user_id), do: %Nostrum.Struct.User{id: user_id}.bot()

  def handle_event({:MESSAGE_REACTION_ADD, m, _ws_state}) do
    if !is_user_bot(m.member.user.id) do
      PartyManager.handle_reaction_event(:create, m)
    end
  end

  def handle_event({:MESSAGE_REACTION_REMOVE, m, _ws_state}) do
    if !is_user_bot(m.user_id) do
      PartyManager.handle_reaction_event(:destroy, m)
    end
  end

  def handle_event({:MESSAGE_CREATE, msg, _ws_state}) do
    [entryCommand | subcommand_params] = msg.content
                            |> String.split(" ")
    case entryCommand do
      "!q" -> handle_subcommand(msg, subcommand_params)
      _ -> :ignore
    end
  end

  def handle_event(_) do
    :noop
  end

  def help_text(), do: "`!q init|config|quest|party`"

  def handle_subcommand(msg, subcommand_params) do
    [subcommand | params] = pad(subcommand_params, 2)
    Logger.info(subcommand)
    server_inited = ServerManager.get_server_by_id(msg.guild_id)
    response = case {server_inited, subcommand} do
      {nil, nil} -> help_text()
      {_, "init"} ->
        case ServerManager.init_server(msg.guild_id) do
          :ok -> "Server initialized successfully!"
          :exists -> "This Server has already been initialized with Quest."
          _ -> "An error occured, please check the bot console."
        end
      {nil, _command} -> "Please initialize the server before interfacing with Quest."
      {server, "config"} -> server |> ServerManager.handle_config_command(params)
      {server, "quest"} -> server |> QuestManager.handle_quest_command(params)
      {server, "party"} -> server |> PartyManager.handle_party_command(params)
      _ -> help_text()
    end
    Api.create_message(msg.channel_id, response)
  end
end
