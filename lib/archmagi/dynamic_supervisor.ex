defmodule Archmagi.DynamicSupervisor do
  @moduledoc """
  Dynamic supervisor used to create Archmagi games on demand.
  """
  use DynamicSupervisor

  alias Archmagi.Game
  alias Archmagi.GameServer
  require Logger

  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  def start_child(%Game{} = game) do
    DynamicSupervisor.start_child(__MODULE__, {GameServer, game})
  end

  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def stop_game(game_id) do
    Logger.debug("Stopping game #{game_id} in supervisor")

    case GenServer.whereis({:global, {:game, game_id}}) do
      nil ->
        Logger.debug("Game #{game_id} not found")

      pid ->
        Supervisor.terminate_child(__MODULE__, pid)
    end
  end

  def current_games do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(&game_data/1)
  end

  defp game_data({_id, pid, _type, _modules}) do
    pid
    |> GenServer.call(:get_data)
    |> Map.take([:id, :players])
  end
end
