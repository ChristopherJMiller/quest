defmodule PostTest do
  use Quest.RepoCase, async: false
  doctest Quest.ServerManager

  import Mock
  import Quest.Mock

  alias Quest.Server
  alias Quest.ServerManager
  alias Quest.PartyManager
  alias Quest.QuestManager
  alias Quest.PostManager
  alias Quest.PartyMember
  alias Quest.Bot
  alias Quest.Repo
  alias Quest.Post
  alias Quest.Party
  alias Quest.Quest

  defp healthy_quest(server_id, party_id), do: %{
    server_id: server_id,
    party_id: party_id,
    title: "test",
    description: "test",
    location: "test",
    level: 0,
    item_loot: 0,
    coin_loot: 0,
    status: 0
  }

  defp unhealthy_quest(server_id, party_id), do: %{
    server_id: server_id,
    party_id: party_id,
    title: "test",
    description: "test",
    location: "test"
  }

  describe "Quest Posting" do
    mock_test("Successfully Posts if given Quest is Healthy", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!
      config = as_message("!q config postboard <#1234>", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})

      msg = as_message("!q quest post #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      after_db = Post |> Repo.aggregate(:count)

      assert after_db - before_db == 1
      assert called Nostrum.Api.create_message(1234, QuestManager.quest_block(quest))
      assert called Nostrum.Api.create_message(5, "Quest posted successfully")
      assert called Nostrum.Api.create_reaction(1234, msg.id(), PostManager.join_button())
    end

    mock_test("Cannot post if the Quest is Unhealthy", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, unhealthy_quest(5, party.id)) |> Repo.insert!
      {_, issues} = QuestManager.is_quest_healthy(quest)
      config = as_message("!q config postboard <#1234>", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})

      msg = as_message("!q quest post #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      after_db = Post |> Repo.aggregate(:count)

      assert after_db - before_db == 0
      assert called Nostrum.Api.create_message(5, "Failed to Post. The Quest has the following issues:" <> QuestManager.bullet_point(issues) <> "\nTo add these fields to your quest, use `!q quest edit <ID>`")
    end

    test "Can recover from a failed DB Insert" do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      before_db = Post |> Repo.aggregate(:count)
      Mock.with_mocks(
        [
          {Nostrum.Api, [], get_module_mocks(:working, Nostrum.Api)},
          {Repo, [:passthrough], get_module_mocks(:failed_insert, Repo)}
        ]
      ) do
        config = as_message("!q config postboard <#1234>", 5, 5)
        msg = as_message("!q quest post #{quest.id}", 5, 5)
        Bot.handle_event({:MESSAGE_CREATE, config, nil})
        Bot.handle_event({:MESSAGE_CREATE, msg, nil})
        after_db = Post |> Repo.aggregate(:count)
        assert after_db - before_db == 0
        assert called Nostrum.Api.create_message(5, "An error occured while saving the quest posting. Posting failed.")
      end
    end

    mock_test("Can recover from failed Reaction Adding", [{Nostrum.Api, :reactions_fail}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      msg = as_message("!q quest post #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      after_db = Post |> Repo.aggregate(:count)

      assert after_db - before_db == 0
      assert called Nostrum.Api.create_message(5, "Posting failed. Failed adding reactions.")
    end
  end

  describe "Posted Quest Modification" do
    mock_test("Can rescind posted quests", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      msg = as_message("!q quest post #{quest.id}", 5, 5)
      rescind = as_message("!q quest rescind #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      Bot.handle_event({:MESSAGE_CREATE, rescind, nil})
      after_db = Post |> Repo.aggregate(:count)

      assert after_db - before_db == 0
      assert called Nostrum.Api.create_message(5, "Successfully unpublished post")
    end

    mock_test("Can recover from a failed message delete", [{Nostrum.Api, :delete_fails}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      msg = as_message("!q quest post #{quest.id}", 5, 5)
      rescind = as_message("!q quest rescind #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      Bot.handle_event({:MESSAGE_CREATE, rescind, nil})
      after_db = Post |> Repo.aggregate(:count)

      assert after_db - before_db == 0
      assert called Nostrum.Api.create_message(5, "Attempted to clean post, ensure message is removed from post board.")
    end

    mock_test("Can set posted quest to inprogress", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      post = as_message("!q quest post #{quest.id}", 5, 5)
      progress = as_message("!q quest inprogress #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, post, nil})
      after_db = Post |> Repo.aggregate(:count)
      assert after_db - before_db == 1

      Bot.handle_event({:MESSAGE_CREATE, progress, nil})

      updated_quest = Quest |> Repo.get(quest.id)

      assert updated_quest.status == 1
      assert called Nostrum.Api.create_message(5, "Quest status and post updated.")
    end

    mock_test("Can set posted quest to attempted", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      post = as_message("!q quest post #{quest.id}", 5, 5)
      progress = as_message("!q quest attempted #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, post, nil})
      after_db = Post |> Repo.aggregate(:count)
      assert after_db - before_db == 1

      Bot.handle_event({:MESSAGE_CREATE, progress, nil})

      updated_quest = Quest |> Repo.get(quest.id)

      assert updated_quest.status == 2
      assert called Nostrum.Api.create_message(5, "Quest status and post updated.")
    end

    mock_test("Can set posted quest to completed", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 5678})
      {_status, _} = PartyManager.db_create_party_member(%{server_id: 5, party_id: party.id, user_id: 50})
      quest = Quest.changeset(%Quest{}, healthy_quest(5, party.id)) |> Repo.insert!

      config = as_message("!q config postboard <#1234>", 5, 5)
      post = as_message("!q quest post #{quest.id}", 5, 5)
      progress = as_message("!q quest complete #{quest.id}", 5, 5)

      before_db = Post |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, config, nil})
      Bot.handle_event({:MESSAGE_CREATE, post, nil})
      after_db = Post |> Repo.aggregate(:count)
      assert after_db - before_db == 1

      Bot.handle_event({:MESSAGE_CREATE, progress, nil})

      updated_quest = Quest |> Repo.get(quest.id)

      assert updated_quest.status == 3
      assert called Nostrum.Api.create_message(5, "Quest Completed")
    end
  end
end
