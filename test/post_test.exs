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
  end
end
