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
end
