defmodule ConfexConsulTest do
  use ExUnit.Case

  @prefix "test_confex_consul_#{:erlang.system_info(:otp_release)}_#{System.version()}/"

  setup do
    _ = ConsulKv.recurse_delete(@prefix)
    _ = :ets.delete_all_objects(ConfexConsul.LocalCache)
    :ok
  end

  test "fetch value" do
    key = "#{@prefix}/key_1"
    assert nil == Confex.get_env(:confex_consul, :only_key)
    assert {:error, _} = ConfexConsul.fetch_value(key)
    assert :miss == ConfexConsul.LocalCache.get(key)
    # put kv
    assert {:ok, true} == ConsulKv.put(key, "v1")
    assert {:ok, "v1"} == ConfexConsul.fetch_value(key)
    assert {:hit, {:ok, "v1"}} == ConfexConsul.LocalCache.get(key)
    assert "v1" == Confex.get_env(:confex_consul, :only_key)
  end

  test "auto refresh cache" do
    ConfexConsul.LocalCache.refresh_cache()
    # default value
    # cache
    assert :miss == ConfexConsul.LocalCache.get("#{@prefix}/key_1")
    assert {:hit, {:ok, "default_value_2"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_2")
    assert :miss == ConfexConsul.LocalCache.get("#{@prefix}/key_3")
    assert {:hit, {:ok, "default_value_4"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_4")
    # confex
    assert nil == Confex.get_env(:confex_consul, :only_key)
    assert "default_value_2" == Confex.get_env(:confex_consul, :key_with_default)
    assert nil == Confex.get_env(:confex_consul, :type_with_key)
    assert "default_value_4" == Confex.get_env(:confex_consul, :type_with_key_with_default)
    # set value
    assert {:ok, true} = ConsulKv.put("#{@prefix}/key_1", "v1")
    assert {:ok, true} = ConsulKv.put("#{@prefix}/key_2", "v2")
    assert {:ok, true} = ConsulKv.put("#{@prefix}/key_3", "v3")
    assert {:ok, true} = ConsulKv.put("#{@prefix}/key_4", "v4")
    # refresh cache
    ConfexConsul.LocalCache.refresh_cache()
    assert {:hit, {:ok, "v1"}} = ConfexConsul.LocalCache.get("#{@prefix}/key_1")
    assert {:hit, {:ok, "v2"}} = ConfexConsul.LocalCache.get("#{@prefix}/key_2")
    assert {:hit, {:ok, "v3"}} = ConfexConsul.LocalCache.get("#{@prefix}/key_3")
    assert {:hit, {:ok, "v4"}} = ConfexConsul.LocalCache.get("#{@prefix}/key_4")
    # confex
    assert "v1" == Confex.get_env(:confex_consul, :only_key)
    assert "v2" == Confex.get_env(:confex_consul, :key_with_default)
    assert "v3" == Confex.get_env(:confex_consul, :type_with_key)
    assert "v4" == Confex.get_env(:confex_consul, :type_with_key_with_default)
  end
end
