defmodule PhxestimationsWeb.Plugs.ParticipantSession do
  @moduledoc """
  Plug to ensure a participant has a unique session identifier.

  This plug generates a unique participant ID if one doesn't exist
  in the session, and makes it available for LiveViews.
  """

  import Plug.Conn

  alias Phxestimations.Poker

  @session_key "participant_id"
  @name_key "participant_name"

  def init(opts), do: opts

  def call(conn, _opts) do
    participant_id = get_session(conn, @session_key)

    if participant_id do
      conn
    else
      new_id = Poker.generate_participant_id()
      put_session(conn, @session_key, new_id)
    end
  end

  @doc """
  Gets the participant ID from the session.
  """
  def get_participant_id(session) do
    Map.get(session, @session_key)
  end

  @doc """
  Gets the participant name from the session, if stored.
  """
  def get_participant_name(session) do
    Map.get(session, @name_key)
  end

  @doc """
  Returns the session keys used by this plug.
  """
  def session_keys, do: {@session_key, @name_key}
end
