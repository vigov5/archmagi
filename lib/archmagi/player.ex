defmodule Archmagi.Player do
  @moduledoc """
  Module used to define a player for a Archmagi
  """
  defstruct name: "",
            ready: false,
            tower: 0,
            wall: 0,
            quary: 0,
            bricks: 0,
            magic: 0,
            gems: 0,
            dungeon: 0,
            recruits: 0

  @wall 10
  @tower 25
  @product_rate 1
  @base_resource 15

  @doc """
  Returns a `Archmagi.Player` struct with the name populated.
  ## Examples:
      iex> Archmagi.Player.new("Ruben")
      %Archmagi.Player{name: "Ruben", ready: false}
  """
  def new(name) when is_binary(name) do
    %__MODULE__{
      name: name,
      tower: @tower,
      wall: @wall,
      quary: @product_rate,
      bricks: @base_resource,
      magic: @product_rate,
      gems: @base_resource,
      dungeon: @product_rate,
      recruits: @base_resource
    }
  end
end
