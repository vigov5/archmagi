defmodule Archmagi.Game do
  @moduledoc """
  Business logic to operate a Archmagi game.
  """
  defstruct id: '',
            players: %{},
            status: '',
            number_of_players: 0,
            turn_player: nil

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
    %Game{
      game
      | players: Map.put(players, player.name, player),
        number_of_players: number_of_players + 1
    }
  end

  def is_full?(%Game{number_of_players: number_of_players}), do: number_of_players == 2

  def player_joined?(%Game{players: players}, %Player{} = player),
    do: Map.has_key?(players, player.name)

  def is_status?(%Game{status: current_status}, status), do: current_status == status

  def change_status(%Game{status: status} = game, _) when status == "playing", do: game

  def change_status(game, new_status), do: %{game | status: new_status}

  def set_ready(game, player_name) do
    put_in(game, [Access.key(:players), player_name, Access.key(:ready)], true)
  end

  def all_players_ready?(%Game{players: players}) do
    Enum.all?(players, fn {_, p} -> p.ready end)
  end
end
