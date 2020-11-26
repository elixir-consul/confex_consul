defmodule ConfexConsul.ConsulClient do
  use Tesla

  adapter(Tesla.Adapter.Hackney,
    recv_timeout: Application.get_env(:confex_consul, :consul_recv_timeout, 5000),
    connect_timeout: Application.get_env(:confex_consul, :consul_connect_timeout, 5000)
  )

  plug(Tesla.Middleware.BaseUrl, Application.get_env(:confex_consul, :consul_address))
  plug(Tesla.Middleware.JSON)

  def get_value(key) do
    key
    |> get()
    |> case do
      {:ok, %{status: 200, body: [%{"Value" => value, "Key" => ^key}]}} -> Base.decode64(value)
      {:ok, other_status} -> {:error, other_status}
      other -> other
    end
  end

  def put_value(key, value) do
    key
    |> put(value)
    |> case do
      {:ok, %{status: 200}} -> {:ok, true}
      {:ok, other_status} -> {:error, other_status}
      other -> other
    end
  end
end
