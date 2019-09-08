defmodule Archmagi.Player do
  @moduledoc """
  Module used to define a player for a Archmagi
  """
  defstruct name: "", points: 0, waiting_response: false

  @doc """
  Returns a `Archmagi.Player` struct with the name populated.
  ## Examples:
      iex> Archmagi.Player.new("Ruben")
      %Archmagi.Player{name: "Ruben", points: 0, waiting_response: false}
  """
  def new(name) when is_binary(name) do
    %__MODULE__{name: name}
  end
end
