defmodule Quest.Bot do
  use Nostrum.Consumer
  require Logger

  alias Nostrum.Api

  alias Quest.ServerManager
  alias Quest.QuestManager
  alias Quest.PartyManager

  def start_link() do
    Consumer.start_link(__MODULE__)
  end

  def is_user_bot(user_id), do: %Nostrum.Struct.User{id: user_id}.bot()

  def handle_event({:MESSAGE_REACTION_ADD, m, _ws_state}) do
    if !is_user_bot(m.member.user.id) do
      Logger.info(PartyManager.handle_reaction_event(:create, m))
    end
  end

  def handle_event({:MESSAGE_REACTION_REMOVE, m, _ws_state}) do
    if !is_user_bot(m.user_id) do
      Logger.info(PartyManager.handle_reaction_event(:destroy, m))
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

  def handle_subcommand(msg, subcommand_params) do
    {subcommand, params} = List.pop_at(subcommand_params, 0)
    Logger.info(subcommand)
    case subcommand do
      "init" ->
        response = case ServerManager.init_server(msg.guild_id) do
          :ok -> "Server initialized successfully!"
          :exists -> "This Server has already been initialized with Quest."
          _ -> "An error occured, please check the bot console."
        end
        Api.create_message(msg.channel_id, response)
      "config" -> ServerManager.handle_config_command(msg, params)
      "quest" -> QuestManager.handle_quest_command(msg, params)
      "party" -> PartyManager.handle_party_command(msg, params)
      _ -> Api.create_message(msg.channel_id, "`!q init|config|quest|party`")
    end
  end
end
