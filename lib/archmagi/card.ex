defmodule Archmagi.Card do
  @moduledoc """
  Module used to define a card for Archmagi
  """
  defstruct name: "",
            id: nil,
            costs: [],
            effects: [],
            desc: ""

  def new(id, name, costs, effects, desc) do
    %__MODULE__{
      id: id,
      name: name,
      costs: costs,
      effects: effects,
      desc: desc
    }
  end

  def have_resource?(player, resource, price), do: Map.get(player, resource) >= price

  def can_play?(player, %{costs: costs}) do
    Enum.all?(costs, fn {resource, price} -> have_resource?(player, resource, price) end)
  end

  def apply_effects(game, %{costs: costs, effects: effects} = card, player_name) do
    {me, you} = Archmagi.Game.get_ordered_players(game, player_name)

    case can_play?(me, card) do
      true ->
        game
        |> pay_card_price(costs, me)
        |> do_apply_effects(effects, me, you)

        {:ok, game}

      false ->
        {:error, "Not enough resource!"}
    end
  end

  def pay_card_price(game, [{resource, price} | tail], me) do
    pay_card_price(game, tail, Map.update(me, resource, 0, &(&1 - price)))
  end

  def pay_card_price(game, [], me), do: put_in(game, [Access.key(:players), me.name], me)

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
    current_wall = get_resource(game, player.name, :wall)
    set_resource(game, player.name, :wall, Enum.min([current_wall + value, 60]))
  end

  def apply_effect(game, {:add, resource, value}, player) do
    add_resource(game, player.name, resource, value)
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
    end
  end

  def add_resource(game, player_name, resource, value) do
    get_and_update_in(
      game,
      [Access.key(:players), player_name, Access.key(resource)],
      &{&1, &1 + value}
    )
  end

  def sub_resource(game, player_name, resource, value) do
    current = get_resource(game, player_name, resource)
    set_resource(game, player_name, resource, Enum.min([current - value, 0]))
  end

  def set_resource(game, player_name, resource, value) do
    put_in(game, [Access.key(:players), player_name, Access.key(resource)], value)
  end

  def get_resource(game, player_name, resource) do
    get_in(game, [Access.key(:players), player_name, Access.key(resource)])
  end
end
