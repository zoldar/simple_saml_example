defmodule SimpleSamlExampleWeb.Plugs.SecureSAML do
  @moduledoc """
  SAML security plug
  """

  import Plug.Conn

  @csp """
       default-src 'none';
       script-src 'self' 'report-sample';
       img-src 'self' 'report-sample';
       report-uri /saml/csp-report;
       report-to csp-report-endpoint
       """
       |> String.replace("\n", " ")

  def init(_) do
    []
  end

  def call(conn, _opts) do
    conn
    |> register_before_send(fn connection ->
      connection
      |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
      |> put_resp_header("pragma", "no-cache")
      |> put_resp_header("x-frame-options", "SAMEORIGIN")
      |> put_resp_header("reporting-endpoints", "csp-report-endpoint=\"/saml/csp-report\"")
      |> put_resp_header("content-security-policy", @csp)
      |> put_resp_header("x-xss-protection", "1; mode=block")
      |> put_resp_header("x-content-type-options", "nosniff")
    end)
  end
end
