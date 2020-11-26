defmodule ConfexConsulTest do
  use ExUnit.Case

  test "put value and get value" do
    {:ok, true} = ConfexConsul.ConsulClient.put_value("test-key", "test-value")
    {:ok, "test-value"} = ConfexConsul.ConsulClient.get_value("test-key")
  end
end
