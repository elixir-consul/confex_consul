defmodule ConfexConsul do
  @moduledoc """
  Documentation for `ConfexConsul`.
  """

  @behaviour Confex.Adapter

  @impl Confex.Adapter
  def fetch_value(consul_key) do
    case ConfexConsul.LocalCache.get(consul_key) do
      {:hit, value} -> value
      :miss -> get_from_consul_and_cache(consul_key)
    end
  end

  @doc false
  defp get_from_consul_and_cache(consul_key) do
    consul_key
    |> ConfexConsul.ConsulKv.get_value()
    |> write_cache_and_return(consul_key)
  end

  @doc false
  defp write_cache_and_return({:ok, value}, consul_key) do
    ConfexConsul.LocalCache.put(consul_key, {:ok, value})
    {:ok, value}
  end

  defp write_cache_and_return(other, _) do
    other
  end
end
