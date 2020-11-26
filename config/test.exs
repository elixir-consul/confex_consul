import Config

config :confex_consul,
  apps: [:confex_consul],
  consul_address: "https://demo.consul.io/v1/kv",
  consul_recv_timeout: 1000,
  consul_connect_timeout: 1000,
  test_name: {{:via, ConfexConsul}, "test_confex_consul_key"}
