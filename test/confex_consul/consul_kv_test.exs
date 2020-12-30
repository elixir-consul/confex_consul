defmodule ConfexConsul.ConsulKvTest do
  use ExUnit.Case, async: false

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
      Application.put_env(:confex_consul, :circuit_breaker_switch, true)

      Application.put_env(
        :confex_consul,
        :circuit_breaker_option,
        {{:standard, 2, 2_000}, {:reset, 2_500}}
      )

      for _i <- 1..3 do
        assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
      end

      assert {:error, :fallback} = ConfexConsul.ConsulKv.get_value("not_exist")

      Process.sleep(3_000)
      assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
    end
  end
end
