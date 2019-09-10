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
      case Game.all_players_ready?(game) do
        true -> Game.change_status(game, "playing")
        _ -> game
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
