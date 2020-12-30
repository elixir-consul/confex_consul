defmodule ConfexConsul do
  @moduledoc """
  Documentation for `ConfexConsul`.
  """

  require Logger

  @behaviour Confex.Adapter

  @impl Confex.Adapter
  def fetch_value(key) do
    case ConfexConsul.LocalCache.get(key) do
      {:hit, value} -> value
      :miss -> get_from_consul_and_write_cache(key)
    end
  end

  @doc false
  defp get_from_consul_and_write_cache(key) do
    with {:ok, value} <- ConfexConsul.ConsulKv.get_value(key),
         _ <- ConfexConsul.LocalCache.put(key, {:ok, value}) do
      {:ok, value}
    else
      {:error, _reason} ->
        :error
    end
  end
end
