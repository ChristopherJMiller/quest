defmodule PartyTest do
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
  alias Quest.Party
  alias Quest.Quest

  describe "!q party integration" do
    mock_test("!q party with no subcommand displays help", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q party", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "`!q party <list|create>`")
    end

    mock_test("!q party create <role> creates a new party using the given discord role", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q party create <@&1234>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      party = Repo.get_by!(Party, server_id: 5)
      stored_role_id = party.role_id
      party_id = party.id

      assert stored_role_id == 1234
      assert called Nostrum.Api.create_message(5, "Created Party with ID `#{party_id}`")
    end

    mock_test("!q party create <role> fails if server is not initialized", [{Nostrum.Api, :working}]) do
      msg = as_message("!q party create <@&1234>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Please initialize the server before interfacing with Quest.")
    end

    mock_test("!q party create <role> fails if the role is not valid", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)

      msg = as_message("!q party create <@&5678>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "Please utilize a valid role ID.")
    end

    mock_test("!q party list lists all avaliable parties", [{Nostrum.Api, :working}]) do
      Repo.delete_all(Party)

      ServerManager.init_server(5)
      party_one = as_message("!q party create <@&1234>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, party_one, nil})

      party_one_id = Repo.get_by!(Party, role_id: 1234).id

      test = as_message("!q party list", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Party List:\n- <@&1234>: ID `#{party_one_id}`\n")
    end
  end

  describe "Party Member Management" do
    mock_test("Adds a party member when they join a quest", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 1234})
      quest = Quest.changeset(%Quest{}, %{server_id: 5, party_id: party.id}) |> Repo.insert!
      {_status, post} = PostManager.create_post_db(33, 5, quest.id)

      msg = %{
        member: %{
          user: %{
            id: 1
          }
        },
        guild_id: 5,
        message_id: 33,
        emoji: %{
          name: PostManager.join_button()
        }
      }

      before_db = PartyMember |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_REACTION_ADD, msg, nil})
      after_db = PartyMember |> Repo.aggregate(:count)

      assert called Nostrum.Api.add_guild_member_role(5, 1, 1234)
      assert after_db - before_db == 1
    end

    mock_test("Removes a party member when they leave a quest", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      {_status, party} = PartyManager.db_create_party(%{server_id: 5, role_id: 1234})
      quest = Quest.changeset(%Quest{}, %{server_id: 5, party_id: party.id}) |> Repo.insert!
      {_status, post} = PostManager.create_post_db(33, 5, quest.id)
      {_status, party_member} = PartyManager.db_create_party_member(%{user_id: 1, party_id: party.id})

      msg = %{
        user_id: 1,
        guild_id: 5,
        message_id: 33,
        emoji: %{
          name: PostManager.join_button()
        }
      }

      before_db = PartyMember |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_REACTION_REMOVE, msg, nil})
      after_db = PartyMember |> Repo.aggregate(:count)

      assert called Nostrum.Api.remove_guild_member_role(5, 1, 1234)
      assert after_db - before_db == -1
    end
  end
end
