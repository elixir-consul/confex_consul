defmodule ConfexConsul do
  @moduledoc """
  Documentation for `ConfexConsul`.
  """

  @behaviour Confex.Adapter

  @impl Confex.Adapter
  def fetch_value(key) do
    case ConsulKv.single_get(key) do
      {:ok, %ConsulKv{value: value}} -> {:ok, value}
      other -> other
    end
  end
end
