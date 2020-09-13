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

      assert called Nostrum.Api.create_message(5, "`!q quest <create|edit|status|post>`")
    end

    mock_test("!q quest create initializes a new quest to be edited", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      quest = Repo.get_by!(Quest, server_id: 5).id


      assert called Nostrum.Api.create_message(5, "Quest created. Reference with ID `#{quest}`")
    end

    mock_test("!q quest create displays a help message if a quest ID is provided", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q quest create test", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Cannot create a quest given additional parameters. To create a new quest, run `!q quest create`")
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

      assert called Nostrum.Api.create_message(5, "Quest does not exist. Please specify a valid ID.")
    end
  end
end
