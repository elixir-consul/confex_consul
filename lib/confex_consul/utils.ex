defmodule ConfexConsul.Utils do
  @moduledoc false

  def get_local_cache_refresh_interval do
    :confex_consul
    |> Application.get_env(:local_cache_refresh_interval, 60)
    |> Kernel.*(1000)
    |> :erlang.max(5000)
    |> round()
  end
end
