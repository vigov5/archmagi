defmodule ArchmagiWeb.Live.ArchmagiView do
  use Phoenix.LiveView

  alias Archmagi.Game
  alias Archmagi.GameServer
  alias Archmagi.Player
  alias Archmagi.DynamicSupervisor, as: GameSupervisor

  require Logger

  def render(assigns) do
    ArchmagiWeb.PageView.render("archmagi.html", assigns)
  end

  def mount(%{player_name: player_name} = session, socket) do
    IO.puts("Test")
    IO.inspect(session)

    if connected?(socket) do
      Logger.debug("Liveview connected!")
      ArchmagiWeb.Endpoint.subscribe("games")
    end

    socket =
      socket
      |> assign(
        game: nil,
        error: "",
        message: "",
        available_games: GameSupervisor.current_games(),
        player_name: player_name,
        player_info: nil
      )

    {:ok, socket}
  end

  # handle broadcasts

  def handle_info(
        %{topic: "games", payload: %{message: message}, event: "updated"},
        socket
      ) do
    {:noreply, assign(socket, available_games: GameSupervisor.current_games(), message: message)}
  end

  def handle_info(%{topic: "games", payload: %{message: message}, event: "stopped"}, socket) do
    {:noreply,
     assign(socket, available_games: GameSupervisor.current_games(), message: message, game: nil)}
  end

  def handle_info(
        %{
          topic: "game:" <> game_id,
          payload: %{message: message, game: game},
          event: "set_ready"
        },
        socket
      ) do
    Logger.debug("Event set_ready in game #{game_id} from socket #{socket.assigns.player_name}")
    {:noreply, assign(socket, message: message, game: game)}
  end

  # handle liveview

  def handle_event("create_game", _value, socket) do
    game_id = "g_#{:rand.uniform(10_000_000_000)}"
    {:ok, game_pid} = Archmagi.DynamicSupervisor.start_child(Game.new(game_id))

    Logger.debug("Game created #{inspect(game_pid)}")

    add_player(game_id, socket.assigns.player_name, socket)
  end

  def handle_event("join_game", game_id, socket) do
    add_player(game_id, socket.assigns.player_name, socket)
  end

  def handle_event("set_ready", player_name, socket) do
    game_id = socket.assigns.game.id
    {:ok, game} = GameServer.set_ready(game_id, player_name)

    ArchmagiWeb.Endpoint.broadcast("game:#{game_id}", "set_ready", %{
      message: "Player #{player_name} ready!",
      game: game
    })

    {:noreply, assign(socket, :game, game)}
  end

  # logics

  def add_player(game_id, player_name, socket) do
    case GameServer.add_player(game_id, Player.new(player_name), self()) do
      {:ok, game} ->
        ArchmagiWeb.Endpoint.broadcast("games", "updated", %{
          message: "Player #{player_name} joined!"
        })

        ArchmagiWeb.Endpoint.subscribe("game:#{game_id}")

        {:noreply, assign_game(socket, game)}

      {:error, reason} ->
        Logger.debug(reason)
        {:noreply, assign(socket, :error, reason)}
    end
  end

  def assign_game(socket, game) do
    socket
    |> assign(:game, game)

    # |> player_info()
  end

  def terminate(reason, socket) do
    Logger.debug("Terminating live view socket with reason #{inspect(reason)}")

    case socket.assigns.game do
      nil ->
        :ok

      game ->
        GameSupervisor.stop_game(game.id)
        ArchmagiWeb.Endpoint.broadcast("games", "stopped", %{message: "Game stopped!"})
    end
  end
end