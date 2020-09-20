defmodule QuestTest do
  use Quest.RepoCase, async: false
  doctest Quest.ServerManager

  import Mock
  import Quest.Mock

  alias Quest.Bot
  alias Quest.ServerManager
  alias Quest.QuestManager
  alias Quest.Repo
  alias Quest.Quest

  describe "!q quest integration" do
    mock_test("!q quest with no subcommand displays help", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, QuestManager.helper_text())
    end

    mock_test("!q quest create initializes a new quest to be edited", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id


      assert called Nostrum.Api.create_message(5, "Quest created. Reference with ID `#{quest}`")
    end

    mock_test("!q quest create displays a help message if additional parameters are provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create test", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Invalid Parameters: Cannot create a quest given additional parameters. To create a new quest, run `!q quest create`")
    end

    mock_test("!q quest edit properly edits an existing quest detail", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} title test", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      new_quest = Repo.get_by!(Quest, server_id: 5)

      assert new_quest.title == "test"

      assert called Nostrum.Api.create_message(5, QuestManager.quest_block(new_quest))
    end

    mock_test("!q quest edit with an invalid ID reports such to the user", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest edit 500", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Invalid Parameters: Quest does not exist. Please specify a valid ID.")
    end

    mock_test("!q quest <field> sends an error/help message if the supplied quest ID is not an integer", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest edit test", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Invalid Parameters: The quest ID must be an integer. Example: `!q quest <edit|status|post> 1`")
    end

    mock_test("!q quest displays helper text when an invalid subcommand is given", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest test", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "`!q quest <create|edit|status|post|help>`")
    end

    mock_test("!q quest <subcommand> (that isn't create) errors if no quest ID is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest edit", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Invalid Parameters: Enter a quest ID after your command. Example: `!q quest <edit|status|post> 1`")
    end

    mock_test("!q quest edit <ID> <field> returns a message if no value is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} title", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "No value given: Enter the title for this quest at the end of this command. Example: `!q quest edit 1 title My Quest`")
    end

    mock_test("!q quest edit <ID> returns a message if the field is invalid and no value is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} test", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "The supplied field is invalid. Valid fields include:" <> QuestManager.list_valid_fields() <> "\nAfter the field, add a value to assign to that field. Example: `!q quest edit 1 title My Quest`")
    end

    mock_test("!q quest edit <ID> level fails if a noninteger value is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} level test", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Quest edit failed: When entering the level for a quest, the value must be an integer. Example: `!q quest edit 1 level 10`")
    end

    mock_test("!q quest edit <ID> party_size fails if a noninteger value is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} party_size test", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Quest edit failed: When entering the party size for a quest, the value must be an integer. Example: `!q quest edit 1 party_size 4`")
    end

    mock_test("!q quest edit <ID> coin_loot fails if the provided value is not an integer within the accepted range", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} coin_loot 10", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Quest edit failed: Make sure the provided coin loot level is valid. Valid coin levels are: " <> QuestManager.list_valid_coin_levels())
    end

    mock_test("!q quest edit <ID> item_loot fails if the provided value is not an integer within the accepted range", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} item_loot 10", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Quest edit failed: Make sure the provided item loot level is valid. Valid item levels are: " <> QuestManager.list_valid_item_levels())
    end

    mock_test("!q quest edit <ID> party_id fails if the provided value is not an integer", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} party_id test", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Quest edit failed: When choosing the party for this quest, only enter the ID associated with that party's role. For instance, instead of entering `!q quest edit 1 party_id @Party 1`, you should enter `!q quest edit 1 party_id 1")
    end

    mock_test("!q quest edit <ID> fails if an incorrect field is given and a value is given", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest edit #{quest} test 10", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "The supplied field is invalid. Valid fields include:" <> QuestManager.list_valid_fields())
    end

    mock_test("!q quest status shows the current representation and problems with a quest", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id
      test = as_message("!q quest status #{quest}", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      new_quest = Repo.get_by!(Quest, server_id: 5)

      assert called Nostrum.Api.create_message(5, QuestManager.quest_block(new_quest) <> "\n\n" <> QuestManager.display_quest_health(new_quest))
    end

  end
end
