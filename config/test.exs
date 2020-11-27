import Config

config :confex_consul,
  apps: [:confex_consul],
  only_key: {{:via, ConfexConsul}, "test_confex_consul/key_1"},
  key_with_default: {{:via, ConfexConsul}, "test_confex_consul/key_2", "default_value_2"},
  type_with_key: {{:via, ConfexConsul}, :string, "test_confex_consul/key_3"},
  type_with_key_with_default:
    {{:via, ConfexConsul}, :string, "test_confex_consul/key_4", "default_value_4"}

config :consul_kv,
  consul_recv_timeout: 1000,
  consul_connect_timeout: 1000,
  consul_kv_address: "https://demo.consul.io/v1/kv"
