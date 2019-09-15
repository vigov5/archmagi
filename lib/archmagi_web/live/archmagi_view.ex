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

  def mount(%{player_name: player_name, player_id: player_id} = session, socket) do
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
        player_id: player_id
      )

    {:ok, socket}
  end

  # handle broadcasts

  def handle_info(
        %{topic: "games", event: "updated"},
        socket
      ) do
    {:noreply, assign(socket, available_games: GameSupervisor.current_games())}
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

  def handle_info(
        %{
          topic: "game:" <> game_id,
          payload: %{message: message, game: game},
          event: "joined"
        },
        socket
      ) do
    Logger.debug("Event joined in game #{game_id} from socket #{socket.assigns.player_name}")
    {:noreply, assign(socket, message: message, game: game)}
  end

  def handle_info(
        %{
          topic: "game:" <> game_id,
          payload: %{message: message, game: game},
          event: "play_card"
        },
        socket
      ) do
    Logger.debug("Event play_card in game #{game_id} from socket #{socket.assigns.player_name}")
    {:noreply, assign(socket, message: message, game: game)}
  end

  # handle liveview
  def handle_event(_event, _value, %{assigns: %{player_name: player_name}} = socket)
      when player_name == "" do
    {:noreply, assign(socket, message: "Please login first!")}
  end

  def handle_event("create_game", _value, socket) do
    game_id = "g_#{:rand.uniform(10_000_000_000)}"
    {:ok, game_pid} = Archmagi.DynamicSupervisor.start_child(Game.new(game_id))

    Logger.debug("Game created #{inspect(game_pid)}")
    ArchmagiWeb.Endpoint.broadcast("games", "updated", %{})

    add_player(game_id, socket)
  end

  def handle_event("join_game", game_id, socket) do
    add_player(game_id, socket)
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

  def handle_event(event, hand_index, socket) when event in ["play_card", "discard_card"] do
    game = socket.assigns.game
    player = game.players[socket.assigns.player_name]

    result =
      case event do
        "play_card" -> GameServer.play_card(game.id, player, hand_index)
        "discard_card" -> GameServer.discard_card(game.id, player, hand_index)
      end

    case result do
      {:ok, game} ->
        {play_type, card} = game.last_played_card

        ArchmagiWeb.Endpoint.broadcast("game:#{game.id}", "play_card", %{
          message: "Player #{player.name} #{Atom.to_string(play_type)} card '#{card.name}'!",
          game: game
        })

        {:noreply, assign(socket, :game, game)}

      {:error, reason} ->
        Logger.debug(reason)
        {:noreply, assign(socket, :error, reason)}
    end
  end

  # logics

  def assign_game(socket, game) do
    socket
    |> assign(:game, game)
  end

  def add_player(game_id, socket) do
    player_name = socket.assigns.player_name
    player = Player.new(socket.assigns.player_id, player_name)

    case GameServer.add_player(game_id, player, self()) do
      {:ok, game} ->
        ArchmagiWeb.Endpoint.subscribe("game:#{game_id}")

        ArchmagiWeb.Endpoint.broadcast("game:#{game_id}", "joined", %{
          message: "Player #{player_name} joined!",
          game: game
        })

        {:noreply, assign(socket, :game, game)}

      {:error, reason} ->
        Logger.debug(reason)
        {:noreply, assign(socket, :error, reason)}
    end
  end

  def terminate(reason, socket) do
    Logger.debug("Terminating live view socket with reason #{inspect(reason)}")

    case socket.assigns.game do
      nil ->
        :ok

      game ->
        GameSupervisor.stop_game(game.id)

        ArchmagiWeb.Endpoint.broadcast("games", "stopped", %{
          message: "Player quitted, game stopped!"
        })
    end
  end
end
