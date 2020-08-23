defmodule ServerTest do
  use Quest.RepoCase
  doctest Quest.ServerManager

  import Mock
  import Quest.Mock

  alias Quest.Bot
  alias Quest.Server
  alias Quest.ServerManager
  alias Quest.Repo

  describe "!q config integration" do
    mock_test("!q config with no subcommand displays help", [{Nostrum.Api, :working}]) do
      msg = as_message("!q config", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "`!q config <dmrole|postboard> <discord reference to role/channel>`")
    end

    mock_test("!q config dmrole sets a mentioned role to dm_role", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q config dmrole <@&1234>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      found_dm_role = Repo.get_by!(Server, server_id: "5").dm_role

      assert found_dm_role == "1234"
      assert called Nostrum.Api.create_message(5, "DM Role Configured")
    end

    mock_test("!q config postboard sets a mentioned channel to post_channel_id", [{Nostrum.Api, :working}]) do
      ServerManager.init_server(5)
      msg = as_message("!q config postboard <#1234>", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      found_channel = Repo.get_by!(Server, server_id: "5").post_channel_id

      assert found_channel == "1234"
      assert called Nostrum.Api.create_message(5, "Post Channel Configured")
    end
  end
end
