defmodule Quest.QuestManager do
  import Ecto.Query
  import Quest.ParamHelper

  require Logger

  alias Quest.PartyManager
  alias Quest.PostManager
  alias Quest.Post
  alias Quest.Repo
  alias Quest.Quest

  def init_quest(server) do
    Quest.changeset(%Quest{}, %{server_id: server.server_id, status: 0})
      |> Repo.insert
  end

  def get_quest_by_id(nil), do: :noID
  def get_quest_by_id(quest_id), do: Quest |> Repo.get_by(id: quest_id)

  def update_quest(quest, changeset) do
    Quest.changeset(quest, changeset)
      |> Repo.update
  end

  def list_valid_fields(), do: bullet_point(Quest.valid_fields)

  def list_valid_coin_levels(), do: bullet_point(["0: Low", "1: Moderate", "2: High", "3: Massive"])

  def list_valid_item_levels(), do: bullet_point(["0: Basic", "1: Wonderous", "2: Rare", "3: Epic", "4: Legendary"])

  def validCoinLevel(str), do: str in ["0", "1", "2", "3"]

  def validItemLevel(str), do: str in ["0", "1", "2", "3", "4"]

  def is_numeric(str) do
    case Integer.parse(str) do
      {_num, ""} -> true
      _ -> false
    end
  end

  def edit_help(), do: "The edit subcommand is used to change modify the fields within a quest, given a quest ID. All quest edits will have the format: `!q quest edit <ID> <field> <value>`. Fields include: \n" <>
                        "`title`: Title for the quest.\n" <>
                        "`description`: Describe to the players what this quest is about.\n" <>
                        "`location`: Where is the quest taking place?\n" <>
                        "`level`: What level should the players be for this quest? Values for this field must be integers.\n" <>
                        "`party_size`: What is the suggested party_size for this quest? Values for this field must be integers. \n" <>
                        "`coin_loot`: What is the expected coin loot for this quest? The provided value must be an integer within the range 0-3. Valid coin levels are " <> list_valid_coin_levels() <> "\n" <>
                        "`item_loot`: What is the highest expected rarity of items expected to be gained from this quest? The provided value must be an integer within the range 0-4. Valid item levels are " <> list_valid_item_levels() <> "\n" <>
                        "`party_id`: Which party should take on this quest. Try to pick one that is not currently being used. The value must be an integer that corresponds to a registered role. To see what parties are configured on your server, use `!q party list`"

  def handle_quest_edit(_, params) when length(params) == 0, do: "Please enter a valid field and value. Valid fields include: " <> list_valid_fields()
  def handle_quest_edit(_, params) when length(params) == 1 do
    [field] = params
    case field do
      "title" -> "No value given: Enter the title for this quest at the end of this command. Example: `!q quest edit 1 title My Quest`"
      "description" -> "No value given: Describe this quest at the end of this command. Example: `!q quest edit 1 description This is a DnD quest!`"
      "location" -> "No value given: Enter where this quest will take place at the end of this command. Example: `!q quest edit 1 location The Death Star`"
      "level" -> "No value given: Enter what level players should be when taking on this quest. Example: `!q quest edit 1 level 10`"
      "party_size" -> "No value given: Enter the suggested party size for this quest at the end of this command. Example: `!q quest edit 1 party_size 4`"
      "coin_loot" -> "No value given: Enter the level of potential coin loot for this quest at the end of this command. Example: `!q quest edit 1 coin_loot 3`. Accepted loot levels are " <> list_valid_coin_levels()
      "item_loot" -> "No value given: Enter the rarity of the potential items to gain from this quest at the end of this command. Example: `!q quest edit 1 item_loot 3`. Accepted item loot levels are " <> list_valid_item_levels()
      "party_id" -> "No value given: Enter an available party ID that is to take on this quest at the end of this command. Players will be able to obtain this role through the quest board. Example: `!q quest edit 1 party_id 1`"
      _ -> "The supplied field is invalid. Valid fields include:" <> list_valid_fields() <> "\nAfter the field, add a value to assign to that field. Example: `!q quest edit 1 title My Quest`"
    end
  end
  def handle_quest_edit(quest, params) do
    [field | value] = params
    final_value = List.foldl(value, "", fn x, acc -> acc <> " " <> x end)
                    |> String.slice(1..-1)
    field_atom = try do
      String.to_atom(field)
    rescue
      _ -> nil
    end

    case {field_atom, is_numeric(final_value), validCoinLevel(final_value), validItemLevel(final_value)} do
      {:level, false, _, _} -> "Quest edit failed: When entering the level for a quest, the value must be an integer. Example: `!q quest edit 1 level 10`"
      {:party_size, false, _, _} -> "Quest edit failed: When entering the party size for a quest, the value must be an integer. Example: `!q quest edit 1 party_size 4`"
      {:coin_loot, _, false, _} -> "Quest edit failed: Make sure the provided coin loot level is valid. Valid coin levels are: " <> list_valid_coin_levels()
      {:item_loot, _, _, false} -> "Quest edit failed: Make sure the provided item loot level is valid. Valid item levels are: " <> list_valid_item_levels()
      {:party_id, false, _, _} -> "Quest edit failed: When choosing the party for this quest, only enter the ID associated with that party's role. For instance, instead of entering `!q quest edit 1 party_id @Party 1`, you should enter `!q quest edit 1 party_id 1"
      _ -> 
        case Enum.member?(Quest.valid_fields, field_atom) do
          true -> case update_quest(quest, Map.put(%{}, field_atom, final_value)) do
              {:ok, new_quest} -> quest_block(new_quest)
              _ -> "An error occured when updating the Quest"
            end
          false -> "The supplied field is invalid. Valid fields include:" <> list_valid_fields()
        end
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


  defp get_party_mention(quest) do
    preloaded = Repo.preload quest, :party
    case preloaded.party do
      nil -> "No Party Set"
      party -> party |> PartyManager.mention_party
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
    > **Assigned to:** #{quest |> get_party_mention}
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

  def quest_status(quest, _params), do: quest_block(quest) <> "\n\n" <> display_quest_health(quest)

  def modify_quest_status(quest, status) do
    case update_quest(quest, %{status: status}) do
      {:ok, new_quest} -> PostManager.update_quest_post(new_quest)
      _ -> "An error occured when updating the Quest status"
    end
  end

  def clear_party_members([], _) do end
  def clear_party_members([party_member | rest], server) do
    PartyManager.remove_role(server, party_member.user_id, party_member.party_id)
    Repo.delete(party_member)
    clear_party_members(rest, server)
  end

  def complete_quest(quest, server) do
    modify_quest_status(quest, 3)
    quest.party.id
    |> PartyManager.get_all_party_members!
    |> clear_party_members(server.server_id)
    "Quest Completed"
  end

  def rescind_quest(quest, server) do
    quest.party.id
    |> PartyManager.get_all_party_members!
    |> clear_party_members(server.server_id)
    PostManager.remove_post(quest, server)
  end

  def helper_text(), do: "`!q quest <create|edit|status|post|help>`"

  def validCommand(str), do: str in ["edit", "status", "post", "rescind", "inprogress", "attempted", "complete"]

  def handle_quest_command(server, params) do
    [subcommand, quest_id | subcommand_params] = pad(params, 3)
    quest_exists = cond do
      (subcommand != "create" and (is_nil(quest_id) or is_numeric(quest_id))) or (subcommand == "create" and is_nil(quest_id)) -> 
        get_quest_by_id(quest_id)
      subcommand == "edit" and quest_id == "help" -> 
        :editHelp
      true -> :invalidID
    end
    case {quest_exists, subcommand} do
      # No integer in quest ID position
      # No params, helper
      {nil, nil} -> helper_text()

      # Commands that don't require an existing quest
      {_, "help"} -> "The quest command is used to create, edit, and manage quests. Subcommands include:\n" <>
                      "-`create`: This subcommand will create a new empty quest and provide you with its quest ID. No additional parameters are needed. Use: `!q quest create`.\n" <>
                      "-`edit`: Use this subcommand to edit the attributes of a quest, given a quest ID. Use: `!q quest edit <ID> <field> <value>`. Use `!q quest edit help` for more information.\n" <>
                      "-`status`: This subcommand will tell you whether a quest is ready to post or what needs to be changed before it is ready. Use `!q quest status <ID>`.\n" <>
                      "-`post`: This subcommand will post a completed quest to the configured postboard for the server. If the quest is not ready to be posted, a help response will be given. Use: `!q quest post <ID>`.\n" <>
                      "-`rescind`: This subcommand will remove a quest from the postboard. Use: `!q quest rescind <ID>`.\n" <>
                      "-`inprogress`: This subcommand will change the status of the given quest to \"In Progress\". Use: `!q quest inprogress <ID>`.\n" <>
                      "-`attempted`: If the party fails this quest, this subcommand will set the status of the quest to \"Attempted\". Players will be able to go back to this quest later. Use: `!q quest attempted <ID>`.\n" <>
                      "-`complete`: If the party completes a quest, this subcommand will set the status of the quest to \"Complete\". Use: `!q quest complete <ID>`.\n" <>
                      "-`help`: Displays this block of text."
      {:noID, "create"} ->
        case init_quest(server) do
          {:ok, quest} -> "Quest created. Reference with ID `#{quest.id}`"
          _ -> "An error occured, please check the bot console."
        end
      
      {:invalidID, "create"} -> "Invalid Parameters: Cannot create a quest given additional parameters. To create a new quest, run `!q quest create`"
      {:invalidID, _} -> "Invalid Parameters: The quest ID must be an integer. Example: `!q quest <edit|status|post> 1`"
      # = QUEST GUARD =
      {:noID, subcommand} -> 
        case validCommand(subcommand) do
          true -> "Invalid Parameters: Enter a quest ID after your command. Example: `!q quest <edit|status|post> 1`"
          false -> helper_text()
        end
      {nil, subcommand} -> 
        case validCommand(subcommand) do
          true -> "Invalid Parameters: Quest does not exist. Please specify a valid ID."
          false -> helper_text()
        end

      # Commands that require an existing quest
      {:editHelp, "edit"} -> edit_help()
      {quest, "edit"} -> quest |> handle_quest_edit(subcommand_params)
      {quest, "status"} -> quest |> quest_status(subcommand_params)
      {quest, "post"} -> quest |> PostManager.post_quest(server)
      {quest, "rescind"} -> quest |> Repo.preload([:party, :post]) |> rescind_quest(server)
      {quest, "inprogress"} -> quest |> Repo.preload([:server, :post]) |> modify_quest_status(1)
      {quest, "attempted"} -> quest |> Repo.preload([:server, :post]) |> modify_quest_status(2)
      {quest, "complete"} -> quest |> Repo.preload([:server, :post, :party]) |> complete_quest(server)

      # For Malformed entries
      _ -> helper_text()
    end
  end
end
