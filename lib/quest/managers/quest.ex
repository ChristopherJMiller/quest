defmodule Quest.QuestManager do
  import Ecto.Query

  require Logger

  alias Quest.PartyManager
  alias Quest.PostManager
  alias Quest.Post
  alias Quest.Repo
  alias Quest.Quest

  alias Nostrum.Api
  alias Nostrum.Snowflake


  def init_quest(server_id) do
    Quest.changeset(%Quest{}, %{server_id: server_id, status: 0})
      |> Repo.insert
  end

  def get_quest!(quest_id), do: Quest |> Repo.get!(quest_id)
  def quest_exists(quest_id), do: Quest |> Repo.get_by(id: quest_id)

  def update_quest(quest, changeset) do
    Quest.changeset(quest, changeset)
      |> Repo.update
  end

  def list_valid_fields(), do: bullet_point(Quest.valid_fields)

  def handle_quest_edit(params) do
    {quest_id, result} = List.pop_at(params, 0)
    {field, value} = List.pop_at(result, 0)
    final_value = List.foldl(value, "", fn x, acc -> acc <> " " <> x end)
                    |> String.slice(1..-1)
    field_atom = try do
      String.to_atom(field)
    rescue
      _ -> nil
    end

    case Enum.member?(Quest.valid_fields, field_atom) do
      true -> case quest_exists(quest_id) do
        nil -> "Invalid Quest ID"
        quest -> case update_quest(quest, Map.put(%{}, field_atom, final_value)) do
          {:ok, new_quest} -> quest_block(new_quest)
          _ -> "An error occured when updating the Quest"
        end
      end
      false -> "Valid Fields:" <> list_valid_fields()
    end
  end

  def coin_loot_descriptor(loot_index) do
    case loot_index do
      0 -> "Low"
      1 -> "Moderate"
      2 -> "High"
      3 -> "Massive"
      _ -> "Invalid"
    end
  end

  def item_descriptor(loot_index) do
    case loot_index do
      0 -> "Basic"
      1 -> "Wonderous"
      2 -> "Rare"
      3 -> "Epic"
      4 -> "Legendary"
      _ -> "Invalid"
    end
  end

  def status_descriptor(status) do
    case status do
      0 -> "Not Attempted"
      1 -> "In Progress"
      2 -> "Attempted"
      3 -> "Completed"
      _ -> "Invalid"
    end
  end

  def quest_block(quest) do
    "> ```css
    > #{quest.title}
    > ```
    > *#{quest.description}*
    > **Location:** #{quest.location}
    > **Expected Level:** #{quest.level}
    > **Expected Party Size:** #{quest.party_size}
    > **Coin Gain:** #{quest.coin_loot |> coin_loot_descriptor}
    > **Potential Item Gain:** #{quest.item_loot |> item_descriptor}
    > **Assigned to:** #{PartyManager.get_role_id_by_quest!(quest.id) |> PartyManager.mention_party}
    > **Status:** #{quest.status |> status_descriptor}"
  end

  def quest_health_check(status_map, check, issue_text) do
    case check do
      true -> status_map
      false -> {:unhealthy, [issue_text | Kernel.elem(status_map, 1)]}
    end
  end

  def quest_party_conflict(_, party_id) when is_nil(party_id), do: false
  def quest_party_conflict(server_id, party_id) do
    posted_quests = from(p in Post, where: p.server_id == ^server_id) |> Repo.all |> Enum.map(fn x -> x.quest_id end)
    full_quests = from(q in Quest, where: q.id in ^posted_quests) |> Repo.all
    full_quests |> Enum.map(fn x -> x.party_id == party_id end) |> Enum.member?(true)
  end

  def is_quest_healthy(quest) do
    {:healthy, []}
      |> quest_health_check(!is_nil(quest.title), "Title cannot be empty")
      |> quest_health_check(!is_nil(quest.description), "Description cannot be empty")
      |> quest_health_check(!is_nil(quest.location), "Location cannot be empty")
      |> quest_health_check(!is_nil(quest.level), "Level cannot be empty")
      |> quest_health_check(!is_nil(quest.item_loot), "Item Loot cannot be empty")
      |> quest_health_check(!is_nil(quest.coin_loot), "Coin Loot cannot be empty")
      |> quest_health_check(!is_nil(quest.party_id), "Party ID cannot be empty")
      |> quest_health_check(!quest_party_conflict(quest.server_id, quest.party_id), "Cannot post two quests with the same Party ID")
  end

  def bullet_point(list), do: List.foldl(list, "", fn x, acc -> acc <> "\n" <> "- #{x}" end)

  def display_quest_health(quest) do
    case is_quest_healthy(quest) do
      {:healthy, _} -> "Quest is ready for posting!"
      {:unhealthy, issues} -> "The Quest has the following issues:" <> bullet_point(issues)
    end
  end

  def quest_status(params) do
    {quest_id, _result} = List.pop_at(params, 0)
    case quest_exists(quest_id) do
      nil -> "Invalid Quest ID"
      quest -> quest_block(quest) <> "\n\n" <> display_quest_health(quest)
    end
  end

  def modify_quest_status(params, status) do
    {quest_id, _result} = List.pop_at(params, 0)
    case quest_exists(quest_id) do
      nil -> "Invalid Quest ID"
      quest -> case update_quest(quest, %{status: status}) do
        {:ok, new_quest} -> PostManager.update_quest_post(new_quest)
        _ -> "An error occured when updating the Quest status"
      end
    end
  end

  def clear_party_members([], _) do end
  def clear_party_members([party_member | rest], server) do
    PartyManager.remove_role(server |> Snowflake.cast!, party_member.user_id |> Snowflake.cast!, party_member.role_id |> Snowflake.cast!)
    PartyManager.db_destroy_party_member(party_member)
    clear_party_members(rest, server)
  end

  def complete_quest(server_id, params) do
    {quest_id, _result} = List.pop_at(params, 0)
    case quest_exists(quest_id) do
      nil -> "Invalid Quest ID"
      quest ->
        modify_quest_status([quest_id], 3)
        PartyManager.get_role_id_by_quest!(quest.id).role_id
        |> PartyManager.get_all_party_members!
        |> clear_party_members(server_id)
        "Quest Completed"
    end
  end

  def handle_quest_command(msg, params) do
    {field, result} = List.pop_at(params, 0)
    server = Kernel.inspect(msg.guild_id)
    response = case field do
      "create" -> 
        case init_quest(server) do
          {:ok, quest} -> "Quest created. Reference with ID `#{quest.id}`"
          _ -> "An error occured, please check the bot console."
        end
      "edit" -> handle_quest_edit(result)
      "status" -> quest_status(result)
      "post" -> PostManager.post_quest(server, result)
      "rescind" -> PostManager.remove_post(server, result)
      "inprogress" -> modify_quest_status(result, 1)
      "attempted" -> modify_quest_status(result, 2)
      "complete" -> complete_quest(server, result)
      _ ->
        "`!q quest <create|edit|status|post>`"
    end
    Api.create_message(msg.channel_id, response)
  end
end