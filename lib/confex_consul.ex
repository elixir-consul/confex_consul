defmodule ConfexConsul do
  @moduledoc """
  Documentation for `ConfexConsul`.
  """

  @behaviour Confex.Adapter

  @impl Confex.Adapter
  def fetch_value(key) do
    case ConfexConsul.LocalCache.get_value(key) do
      {:hit, value} -> value
      :miss -> ConfexConsul.ConsulClient.get_value(key)
    end
  end
end
