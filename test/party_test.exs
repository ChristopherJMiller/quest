defmodule PartyTest do
  use Quest.RepoCase, async: false
  doctest Quest.ServerManager

  import Mock
  import Quest.Mock

  alias Quest.Server
  alias Quest.ServerManager
  alias Quest.Bot
  alias Quest.Repo
  alias Quest.Party

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

    mock_test("!q party list lists all avaliable parties", [{Nostrum.Api, :working}]) do
      Repo.delete_all(Party)

      ServerManager.init_server(5)
      party_one = as_message("!q party create <@&1234>", 5, 5)
      party_two = as_message("!q party create <@&5678>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, party_one, nil})
      Bot.handle_event({:MESSAGE_CREATE, party_two, nil})

      party_one_id = Repo.get_by!(Party, role_id: 1234).id
      party_two_id = Repo.get_by!(Party, role_id: 5678).id

      test = as_message("!q party list", 5, 5)
      Bot.handle_event({:MESSAGE_CREATE, test, nil})

      assert called Nostrum.Api.create_message(5, "Party List:\n- <@&1234>: ID `#{party_one_id}`\n- <@&5678>: ID `#{party_two_id}`\n")
    end
  end
end
