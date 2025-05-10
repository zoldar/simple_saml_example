# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :simple_saml_example,
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :simple_saml_example, SimpleSamlExampleWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: SimpleSamlExampleWeb.ErrorHTML, json: SimpleSamlExampleWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SimpleSamlExample.PubSub,
  live_view: [signing_salt: "6xdJAgMu"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure SAML SSO Identity Providers
config :simple_saml_example, :saml,
  service_provider: %{
    entity_id: "http://localhost:4000"
  },
  identity_providers: [
    %{
      id: "dummy-simplesaml",
      signin_url: "http://localhost:8080/simplesaml/saml2/idp/SSOService.php",
      entity_id: "http://localhost:8080/simplesaml/saml2/idp/metadata.php",
      certificate: File.read!("priv/idp.crt")
    }
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
