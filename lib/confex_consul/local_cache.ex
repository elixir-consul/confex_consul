defmodule ConfexConsul.LocalCache do
  @moduledoc """
  Local cache, use proactive model.
  """

  use GenServer
  require Logger
  alias ConfexConsul.Utils

  @refresh_interval Utils.get_local_cache_refresh_interval()

  def get(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, value}] -> {:hit, value}
      _ -> :miss
    end
  end

  def put(key, consul_value) do
    true = :ets.insert(__MODULE__, {key, consul_value})
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
      :ok = :telemetry.execute([:local_cache, :refresh_key, :error], %{}, %{error: e})
      timer = Process.send_after(self(), :refresh, @refresh_interval)
      {:noreply, %{state | timer: timer}}
  end

  @doc false
  def refresh_cache do
    get_confex_consul_config_apps()
    |> Enum.each(&refresh_cache_by_app/1)
  end

  @doc false
  defp get_confex_consul_config_apps do
    case Application.get_env(:confex_consul, :apps, try_get_app()) do
      apps when is_list(apps) -> apps
      nil -> []
      app -> [app]
    end
  end

  @doc false
  defp try_get_app do
    Application.get_env(:confex_consul, :app)
  end

  @doc false
  defp refresh_cache_by_app(app) do
    app
    |> Application.get_all_env()
    |> Enum.filter(fn {_, val} -> is_tuple(val) and {:via, ConfexConsul} == elem(val, 0) end)
    |> Enum.each(fn {_, app_val} -> refresh_cache_by_key(app_val) end)

    :ok = :telemetry.execute([:local_cache, :refresh_app, :done], %{}, %{app: app})
  end

  @doc false
  defp refresh_cache_by_key({{:via, ConfexConsul}, key}) do
    refresh_cache_by_key(key)
  end

  defp refresh_cache_by_key({{:via, ConfexConsul}, key, default_value}) when is_binary(key) do
    refresh_cache_by_key(key, default_value)
  end

  defp refresh_cache_by_key({{:via, ConfexConsul}, _type, key}) do
    refresh_cache_by_key(key)
  end

  defp refresh_cache_by_key({{:via, ConfexConsul}, _type, key, default_value}) do
    refresh_cache_by_key(key, default_value)
  end

  defp refresh_cache_by_key(key, default_value \\ nil) do
    case ConfexConsul.ConsulKv.get_value(key) do
      {:ok, _} = value ->
        put(key, value)

      {:error, _reason} ->
        maybe_put_default_value(key, default_value)
    end
  end

  defp maybe_put_default_value(_key, nil), do: true

  defp maybe_put_default_value(key, default_value) do
    case get(key) do
      {:hit, _value} -> true
      :miss -> put(key, {:ok, default_value})
    end
  end
end
