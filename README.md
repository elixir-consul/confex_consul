# ConfexConsul
This adapter allows [Confex](https://github.com/Nebo15/confex) to fetch dynamic configs from the [Consul KV Store](https://www.consul.io/docs/dynamic-app-config/kv).
And it will synchronize the config from Consul KV Store at a configurable interval. 

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `confex_consul` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:confex_consul, "~> 0.1.0"}
  ]
end
```
## Usage
### Config for confex_consul
To synchronize config from Consul KV Store, we need to specify the refresh interval for the local cache by `local_cache_refresh_interval` in second, default to 60.
```elixir
config :confex_consul,
  local_cache_refresh_interval: 10
```
Note that the minimum value of `local_cache_refresh_interval` is 5 in order to preventing consul KV overloads.

We also need to tell confex_consul which apps' configs need to be refreshed by `apps` or `app`.
```elixir
config :confex_consul,
  apps: [:your_app1, :your_app2]

# Or
# config :confex_consul,
#   app: :your_app
```
Automatic refresh can be turned off by set `enable_local_cache_auto_refresh` to false, it's default to true.

Here is an example of config.exs
```elixir
use Mix.Config

config :confex_consul,
  apps: [:my_app],
  local_cache_refresh_interval: 120

config :my_app,
  consul_config: {{:via, ConfexConsul}, "consul_my_key"}
```

This adapter support to decode the value from Consul KV Store by add a prefix "decode: " for the key:
```elixir
config :my_app,
  consul_json_config: {
    {:via, ConfexConsul}, "decode: my_json_key", %{"default_value" => 1}
  }
```
Note that it only support JSON now(Consul KV supports JSON, HCL and YAML).

### Config for circuit_breaker
We can config circuit_breaker for Consul KV Store to reduce requests when Consul KV has issue, it will work for every key.
```elixir
config :confex_consul,
  circuit_breaker_switch: true,
  circuit_breaker_option: {{:standard, 1, 2_000}, {:reset, 3_000}}
```
For example, the above configuration means that if get an error response within 2 seconds, the next requests will not be sent. Reset after 3 seconds.  
You can find more option details in [fuse document](https://hexdocs.pm/fuse/).

### Config for consul_kv
The [consul_kv](https://github.com/elixir-consul/consul_kv) is a dependency library that sends requests to Consul KV Store. We can modify it's config:
```elixir
config :consul_kv,
  consul_recv_timeout: 1000,
  consul_connect_timeout: 1000,
  consul_kv_address: "https://demo.consul.io/v1/kv"
```

### Metrics
ConfexConsul use [telemetry](https://github.com/beam-telemetry/telemetry) to handle metrics and logs. You can find the details in `ConfexConsul.Telemetry`. 
