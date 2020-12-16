import Config

prefix = "test_confex_consul_#{:erlang.system_info(:otp_release)}_#{System.version()}/"

config :confex_consul,
  apps: [:confex_consul],
  enable_local_cache_auto_refresh: false,
  only_key: {{:via, ConfexConsul}, "#{prefix}/key_1"},
  key_with_default: {{:via, ConfexConsul}, "#{prefix}/key_2", "default_value_2"},
  type_with_key: {{:via, ConfexConsul}, :string, "#{prefix}/key_3"},
  type_with_key_with_default: {{:via, ConfexConsul}, :string, "#{prefix}/key_4", "default_value_4"}

config :consul_kv,
  consul_recv_timeout: 1000,
  consul_connect_timeout: 1000,
  consul_kv_address: "https://demo.consul.io/v1/kv"

config :logger, backends: []
