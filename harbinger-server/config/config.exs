use Mix.Config

case System.get_env("SENTRY_DSN") do
  nil -> nil
  dsn ->
    config :sentry,
      dsn: dsn,
      environment_name: Mix.env(),
      included_environments: [:prod],
      enable_source_code_context: true,
      root_source_code_paths: [File.cwd!()],
      hackney_opts: [pool: :sentry_pool, ssl_options: [{:versions, [:'tlsv1.2']}]]

    config :logger,
      backends: [:console, Sentry.LoggerBackend]
end
