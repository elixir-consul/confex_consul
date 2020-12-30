defmodule ConfexConsul.TelemetryTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  describe "attach telemetry" do
    test "consul kv not found" do
      ConfexConsul.TelemetryUser.attach()

      log =
        capture_log(fn ->
          assert {:error, :not_found} = ConfexConsul.ConsulKv.get_value("not_exist")
        end)

      assert log =~ ~S(Get value from Consul KV failed for key "not_exist", reason: :not_found)
    end

    test "refresh cache" do
      ConfexConsul.TelemetryUser.attach()

      log =
        capture_log(fn ->
          assert :ok = ConfexConsul.LocalCache.refresh_cache()
        end)

      assert log =~ ~S(Refresh config for app :confex_consul)
    end
  end
end
