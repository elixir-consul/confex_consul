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
      :miss -> get_from_consul_and_cache(key)
    end
  end

  @doc false
  defp get_from_consul_and_cache(key) do
    with {:ok, value} <- ConfexConsul.ConsulKv.get_value(key) do
      write_cache_and_return(key, {:ok, value})
    else
      {:error, reason} ->
        Logger.error("<#{__MODULE__}> get_from_consul_and_cache error: #{inspect(reason)}")

        :error
    end
  end

  @doc false
  defp write_cache_and_return(key, value) do
    ConfexConsul.LocalCache.put(key, value)
    value
  end
end
