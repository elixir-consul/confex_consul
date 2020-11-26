defmodule ConfexConsul.LocalCache do
  @moduledoc """
  Local cache, use proactive model.
  """

  use GenServer

  require Logger

  def get_value(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:hit, value}
      _ -> :miss
    end
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ets.new(__MODULE__, [{:read_concurrency, true}, :named_table, :public])
    Process.send(self(), :refresh, [])
    {:ok, %{timer: nil}}
  end

  @impl GenServer
  def handle_info(:refresh, %{timer: timer} = state) do
    if timer do
      Process.cancel_timer(timer)
    end

    refresh_cache()
    timer = Process.send_after(self(), :refresh, 1000)
    {:noreply, %{state | timer: timer}}
  rescue
    e ->
      Logger.error("refresh cache error: #{inspect(e)}")
      timer = Process.send_after(self(), :refresh, 1000)
      {:noreply, %{state | timer: timer}}
  end

  @doc false
  defp refresh_cache() do
    :confex_consul
    |> Application.get_env(:apps)
    |> Enum.each(fn app -> :ok = refresh_cache_by_app(app) end)
  end

  @doc false
  defp refresh_cache_by_app(app) do
    app
    |> Application.get_all_env()
    |> Enum.filter(fn {_, val} -> is_tuple(val) and {:via, ConfexConsul} == elem(val, 0) end)
    |> Enum.each(fn {_, {_, consul_key}} ->
      insert_cache(consul_key, ConfexConsul.ConsulClient.get_value(consul_key))
    end)
  end

  @doc false
  defp insert_cache(consul_key, {:ok, _} = value) do
    true = :ets.insert(__MODULE__, {consul_key, value})
  end

  defp insert_cache(_consul_key, _error_value) do
    true
  end
end
