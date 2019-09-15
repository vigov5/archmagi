defmodule Archmagi.Player do
  @moduledoc """
  Module used to define a player for a Archmagi
  """
  defstruct name: "",
            id: nil,
            status: "idle",
            tower: 0,
            wall: 0,
            quarry: 0,
            bricks: 0,
            magic: 0,
            gems: 0,
            dungeon: 0,
            recruits: 0,
            deck: [],
            hand: []

  @wall 10
  @tower 25
  @product_rate 1
  @base_resource 15

  @doc """
  Returns a `Archmagi.Player` struct with the name populated.
  """
  def new(id, name) do
    %__MODULE__{
      name: name,
      id: id,
      tower: @tower,
      wall: @wall,
      quarry: @product_rate,
      bricks: @base_resource,
      magic: @product_rate,
      gems: @base_resource,
      dungeon: @product_rate,
      recruits: @base_resource
    }
  end
end
