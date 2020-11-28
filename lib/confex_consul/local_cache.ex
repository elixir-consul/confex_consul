defmodule ConfexConsul.LocalCache do
  @moduledoc """
  Local cache, use proactive model.
  """

  use GenServer
  require Logger

  @refresh_interval Application.get_env(:confex_consul, :local_cache_refresh_interval, 1000)

  def get(consul_key) do
    case :ets.lookup(__MODULE__, consul_key) do
      [{^consul_key, value}] -> {:hit, value}
      _ -> :miss
    end
  end

  def put(consul_key, consul_value) do
    true = :ets.insert(__MODULE__, {consul_key, consul_value})
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

    Application.get_env(:confex_consul, :enable_local_cache_auto_refresh, true) and
      refresh_cache()

    timer = Process.send_after(self(), :refresh, @refresh_interval)
    {:noreply, %{state | timer: timer}}
  rescue
    e ->
      Logger.error("refresh cache error: #{inspect(e)}")
      timer = Process.send_after(self(), :refresh, @refresh_interval)
      {:noreply, %{state | timer: timer}}
  end

  @doc false
  def refresh_cache() do
    :confex_consul
    |> Application.get_env(:apps)
    |> Enum.each(fn app -> :ok = refresh_cache_by_app(app) end)
  end

  @doc false
  defp refresh_cache_by_app(app) do
    app
    |> Application.get_all_env()
    |> Enum.filter(fn {_, val} -> is_tuple(val) and {:via, ConfexConsul} == elem(val, 0) end)
    |> Enum.each(fn {_, app_val} -> refresh_cache_by_consul_key(app_val) end)
  end

  @doc false
  defp refresh_cache_by_consul_key({{:via, ConfexConsul}, consul_key}) do
    case ConfexConsul.ConsulKv.get_value(consul_key) do
      {:ok, _} = value -> put(consul_key, value)
      _ -> true
    end
  end

  defp refresh_cache_by_consul_key({{:via, ConfexConsul}, consul_key, default_value})
       when is_binary(consul_key) do
    case ConfexConsul.ConsulKv.get_value(consul_key) do
      {:ok, _} = value -> put(consul_key, value)
      _ -> put(consul_key, {:ok, default_value})
    end
  end

  defp refresh_cache_by_consul_key({{:via, ConfexConsul}, _type, consul_key})
       when is_binary(consul_key) do
    refresh_cache_by_consul_key({{:via, ConfexConsul}, consul_key})
  end

  defp refresh_cache_by_consul_key({{:via, ConfexConsul}, _type, consul_key, default_value}) do
    refresh_cache_by_consul_key({{:via, ConfexConsul}, consul_key, default_value})
  end
end
