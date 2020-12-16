defmodule ConfexConsulTest do
  use ExUnit.Case

  @prefix "test_confex_consul_#{:erlang.system_info(:otp_release)}_#{System.version()}"
  @json_prefix "test_confex_consul_json_#{:erlang.system_info(:otp_release)}_#{System.version()}"

  setup do
    _ = ConsulKv.recurse_delete(@prefix)
    _ = ConsulKv.recurse_delete(@json_prefix)
    _ = :ets.delete_all_objects(ConfexConsul.LocalCache)
    :ok
  end

  test "fetch string value" do
    key = "#{@prefix}/key_1"
    assert nil == Confex.get_env(:confex_consul, :only_key)
    assert :error = ConfexConsul.fetch_value(key)
    assert :miss == ConfexConsul.LocalCache.get(key)
    # put kv
    assert {:ok, true} == ConsulKv.put(key, "v1")
    assert {:ok, "v1"} == ConfexConsul.fetch_value(key)
    assert {:hit, {:ok, "v1"}} == ConfexConsul.LocalCache.get(key)
    assert "v1" == Confex.get_env(:confex_consul, :only_key)
  end

  test "fetch json value" do
    consul_key = "#{@json_prefix}/key_1"
    key = "decode: #{consul_key}"
    json = %{"a" => 1, "b" => %{"c" => 2}}
    encoded_json = Jason.encode!(%{"a" => 1, "b" => %{"c" => 2}})

    assert {:ok, true} == ConsulKv.put(consul_key, encoded_json)
    assert {:ok, json} == ConfexConsul.fetch_value(key)
    assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get(key)
    assert json == Confex.get_env(:confex_consul, :json_only_key)
  end

  describe "auto refresh values cache" do
    test "get default value from cache" do
      ConfexConsul.LocalCache.refresh_cache()
      # cache
      assert :miss == ConfexConsul.LocalCache.get("#{@prefix}/key_1")
      assert {:hit, {:ok, "default_value_2"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_2")
      assert :miss == ConfexConsul.LocalCache.get("#{@prefix}/key_3")
      assert {:hit, {:ok, "default_value_4"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_4")

      assert :miss == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_1")

      assert {:hit, {:ok, %{"default_value_2" => true}}} ==
               ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_2")

      assert :miss == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_3")

      assert {:hit, {:ok, %{"default_value_4" => false}}} ==
               ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_4")
    end

    test "get default config value from cache" do
      ConfexConsul.LocalCache.refresh_cache()

      assert nil == Confex.get_env(:confex_consul, :only_key)
      assert "default_value_2" == Confex.get_env(:confex_consul, :key_with_default)
      assert nil == Confex.get_env(:confex_consul, :type_with_key)
      assert "default_value_4" == Confex.get_env(:confex_consul, :type_with_key_with_default)

      assert nil == Confex.get_env(:confex_consul, :json_only_key)
      assert %{"default_value_2" => true} == Confex.get_env(:confex_consul, :json_key_with_default)
      assert nil == Confex.get_env(:confex_consul, :json_type_with_key)

      assert %{"default_value_4" => false} ==
               Confex.get_env(:confex_consul, :json_type_with_key_with_default)
    end

    test "get cached strings values when get values from consul failed" do
      ConsulKv.put("#{@prefix}/key_1", "v1")
      ConsulKv.put("#{@prefix}/key_2", "v2")
      ConsulKv.put("#{@prefix}/key_3", "v3")
      ConsulKv.put("#{@prefix}/key_4", "v4")

      assert "v1" == Confex.get_env(:confex_consul, :only_key)
      assert "v2" == Confex.get_env(:confex_consul, :key_with_default)
      assert "v3" == Confex.get_env(:confex_consul, :type_with_key)
      assert "v4" == Confex.get_env(:confex_consul, :type_with_key_with_default)

      assert {:hit, {:ok, "v1"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_1")
      assert {:hit, {:ok, "v2"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_2")
      assert {:hit, {:ok, "v3"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_3")
      assert {:hit, {:ok, "v4"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_4")

      _ = ConsulKv.recurse_delete(@prefix)
      ConfexConsul.LocalCache.refresh_cache()

      assert {:hit, {:ok, "v1"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_1")
      assert {:hit, {:ok, "v2"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_2")
      assert {:hit, {:ok, "v3"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_3")
      assert {:hit, {:ok, "v4"}} == ConfexConsul.LocalCache.get("#{@prefix}/key_4")
    end

    test "get cached decoded values when get values from consul failed" do
      json = %{"a" => 1, "b" => %{"c" => 2}}
      encoded_json = Jason.encode!(%{"a" => 1, "b" => %{"c" => 2}})

      ConsulKv.put("#{@json_prefix}/key_1", encoded_json)
      ConsulKv.put("#{@json_prefix}/key_2", encoded_json)
      ConsulKv.put("#{@json_prefix}/key_3", encoded_json)
      ConsulKv.put("#{@json_prefix}/key_4", encoded_json)

      assert json == Confex.get_env(:confex_consul, :json_only_key)
      assert json == Confex.get_env(:confex_consul, :json_key_with_default)
      assert json == Confex.get_env(:confex_consul, :json_type_with_key)
      assert json == Confex.get_env(:confex_consul, :json_type_with_key_with_default)

      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_1")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_2")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_3")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_4")

      _ = ConsulKv.recurse_delete(@json_prefix)
      ConfexConsul.LocalCache.refresh_cache()

      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_1")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_2")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_3")
      assert {:hit, {:ok, json}} == ConfexConsul.LocalCache.get("decode: #{@json_prefix}/key_4")
    end
  end
end
