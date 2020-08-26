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
  end
end
