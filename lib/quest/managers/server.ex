defmodule Quest.ServerManager do
  require Logger

  alias Quest.Repo
  alias Quest.Server
  alias Nostrum.Api

  def server_exists(server_id), do: Server |> Repo.get_by(server_id: server_id)
  def get_server!(server_id), do: Server |> Repo.get_by!(server_id: server_id)

  def create_server(server_id) do
    Server.changeset(%Server{}, %{server_id: server_id})
      |> Repo.insert
      |> Kernel.elem(0)
  end

  def update_server(server, changeset) do
    Server.changeset(server, changeset)
      |> Repo.update
      |> Kernel.elem(0)
  end

  def init_server(server_id) do
    server = Kernel.inspect(server_id)
    case server_exists(server) do
      nil -> create_server(server)
      _ -> :exists
    end
  end

  def set_dm_role(server_id, params) do
    [role_str] = params
    role = role_str |> String.slice(3..-2)
    Logger.info(role_str)
    server = Kernel.inspect(server_id)
    case server_exists(server) do
      nil -> :error
      server_found -> update_server(server_found, %{dm_role: role})
    end
  end

  def set_post_channel(server_id, params) do
    [channel_str] = params
    channel = channel_str |> String.slice(2..-2)
    Logger.info(channel_str)
    server = Kernel.inspect(server_id)
    case server_exists(server) do
      nil -> :error
      server_found -> update_server(server_found, %{post_channel_id: channel})
    end
  end

  def handle_config_command(msg, params) do
    {field, result} = List.pop_at(params, 0)
    Logger.info(field)
    response = case field do
      "dmrole" ->
        case set_dm_role(msg.guild_id, result) do
          :ok -> "DM Role Configured"
          _ -> "An error occured, please check the bot console."
        end
      "postboard" ->
        case set_post_channel(msg.guild_id, result) do
          :ok -> "Post Channel Configured"
          _ -> "An error occured, please check the bot console."
        end
      _ ->
        "`!q config <dmrole|postboard> <discord reference to role/channel>`"
    end
    Api.create_message(msg.channel_id, response)
  end
end
