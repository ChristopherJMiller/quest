defmodule Quest.PostManager do
  require Logger

  alias Quest.Repo
  alias Quest.Post

  alias Quest.ServerManager
  alias Quest.QuestManager

  alias Nostrum.Api
  alias Nostrum.Snowflake

  def join_button(), do: "⏩"

  def get_post_by_message_id(message_id), do: Post |> Repo.get_by(post_id: message_id)
  def delete_post(post), do: Repo.delete(post)

  def quest_published(quest_id) do
    Post |> Repo.get_by(quest_id: quest_id)
  end

  def create_post_db(post_id, server_id, quest_id) do
    Post.changeset(%Post{}, %{server_id: server_id, quest_id: quest_id, post_id: Kernel.inspect(post_id)})
      |> Repo.insert
  end

  def remove_post(server_id, params) do
    {quest_id, _rest} = List.pop_at(params, 0)
    case quest_published(quest_id) do
      nil -> "Quest Not Posted"
      post -> case Api.delete_message(Snowflake.cast!(ServerManager.get_server!(server_id).post_channel_id), Snowflake.cast!(post.post_id)) do
        {:ok} -> case delete_post(post) do
          {:ok, _} -> "Successfully unpublished post"
          nil -> "An unexpected error occured when trying to remove the post from the DB."
        end
        _ -> case clean_post(nil, post.id) do
          _ -> "Attempted to clean post, ensure message is removed from post board."
        end
      end
    end
  end

  def update_quest_post(quest) do
    case quest_published(quest.id) do
      nil -> "Quest status updated"
      post -> case Api.edit_message(Snowflake.cast!(ServerManager.get_server!(post.server_id).post_channel_id), Snowflake.cast!(post.post_id), QuestManager.quest_block(quest)) do
        {:ok, _msg} -> "Quest status and post updated."
        _ -> "An error occured when modifying the posting. Quest status still updated." 
      end
    end
  end

  def prepare_enlist_reactions(msg) do
    Nostrum.Api.create_reaction(msg.channel_id(), msg.id(), join_button())
  end

  def clean_post(msg, known_post_id) do
    try do
      case Post |> Repo.get(known_post_id) do
        post -> Repo.delete(post)
      end
      Api.delete_message(msg)
      :ok
    catch
      _ -> :error
    end
  end

  def make_post(server, quest, channel_id) do
    case Api.create_message(Snowflake.cast!(channel_id), QuestManager.quest_block(quest)) do
      {:ok, msg} -> case create_post_db(msg.id, server.server_id, quest.id) do
        {:ok, post} -> case prepare_enlist_reactions(msg) do
          {:ok} -> "Quest posted successfully"
          _ -> case clean_post(msg, post.id) do
            :ok -> "An error occured while saving the quest posting. Posting failed. (Failed on Reaction Adding)"
            :error -> "An error occured and could not recover"
          end
        end
        _ -> case clean_post(msg, nil) do
          {:ok} -> "An error occured while saving the quest posting. Posting failed."
          _ -> "An error occured and was unable to recover."
        end
      end
      _ -> "Failed to post, an error has occured while posting."
    end
  end

  def post_quest(server_id, params) do
    {quest_id, _rest} = List.pop_at(params, 0)
    case quest_published(quest_id) do
      nil -> case ServerManager.server_exists(server_id) do
        nil -> "Server has not been Initialized"
        server -> case QuestManager.quest_exists(quest_id) do
          nil -> "Invalid Quest ID"
          quest -> case QuestManager.is_quest_healthy(quest) do
            {:unhealthy, issues} -> "Failed to Post. The Quest has the following issues:" <> QuestManager.bullet_point(issues)
            {:healthy, _} -> case server.post_channel_id do
              nil -> "Server Post Channel not configured"
              channel_id -> make_post(server, quest, channel_id)
            end
          end
        end
      end
      _ -> "Quest is already posted."
    end
  end
end