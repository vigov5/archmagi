defmodule Archmagi.Game do
  @moduledoc """
  Business logic to operate a Archmagi game.
  """
  defstruct id: '',
            questions: [],
            players: [],
            status: '',
            number_of_players: 0

  alias Archmagi.Game
  alias Archmagi.Player

  def new(game_id) do
    %Game{id: game_id, status: "waiting"}
  end

  def start_game(%Game{} = game) do
    game
  end

  def add_player(
        %Game{players: players, number_of_players: number_of_players} = game,
        %Player{} = player
      ) do
    %Game{game | players: [player | players], number_of_players: number_of_players + 1}
  end

  def is_full?(%Game{number_of_players: number_of_players}), do: number_of_players == 2

  def player_joined?(%Game{players: players}, %Player{} = player),
    do: Enum.any?(players, &(&1.name == player.name))

  def is_status?(%Game{status: current_status}, status), do: current_status == status

  def change_status(%Game{status: status} = game) when status == "playing", do: game
end
