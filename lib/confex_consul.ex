defmodule ConfexConsul do
  @moduledoc """
  Documentation for `ConfexConsul`.
  """

  @behaviour Confex.Adapter

  @impl Confex.Adapter
  def fetch_value(key) do
    ConfexConsul.ConsulClient.get_value(key)
  end
end
