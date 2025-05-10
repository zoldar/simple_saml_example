defmodule SimpleSamlExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SimpleSamlExampleWeb.Telemetry,
      {DNSCluster,
       query: Application.get_env(:simple_saml_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: SimpleSamlExample.PubSub},
      # Start a worker by calling: SimpleSamlExample.Worker.start_link(arg)
      # {SimpleSamlExample.Worker, arg},
      # Start to serve requests, typically the last entry
      SimpleSamlExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SimpleSamlExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SimpleSamlExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
