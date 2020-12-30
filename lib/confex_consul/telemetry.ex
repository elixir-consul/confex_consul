defmodule ConfexConsul.Telemetry do
  @moduledoc """
  Telemetry integration for event tracing, metrics, and logging.

  ConsulKv execute the fetch_key event:
    * `[:consul_kv, :fetch_value, :done]` - Got response from Consul KV Store
      Measurements are:

      * `:duration` - The time of fetching value from Consul KV Store, in ms

      Metadata are:

      * `:status` - fetching response status, `:ok` or `:error`
      * `:key` - the key sent to Consul KV Store
      * `:value` - the value fetched from Consul KV Store, it's exist when status is `:ok`
      * `:reason` - the error reason, it's exist when status is `:error`

  LocalCache execute those events:
    * `[local_cache:, :refresh_app, :done]` - After refresh one app's configs
      Metadata are:

      * `:app` - the app that include the config

    * `[local_cache:, :refresh_configs, :error]` - Got unknown error when refresh local cache
      Metadata are:

      * `:error` - the error that occur, in any term

  To handle those events, you can use this module:
    1. Define your module and use `ConfexConsul.Telemetry`

        defmodule MyApp.Telemetry do
          use ConfexConsul.Telemetry
        end

      It supports to enable statsd metrics by adding `statsd_module` option
      Note that the statsd_module should be [StatsD](https://github.com/statsd/statsd)-compatible

        defmodule MyApp.Telemetry do
          use ConfexConsul.Telemetry, statsd_module: MyApp.Metrix
        end

    2. Attach the handler when your application starts

        MyApp.Telemetry.attach()

      You can override `handle_event/4`
  """

  defmacro __using__(opts) do
    quote location: :keep do
      require Logger

      @statsd_module unquote(Keyword.get(opts, :statsd_module))

      def attach do
        events = [
          [:consul_kv, :fetch_value, :done],
          [:local_cache, :refresh_app, :done],
          [:local_cache, :refresh, :error]
        ]

        :telemetry.attach_many(
          "confex-consul-handler",
          events,
          &__MODULE__.handle_event/4,
          :no_config
        )
      end

      def handle_event([:consul_kv, :fetch_value, :done], measurements, metadata, :no_config) do
        case metadata do
          %{status: :ok, key: key, value: value} ->
            Logger.info("Get value #{inspect(value)} from Consul KV for key #{inspect(key)}")

            statsd_histogram("consul_kv.get_value.duration", measurements.duration,
              tags: ["status:ok"]
            )

          %{status: :error, key: key, reason: reason} ->
            Logger.error(
              "Get value from Consul KV failed for key #{inspect(key)}, reason: #{inspect(reason)}"
            )

            statsd_histogram("consul_kv.get_value.duration", measurements.duration,
              tags: ["status:error"]
            )
        end

        statsd_increment("consul_kv.get", 1, tags: ["status:#{metadata.status}"])
      end

      def handle_event([:local_cache, :refresh_app, :done], _measurements, metadata, :no_config) do
        Logger.info("Refresh config for app #{inspect(metadata.app)}")
        statsd_increment("confex_consul.localcache.refresh_app", 1, tags: ["app:#{metadata.app}"])
      end

      def handle_event([:local_cache, :refresh, :error], _measurements, metadata, :no_config) do
        Logger.error("ConfexConsul refresh cache error: #{inspect(metadata.error)}")
      end

      def handle_event(_, _, _, _), do: :ok

      defoverridable handle_event: 4

      ## Metric helpers
      if is_nil(@statsd_module) do
        def statsd_histogram(_, _, _), do: :ok
        def statsd_increment(_, _, _), do: :ok
      else
        defdelegate statsd_histogram(key, value, options), to: @statsd_module, as: :histogram
        defdelegate statsd_increment(key, value, options), to: @statsd_module, as: :increment
      end
    end
  end
end
