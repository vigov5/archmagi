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

  def set_ready(id, player_name), do: try_call(id, {:set_ready, player_name})
  def play_card(id, player, hand_index), do: try_call(id, {:play_card, player, hand_index})

  # Server (callbacks)

  def init(default) do
    {:ok, default}
  end

  def handle_call(:get_data, _from, %Game{} = game) do
    {:reply, game, game}
  end

  def handle_call({:set_ready, player_name}, _from, game) do
    game = Game.set_ready(game, player_name)

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
        {:play_card, %{hand: hand, name: player_name}, hand_index},
        _from,
        %Game{turn_player: turn_player} = game
      ) do
    hand_index = String.to_integer(hand_index)

    with {:turn, true} <- {:turn, turn_player == player_name},
         {:index, true} <- {:index, hand_index in 0..(length(hand) - 1)},
         {:started, true} <- {:started, Game.is_status?(game, "playing")} do
      card = Enum.at(hand, hand_index)

      case Game.apply_effects(game, card, player_name) do
        {:ok, game} ->
          game = Game.update_player_deck_hand(game, player_name, hand_index)

          game =
            case Game.all_players_status?(game, "done") do
              true ->
                game
                |> Game.set_all_players_status("ready")
                |> Game.inc_resource()
                |> Game.switch_turn_player(player_name)

              false ->
                Game.switch_turn_player(game, player_name)
            end

          {:reply, {:ok, game}, game}

        {:error, message} ->
          {:reply, {:error, message}, game}
      end
    else
      {:turn, false} -> {:reply, {:error, "It's not your turn"}, game}
      {:index, false} -> {:reply, {:error, "Bad card position"}, game}
      {:started, false} -> {:reply, {:error, "Game not started"}, game}
    end
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
