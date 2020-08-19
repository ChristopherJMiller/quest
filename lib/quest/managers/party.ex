defmodule Quest.PartyManager do
  import Ecto.Query
  require Logger

  alias Quest.PostManager
  alias Quest.QuestManager
  alias Quest.ServerManager
  alias Quest.PartyMember

  alias Quest.Repo
  alias Quest.Party

  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Api
  alias Nostrum.Snowflake

  def get_role_id_by_quest!(quest_id), do: Party |> Repo.get!(QuestManager.get_quest!(quest_id).party_id)

  def get_server_parties(server_id) do
    from(p in Party, where: p.server_id == ^server_id) |> Repo.all
  end

  def db_create_party(changeset) do
    Party.changeset(%Party{}, changeset)
      |> Repo.insert
  end

  def remove_role(server, user, role), do: Api.remove_guild_member_role(server, user, role)

  def get_all_party_members!(role_id), do: from(p in PartyMember, where: p.role_id == ^role_id) |> Repo.all
  def get_party_member!(role_id, user_id), do: PartyMember |> Repo.get_by!(%{role_id: role_id, user_id: user_id})
  def db_destroy_party_member(party_member), do: Repo.delete(party_member)
  def db_create_party_member(changeset) do
    PartyMember.changeset(%PartyMember{}, changeset)
      |> Repo.insert
  end

  def create_party(server_id, params) do
    [role_str] = params
    role = role_str |> String.slice(3..-2)
    server = Kernel.inspect(server_id)
    case ServerManager.server_exists(server) do
      nil -> :error
      _ -> db_create_party(%{server_id: server, role_id: role})
    end
  end

  def id_to_role(id), do: %Nostrum.Struct.Guild.Role{id: id}
  def mention_party(party), do: Role.mention(id_to_role(Snowflake.cast!(party.role_id)))
  def format_party_item(party), do: "- " <> mention_party(party) <> ": ID `#{party.id}`\n"

  def list_parties(server_id) do
    get_server_parties(server_id) |> List.foldl("Party List:\n", fn x, acc -> acc <> format_party_item(x) end)
  end

  def handle_reaction_event(operation, msg) do
    quest_post = PostManager.get_post_by_message_id(Kernel.inspect(msg.message_id()))
    quest = QuestManager.get_quest!(quest_post.quest_id)
    server = Kernel.inspect(msg.guild_id())
    is_join_emoji = msg.emoji.name == PostManager.join_button()
    case {quest.status, operation, quest_post, is_join_emoji} do
      {3, _, _, _} -> :ignore
      {_, _, nil, _} -> :ignore
      {_, :create, post, true} -> case Api.add_guild_member_role(msg.guild_id(), msg.member.user.id(), get_role_id_by_quest!(post.quest_id).role_id |> Snowflake.cast!) do
        {:ok} -> case db_create_party_member(%{server_id: server, user_id: Kernel.inspect(msg.member.user.id()), role_id: get_role_id_by_quest!(post.quest_id).role_id}) do
          {:ok, _} -> :ok
          _ -> case Api.remove_guild_member_role(msg.guild_id, msg.user_id, get_role_id_by_quest!(post.quest_id).role_id |> Snowflake.cast!) do
            {:ok} -> :ok
            _ -> :error
          end
        end
        _ -> :error
      end
      {_, :destroy, post, true} -> case Api.remove_guild_member_role(msg.guild_id, msg.user_id, get_role_id_by_quest!(post.quest_id).role_id |> Snowflake.cast!) do
        {:ok} -> case get_role_id_by_quest!(post.quest_id).role_id |> get_party_member!(Kernel.inspect(msg.user_id)) |> db_destroy_party_member do
          {:ok, _} -> :ok
          _ -> :error
        end
        _ -> :error
      end
    end
  end

  def handle_party_command(msg, params) do
    {field, result} = List.pop_at(params, 0)
    server = Kernel.inspect(msg.guild_id)
    Logger.info(field)
    response = case field do
      "create" -> 
        case create_party(msg.guild_id, result) do
          {:ok, party} -> "Created Party with ID `#{party.id}`"
          _ -> "An error occured, please check the bot console."
        end
      "list" -> list_parties(server)
      _ ->
        "`!q party <list|create>`"
    end
    Api.create_message(msg.channel_id, response)
  end
end