defmodule ConfexConsul.Application do
  @moduledoc false

  use Application

  def start(_, _) do
    children = [{ConfexConsul.LocalCache, []}]
    opts = [strategy: :one_for_one, name: ConfexConsul.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
