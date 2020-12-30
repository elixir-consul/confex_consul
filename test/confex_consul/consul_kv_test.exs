defmodule ConfexConsul.ConsulKvTest do
  use ExUnit.Case, async: true

  @prefix "test_consul_kv_#{:erlang.system_info(:otp_release)}_#{System.version()}/"

  setup do
    _ = ConsulKv.recurse_delete(@prefix)
    :ok
  end

  describe "get_value" do
    test "by string key" do
      key = @prefix <> "string_key"
      {:ok, true} = ConsulKv.put(key, "v1")
      assert {:ok, "v1"} = ConfexConsul.ConsulKv.get_value(key)
    end

    test "by decode key" do
      key = @prefix <> "json_key"
      {:ok, true} = ConsulKv.put(key, "{\"a\":1,\"b\":2,\"c\":3}")
      assert {:ok, "{\"a\":1,\"b\":2,\"c\":3}"} = ConfexConsul.ConsulKv.get_value(key)

      assert {:ok, %{"a" => 1, "b" => 2, "c" => 3}} =
               ConfexConsul.ConsulKv.get_value("decode: #{key}")
    end

    test "circuit_breaker work when get value" do
      assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
      assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
      assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")

      assert {:error, :fallback} = ConfexConsul.ConsulKv.get_value("not_exist")

      Process.sleep(5_000)
      assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
    end
  end
end
