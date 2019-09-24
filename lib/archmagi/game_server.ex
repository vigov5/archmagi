defmodule Archmagi.GameServer do
  @moduledoc """
  Maintain the state of a `Archmagi.Game` manage time and messages
  for the process.
  """
  use GenServer, restart: :transient

  alias Archmagi.Game
  alias Archmagi.Player
  require Logger

  defp ref(id), do: {:global, {:game, id}}

  # Client

  def start_link(%Game{id: id} = default) do
    GenServer.start_link(__MODULE__, default, name: ref(id))
  end

  def get_data(id), do: try_call(id, :get_data)

  def add_player(id, player, liveview_pid),
    do: try_call(id, {:add_player, player, liveview_pid})

  def set_ready(id, player_name, deck_id), do: try_call(id, {:set_ready, player_name, deck_id})

  def play_card(id, player, hand_index), do: try_call(id, {:play_card, player, hand_index})

  def discard_card(id, player, hand_index), do: try_call(id, {:discard_card, player, hand_index})

  # Server (callbacks)

  def init(default) do
    {:ok, default}
  end

  def handle_call(:get_data, _from, %Game{} = game) do
    {:reply, game, game}
  end

  def handle_call({:set_ready, player_name, deck_id}, _from, game) do
    game = Game.set_ready(game, player_name, deck_id)

    game =
      cond do
        Game.all_players_status?(game, "ready") and Game.is_full?(game) ->
          game
          |> Game.change_status("playing")
          |> Game.set_player_status(game.turn_player, "playing")

        true ->
          game
      end

    {:reply, {:ok, game}, game}
  end

  def handle_call({:add_player, %Player{} = player, liveview_pid}, _from, %Game{} = game) do
    with {:joined, false} <- {:joined, Game.player_joined?(game, player)},
         {:full, false} <- {:full, Game.is_full?(game)},
         {:started, false} <- {:started, Game.is_status?(game, "playing")} do
      Process.monitor(liveview_pid)
      game = Game.add_player(game, player)
      {:reply, {:ok, game}, game}
    else
      {:joined, true} -> {:reply, {:ok, game}, game}
      {:full, true} -> {:reply, {:error, "Game is full"}, game}
      {:started, true} -> {:reply, {:error, "Game has already started"}, game}
    end
  end

  def handle_call(
        {action, %{hand: hand, name: player_name} = player, hand_index},
        _from,
        %Game{turn_player: turn_player} = game
      )
      when action in [:play_card, :discard_card] do
    hand_index = String.to_integer(hand_index)

    with {:turn, true} <- {:turn, turn_player == player_name},
         {:index, true} <- {:index, hand_index in 0..(length(hand) - 1)},
         {:started, true} <- {:started, Game.is_status?(game, "playing")} do
      case action do
        :play_card -> do_handle_play_card(game, player, hand_index)
        :discard_card -> do_handle_discard_card(game, player, hand_index)
      end
    else
      {:turn, false} -> {:reply, {:error, "It's not your turn"}, game}
      {:index, false} -> {:reply, {:error, "Bad card position"}, game}
      {:started, false} -> {:reply, {:error, "Game not started"}, game}
    end
  end

  def do_handle_play_card(game, %{hand: hand, name: player_name}, hand_index) do
    card = Enum.at(hand, hand_index)

    case Game.apply_effects(game, card, player_name) do
      {:ok, game} ->
        game = Game.update_player_deck_hand(game, player_name, hand_index)

        case Game.is_finished?(game) do
          true ->
            winner = Game.get_winner(game)

            game =
              game
              |> Game.change_status("finished")
              |> Map.put(:winner, winner.name)

            {:reply, {:ok, game}, game}

          false ->
            game = Game.next_turn(game, player_name)
            {:reply, {:ok, game}, game}
        end

      {:error, message} ->
        {:reply, {:error, message}, game}
    end
  end

  def do_handle_discard_card(game, %{hand: hand, name: player_name}, hand_index) do
    card = Enum.at(hand, hand_index)

    game =
      game
      |> Game.update_player_deck_hand(player_name, hand_index)
      |> Game.set_player_status(player_name, "done")
      |> Game.next_turn(player_name)
      |> Map.put(:last_played_card, {:discarded, card})

    {:reply, {:ok, game}, game}
  end

  # Server (helpers)

  def handle_info({:DOWN, _ref, :process, pid, reason}, state) do
    Logger.debug("Player #{inspect(pid)} left with reason #{inspect(reason)}!")
    {:noreply, state}
  end

  defp try_call(id, message) do
    case GenServer.whereis(ref(id)) do
      nil ->
        {:error, "Game does not exist"}

      game ->
        Logger.debug("#{id}: Call #{inspect(message)}", ansi_color: :yellow)
        GenServer.call(game, message)
    end
  end
end
