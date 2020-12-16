defmodule ConfexConsul.UtilsTest do
  use ExUnit.Case, async: false

  alias ConfexConsul.Utils

  describe "get_local_cache_refresh_interval" do
    test "should default to 60_000" do
      Application.delete_env(:confex_consul, :local_cache_refresh_interval)
      assert 60_000 == Utils.get_local_cache_refresh_interval()
    end

    test "should respect config value" do
      Application.put_env(:confex_consul, :local_cache_refresh_interval, 10)
      assert 10_000 == Utils.get_local_cache_refresh_interval()
    end

    test "should not be less than 5_000" do
      Application.put_env(:confex_consul, :local_cache_refresh_interval, 1)
      assert 5_000 == Utils.get_local_cache_refresh_interval()

      Application.put_env(:confex_consul, :local_cache_refresh_interval, -1.2)
      assert 5_000 == Utils.get_local_cache_refresh_interval()
    end
  end
end
