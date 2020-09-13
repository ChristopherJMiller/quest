defmodule Quest.PartyManager do
  import Ecto.Query
  import Quest.ParamHelper
  require Logger

  alias Quest.PostManager
  alias Quest.ServerManager
  alias Quest.PartyMember

  alias Quest.Repo
  alias Quest.Party

  alias Nostrum.Struct.Guild.Role
  alias Nostrum.Api

  def get_server_parties(server) do
    from(p in Party, where: p.server_id == ^server.server_id) |> Repo.all
  end

  def db_create_party(changeset) do
    Party.changeset(%Party{}, changeset)
      |> Repo.insert
  end

  def remove_role(server, user, role), do: Api.remove_guild_member_role(server, user, role)

  def get_all_party_members!(party_id), do: from(p in PartyMember, where: p.party_id == ^party_id) |> Repo.all
  def db_create_party_member(changeset) do
    PartyMember.changeset(%PartyMember{}, changeset)
      |> Repo.insert
  end

  def create_party(server_id, params) do
    [role_str] = params
    role = role_str |> String.slice(3..-2)
    server = Kernel.inspect(server_id)
    case ServerManager.get_server_by_id(server) do
      nil -> :error
      _ -> db_create_party(%{server_id: server, role_id: role})
    end
  end

  def id_to_role(id), do: %Nostrum.Struct.Guild.Role{id: id}
  def mention_party(party) when is_nil(party), do: ""
  def mention_party(party), do: party.role_id |> id_to_role |> Role.mention
  def format_party_item(party), do: "- " <> mention_party(party) <> ": ID `#{party.id}`\n"

  def list_parties(server) do
    get_server_parties(server) |> List.foldl("Party List:\n", fn x, acc -> acc <> format_party_item(x) end)
  end

  def delete_party_member(msg, quest, user_id) do
    server = msg.guild_id
    case Api.remove_guild_member_role(server, user_id, quest.party.role_id) do
      {:ok} -> case PartyMember |> Repo.get_by(%{user_id: user_id, party_id: quest.party.id}) |> Repo.delete do
        {:ok, _} -> :ok
        _ -> :error
      end
      _ -> :error
    end
  end

  def create_party_member(msg, quest, user_id) do
    server = msg.guild_id
    case Api.add_guild_member_role(server, user_id, quest.party.role_id) do
      {:ok} -> case db_create_party_member(%{server_id: server, user_id: user_id, party_id: quest.party.id}) do
        {:ok, _} -> :ok
        _ ->
          delete_party_member(msg, quest, user_id)
          :error
      end
      _ -> :error
    end
  end

  def handle_reaction_event(operation, msg) do
    post = PostManager.get_post_by_message_id(msg.message_id()) |> Repo.preload(:quest)
    quest = post.quest |> Repo.preload(:party)
    is_join_emoji = msg.emoji.name == PostManager.join_button()
    case {quest.status, operation, post, is_join_emoji} do
      {3, _, _, _} -> :ignore
      {_, _, nil, _} -> :ignore
      {_, :create, _post, true} -> create_party_member(msg, quest, msg.member.user.id)
      {_, :destroy, _post, true} -> delete_party_member(msg, quest, msg.user_id)
    end
  end

  def handle_party_command(server, params) do
    [field | result] = pad(params, 2)
    Logger.info(field)
    Logger.info(result)
    case field do
      "create" ->
        case create_party(server.server_id, result) do
          {:ok, party} -> "Created Party with ID `#{party.id}`"
          _ -> "An error occured, please check the bot console."
        end
      "list" -> list_parties(server)
      _ ->
        "`!q party <list|create>`"
    end
  end
end
