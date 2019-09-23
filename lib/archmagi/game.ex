defmodule Archmagi.Game do
  @moduledoc """
  Business logic to operate a Archmagi game.
  """
  defstruct id: '',
            players: %{},
            status: '',
            number_of_players: 0,
            turn_player: nil,
            last_played_card: {:played, nil},
            winner: ''

  import Ecto.Query, warn: false
  alias Archmagi.Game
  alias Archmagi.Player
  alias Archmagi.Repo
  alias Archmagi.Decks
  alias Archmagi.Users.User
  require Logger

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
        number_of_players: number_of_players + 1,
        turn_player: if(number_of_players == 1, do: player.name, else: nil)
    }
  end

  def is_full?(%Game{number_of_players: number_of_players}), do: number_of_players == 2

  def player_joined?(%Game{players: players}, %Player{} = player),
    do: Map.has_key?(players, player.name)

  def is_status?(%Game{status: current_status}, status), do: current_status == status
  def change_status(game, new_status), do: %{game | status: new_status}

  def set_ready(game, player_name) do
    # TODO allow select deck
    deck =
      Archmagi.Repo.get!(User, game.players[player_name].id)
      |> Ecto.assoc(:decks)
      |> Repo.all()
      |> List.first()

    {hand, cards} =
      deck
      |> Decks.parse_cards()
      |> Enum.shuffle()
      |> Enum.split(6)

    game
    |> set_player_status(player_name, "ready")
    |> set_deck_and_hand(player_name, cards, hand)
  end

  def all_players_status?(%Game{players: players}, status) do
    Enum.all?(players, fn {_, p} -> p.status == status end)
  end

  def set_player_status(game, player_name, status) do
    game
    |> put_in([Access.key(:players), player_name, Access.key(:status)], status)
  end

  def set_all_players_status(%Game{players: players} = game, status) do
    [p1, p2] = Map.keys(players)

    game
    |> set_player_status(p1, status)
    |> set_player_status(p2, status)
  end

  def get_ordered_players(game, player_name) do
    [{_, you}] = Enum.filter(game.players, fn {k, _} -> k != player_name end)
    {game.players[player_name], you}
  end

  def have_resource?(player, resource, price), do: Map.get(player, resource) >= price

  def can_play?(player, %{costs: costs}) do
    Enum.all?(costs, fn {resource, price} -> have_resource?(player, resource, price) end)
  end

  def apply_effects(game, %{costs: costs, effects: effects} = card, player_name) do
    {me, you} = get_ordered_players(game, player_name)

    case can_play?(me, card) do
      true ->
        game =
          game
          |> pay_card_price(costs, me)
          |> do_apply_effects(effects, me, you)
          |> set_player_status(me.name, "done")

        {:ok, %{game | last_played_card: {:played, card}}}

      false ->
        {:error, "Not enough resource!"}
    end
  end

  def pay_card_price(game, [{resource, price} | tail], me) do
    pay_card_price(game, tail, Map.update(me, resource, 0, &(&1 - price)))
  end

  def pay_card_price(game, [], me) do
    put_in(game, [Access.key(:players), Access.key(me.name)], me)
  end

  def do_apply_effects(game, [{target, info} | tail], me, you) do
    targets =
      case target do
        :me -> me
        :you -> you
        :both -> [me, you]
      end

    game
    |> apply_effect(info, targets)
    |> do_apply_effects(tail, me, you)
  end

  def do_apply_effects(game, [], _, _), do: game

  def apply_effect(game, info, [me, you]) do
    game
    |> apply_effect(info, me)
    |> apply_effect(info, you)
  end

  def apply_effect(game, {:add, :wall, value}, player) do
    add_resource(game, player.name, :wall, value, 60)
  end

  def apply_effect(game, {:add, :tower, value}, player) do
    add_resource(game, player.name, :tower, value, 100)
  end

  def apply_effect(game, {:add, resource, value}, player) do
    add_resource(game, player.name, resource, value)
  end

  def apply_effect(game, {:sub, resource, value}, player)
      when resource in [:quarry, :magic, :dungeon] do
    sub_resource(game, player.name, resource, value, 1)
  end

  def apply_effect(game, {:sub, resource, value}, player) do
    sub_resource(game, player.name, resource, value)
  end

  def apply_effect(game, {:attack_wall, value}, player) do
    current_wall = get_resource(game, player.name, :wall)

    if current_wall < value do
      game
      |> set_resource(player.name, :wall, 0)
      |> sub_resource(player.name, :tower, value - current_wall)
    else
      sub_resource(game, player.name, :wall, value)
    end
  end

  def add_resource(game, player_name, resource, value, max \\ 9999) do
    game
    |> get_and_update_in(
      [Access.key(:players), player_name, Access.key(resource)],
      &{&1, Enum.min([&1 + value, max])}
    )
    |> elem(1)
  end

  def sub_resource(game, player_name, resource, value, min \\ 0) do
    current = get_resource(game, player_name, resource)
    set_resource(game, player_name, resource, Enum.max([current - value, min]))
  end

  def set_resource(game, player_name, resource, value) do
    put_in(game, [Access.key(:players), player_name, Access.key(resource)], value)
  end

  def get_resource(game, player_name, resource) do
    get_in(game, [Access.key(:players), player_name, Access.key(resource)])
  end

  def update_player_deck_hand(game, player_name, hand_index) do
    player = game.players[player_name]
    {next_card, new_deck} = List.pop_at(player.deck, 0)
    new_hand = List.delete_at(player.hand, hand_index) ++ [next_card]

    set_deck_and_hand(game, player_name, new_deck, new_hand)
  end

  def set_deck_and_hand(game, player_name, deck, hand) do
    game
    |> put_in([Access.key(:players), player_name, Access.key(:deck)], deck)
    |> put_in([Access.key(:players), player_name, Access.key(:hand)], hand)
  end

  def switch_turn_player(%Game{players: players} = game, current_player) do
    [{next_player, _}] = Enum.filter(players, fn {k, _} -> k != current_player end)
    set_player_status(%{game | turn_player: next_player}, next_player, "playing")
  end

  def inc_resource(%{players: players} = game) do
    [p1, p2] = Map.values(players)

    game
    |> inc_player_resource(p1)
    |> inc_player_resource(p2)
  end

  def inc_player_resource(game, player) do
    new_resources =
      [quarry: :bricks, magic: :gems, dungeon: :recruits]
      |> Enum.reduce(%{}, fn {type, resource}, acc ->
        current = get_resource(game, player.name, resource)
        value = get_resource(game, player.name, type)
        Map.put(acc, resource, current + value)
      end)

    put_in(
      game,
      [Access.key(:players), Access.key(player.name)],
      Map.merge(player, new_resources)
    )
  end

  def is_finished?(%Game{players: players}) do
    Map.values(players)
    |> Enum.any?(fn p -> p.tower == 100 || p.tower == 0 end)
  end

  def get_winner(%Game{players: players}) do
    [p1, p2] = Map.values(players)

    cond do
      p1.tower == 100 -> p1
      p2.tower == 100 -> p2
      p1.tower == 0 -> p2
      p2.tower == 0 -> p1
    end
  end

  def next_turn(game, current_player_name) do
    case Game.all_players_status?(game, "done") do
      true ->
        game
        |> Game.set_all_players_status("ready")
        |> Game.inc_resource()
        |> Game.switch_turn_player(current_player_name)

      false ->
        Game.switch_turn_player(game, current_player_name)
    end
  end

  def get_players(game) do
    case game.number_of_players do
      0 ->
        [nil, nil]

      1 ->
        [hd(Map.values(game.players)), nil]

      2 ->
        Map.keys(game.players)
        |> Enum.sort()
        |> Enum.map(&Map.get(game.players, &1))
    end
  end

  def get_ratio(%{number_of_players: number_of_players} = game) when number_of_players == 2 do
    [score1, score2] =
      get_players(game)
      |> Enum.map(fn p -> p.tower + p.wall end)

    total = score1 + score2

    [score1, score2]
    |> Enum.map(fn s -> s / total * 100 end)
  end

  def get_ratio(_), do: [50, 50]
end
