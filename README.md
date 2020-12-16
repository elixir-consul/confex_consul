# ConfexConsul
This adapter allows [Confex](https://github.com/Nebo15/confex) to fetch dynamic configs from the [Consul KV Store](https://www.consul.io/docs/dynamic-app-config/kv).
And it will synchronize the config from Consul KV Store at a fixed interval. 

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
To synchronize config from Consul KV Store, we need to specify the refresh interval for the local cache by `local_cache_refresh_interval` in milliseconds, default to 1000.
```elixir
config :confex_consul,
  local_cache_refresh_interval: 5000
```
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

config :my_app,
  consul_config: {{:via, ConfexConsul}, "consul_my_key"},
```
