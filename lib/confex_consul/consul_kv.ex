defmodule ConfexConsul.ConsulKv do
  @moduledoc """
  Get value from Consul KV Store
  Support config circuit_breaker for in consul_key level
  """

  alias ConfexConsul.Utils

  @doc """
  Get value from Consul KV Store
  There are two type of keys:
    1. "decode: " + consul_key, get value by consul_key, then decode it by Jason
    1. consul_key, get value by consul_key directly
  """
  @spec get_value(String.t()) :: {:ok, any()} | {:error, any()}
  def get_value("decode: " <> consul_key) do
    with {:ok, value} <- get_value(consul_key) do
      Jason.decode(value)
    end
  end

  def get_value(consul_key) do
    with :ok <- ask_fuse(consul_key),
         {:ok, %ConsulKv{value: value}} <- ConsulKv.single_get(consul_key) do
      {:ok, value}
    else
      :blown ->
        {:error, :fallback}

      other ->
        melt(consul_key)
        other
    end
  end

  defp melt(consul_key) do
    :fuse.melt(consul_key)
  end

  defp ask_fuse(consul_key) do
    case circuit_breaker_switch?() do
      false -> :ok
      _ -> ask_switch(consul_key)
    end
  end

  defp circuit_breaker_switch? do
    Application.get_env(:confex_consul, :circuit_breaker_switch, false)
  end

  defp ask_switch(consul_key) do
    case :fuse.ask(consul_key, :async_dirty) do
      :ok ->
        :ok

      :blown ->
        :blown

      {:error, :not_found} ->
        install_fuse(consul_key)
        :ok
    end
  end

  @default_fuse_option Utils.get_default_fuse_option()
  defp install_fuse(consul_key) do
    option = Application.get_env(:confex_consul, :circuit_breaker_option, @default_fuse_option)
    :fuse.install(consul_key, option)
  end
end
