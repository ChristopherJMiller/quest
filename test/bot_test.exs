defmodule BotTest do
  use Quest.RepoCase
  doctest Quest.Bot

  import Mock
  import Quest.Mock

  alias Quest.Bot
  alias Quest.Server
  alias Quest.Repo

  describe "handle_event MESSAGE_CREATE" do
    mock_test("ignores non-command messages", [{Nostrum.Api, :working}]) do
      msg = as_message("not a command")
      assert Bot.handle_event({:MESSAGE_CREATE, msg, nil}) == :ignore
    end

    mock_test("respond to !q", [{Nostrum.Api, :working}]) do
      msg = as_message("!q", 5)
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      assert called Nostrum.Api.create_message(5, "`!q init|config|quest|party`")
    end
  end

  describe "!q init" do
    mock_test("successfully initializes the database", [{Nostrum.Api, :working}]) do
      msg = as_message("!q init", 5, 5)

      before_db = Server |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      after_db = Server |> Repo.aggregate(:count)

      assert called Nostrum.Api.create_message(5, "Server initialized successfully!")
      assert after_db - before_db == 1
    end

    mock_test("responds properly if the server already exists", [{Nostrum.Api, :working}]) do
      msg = as_message("!q init", 5, 5)

      before_db = Server |> Repo.aggregate(:count)
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      Bot.handle_event({:MESSAGE_CREATE, msg, nil})
      after_db = Server |> Repo.aggregate(:count)

      assert called Nostrum.Api.create_message(5, "Server initialized successfully!")
      assert called Nostrum.Api.create_message(5, "This Server has already been initialized with Quest.")
      assert after_db - before_db == 1
    end

    mock_test("responds gracefully when encountering an unknown error", [{Nostrum.Api, :working}, {Quest.ServerManager, :not_working}]) do
      msg = as_message("!q init", 5, 5)

      Bot.handle_event({:MESSAGE_CREATE, msg, nil})

      assert called Nostrum.Api.create_message(5, "An error occured, please check the bot console.")
    end
  end
end
