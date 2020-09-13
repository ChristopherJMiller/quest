defmodule Quest.PostManager do
  require Logger

  alias Quest.Repo
  alias Quest.Post

  alias Quest.QuestManager

  alias Nostrum.Api

  def join_button(), do: "⏩"

  def get_post_by_message_id(message_id), do: Post |> Repo.get_by(post_id: message_id)
  def delete_post(post), do: Repo.delete(post)

  def quest_published(quest) do
    Repo.preload(quest, :post).post
  end

  def create_post_db(post_id, server_id, quest_id) do
    Post.changeset(%Post{}, %{server_id: server_id, quest_id: quest_id, post_id: post_id})
      |> Repo.insert
  end

  def remove_post(quest, server) do
    case Api.delete_message(server.post_channel_id, quest.post.post_id) do
      {:ok} -> case delete_post(quest.post) do
        {:ok, _} -> "Successfully unpublished post"
        nil -> "An unexpected error occured when trying to remove the post from the DB."
      end
      _ -> case clean_post(quest.post, nil) do
        _ -> "Attempted to clean post, ensure message is removed from post board."
      end
    end
  end

  def update_quest_post(quest) do
    case quest_published(quest) do
      nil -> "Quest status updated"
      post ->
      updated_post = post |> Repo.preload(:server)
      case Api.edit_message(updated_post.server.post_channel_id, post.post_id, QuestManager.quest_block(quest)) do
        {:ok, _msg} -> "Quest status and post updated."
        _ -> "An error occured when modifying the posting. Quest status still updated."
      end
    end
  end

  def prepare_enlist_reactions(msg) do
    Nostrum.Api.create_reaction(msg.channel_id(), msg.id(), join_button())
  end

  def clean_post(nil), do: {:error}
  def clean_post(msg), do: Api.delete_message(msg)
  def clean_post(post, msg) do
    try do
      clean_post(msg)
      Repo.delete(post)
      {:ok}
    catch
      _ -> {:error}
    end
  end

  def make_post(server, quest, channel_id) do
    case Api.create_message(channel_id, QuestManager.quest_block(quest)) do
      {:ok, msg} -> case {create_post_db(msg.id, server.server_id, quest.id), prepare_enlist_reactions(msg)} do
        {{:ok, _post}, {:ok}} -> "Quest posted successfully"
        {{:ok, post}, _} -> case clean_post(post, msg) do
          {:ok} -> "Posting failed. Failed adding reactions."
          {:error} -> "An error occured and could not recover"
        end
        _ -> case clean_post(msg) do
          {:ok} -> "An error occured while saving the quest posting. Posting failed."
          {:error} -> "An error occured and could not recover"
        end
      end
      _ -> "Failed to post, an error has occured while attempting to post."
    end
  end

  def post_quest(quest, server) do
    is_published = quest_published(quest)
    is_healthy = QuestManager.is_quest_healthy(quest)
    post_channel_configured = server.post_channel_id

    case {post_channel_configured, is_published, is_healthy} do
      {nil, _, _} -> "Server Post Channel not configured, please configure before continuing."
      {_, _, {:unhealthy, issues}} -> "Failed to Post. The Quest has the following issues:" <> QuestManager.bullet_point(issues)
      {channel_id, nil, {:healthy, _}} -> make_post(server, quest, channel_id)
      {_, _published_post, _} -> "Quest is already posted"
    end
  end
end
