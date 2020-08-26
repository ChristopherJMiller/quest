defmodule Quest.ServerManager do
  require Logger

  alias Quest.Repo
  alias Quest.Server
  alias Nostrum.Api

  def get_server_by_id(nil), do: nil
  def get_server_by_id(id), do: Server |> Repo.get_by(server_id: id)

  defp create_server(server_id) do
    Server.changeset(%Server{}, %{server_id: server_id})
      |> Repo.insert
      |> Kernel.elem(0)
  end

  defp update_server(server, changeset) do
    Server.changeset(server, changeset)
      |> Repo.update
      |> Kernel.elem(0)
  end

  defp set_dm_role(nil, _), do: :error
  defp set_dm_role(server, params) do
    [role_str] = params
    role = role_str |> String.slice(3..-2)
    Logger.info(role_str)
    update_server(server, %{dm_role: role})
  end

  defp set_post_channel(nil, _), do: :error
  defp set_post_channel(server, params) do
    [channel_str] = params
    channel = channel_str |> String.slice(2..-2)
    Logger.info(channel_str)
    update_server(server, %{post_channel_id: channel})
  end

  def init_server(server_id) do
    case get_server_by_id(server_id) do
      nil -> create_server(server_id)
      _ -> :exists
    end
  end

  def handle_config_command(server, msg, params) do
    {field, sub_params} = List.pop_at(params, 0)
    Logger.info(field)
    response = case field do
      "dmrole" ->
        case set_dm_role(server, sub_params) do
          :ok -> "DM Role Configured"
          _ -> "An error occured, please check the bot console."
        end
      "postboard" ->
        case set_post_channel(server, sub_params) do
          :ok -> "Post Channel Configured"
          _ -> "An error occured, please check the bot console."
        end
      _ ->
        "`!q config <dmrole|postboard> <discord reference to role/channel>`"
    end
    Api.create_message(msg.channel_id, response)
  end
end
