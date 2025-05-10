defmodule SimpleSamlExampleWeb.Router do
  use SimpleSamlExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {SimpleSamlExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :saml do
    plug SimpleSamlExampleWeb.Plugs.SecureSAML
    plug :fetch_session
  end

  pipeline :saml_auth do
    plug Plug.CSRFProtection, with: :clear_session
  end

  scope "/saml", SimpleSamlExampleWeb do
    pipe_through :saml

    scope "/auth" do
      pipe_through :saml_auth

      get "/signin/:idp_id", SAMLController, :signin
    end

    post "/sp/consume/:idp_id", SAMLController, :consume

    post "/csp-report", SAMLController, :csp_report
  end

  scope "/", SimpleSamlExampleWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Other scopes may use custom stacks.
  # scope "/api", SimpleSamlExampleWeb do
  #   pipe_through :api
  # end
end
