defmodule SimpleSamlExampleWeb.SAMLController do
  use SimpleSamlExampleWeb, :controller

  require Logger

  @deflate "urn:oasis:names:tc:SAML:2.0:bindings:URL-Encoding:DEFLATE"

  plug :get_idp when action in [:signin, :consume]

  def signin(conn, _params) do
    config = Application.fetch_env!(:simple_saml_example, :saml)
    sp = Keyword.fetch!(config, :service_provider)
    idp = Map.fetch!(conn.private, :saml_idp)
    relay_state = gen_id()
    id = "saml_flow_#{gen_id()}"

    auth_xml = generate_auth_request(sp.entity_id, id, DateTime.utc_now())

    params = %{
      "SAMLEncoding" => @deflate,
      "SAMLRequest" => Base.encode64(:zlib.zip(auth_xml)),
      "RelayState" => relay_state
    }

    url = %URI{} = URI.parse(idp.signin_url)

    query_string =
      (url.query || "")
      |> URI.decode_query()
      |> Map.merge(params)
      |> URI.encode_query()

    url = URI.to_string(%{url | query: query_string})

    conn
    |> configure_session(renew: true)
    |> put_session("target_url", "/")
    |> put_session("relay_state", relay_state)
    |> put_session("idp_id", idp.id)
    |> redirect(external: url)
  end

  def consume(conn, _params) do
    idp = Map.fetch!(conn.private, :saml_idp)

    saml_response = conn.body_params["SAMLResponse"]
    relay_state = conn.body_params["RelayState"] |> safe_decode_www_form()
    target_url = get_session(conn, "target_url")

    with :ok <- validate_authresp(conn, relay_state),
         {:ok, {root, assertion}} = SimpleSaml.parse_response(saml_response),
         {:ok, cert} = X509.Certificate.from_pem(idp.certificate),
         public_key = X509.Certificate.public_key(cert),
         :ok <- SimpleSaml.verify_and_validate_response(root, assertion, public_key) do
      conn
      |> configure_session(renew: true)
      |> put_session("saml_assertion", assertion)
      |> tap(fn _conn -> IO.inspect(assertion, label: :ASSERTION) end)
      |> redirect(to: target_url)
    else
      {:error, reason} ->
        send_resp(conn, 403, "access_denied #{inspect(reason)}")
    end
  end

  def csp_report(conn, _params) do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    Logger.error(body)
    conn |> send_resp(200, "OK")
  end

  defp safe_decode_www_form(nil), do: ""
  defp safe_decode_www_form(data), do: URI.decode_www_form(data)

  defp get_idp(conn, _config) do
    idp_id = conn.params["idp_id"]
    config = Application.fetch_env!(:simple_saml_example, :saml)
    idps = Keyword.fetch!(config, :identity_providers)
    idp = Enum.find(idps, &(&1[:id] == idp_id))

    if idp do
      conn |> put_private(:saml_idp, idp)
    else
      conn |> send_resp(403, "invalid_request unknown IdP") |> halt()
    end
  end

  defp generate_auth_request(issuer_id, id, timestamp) do
    XmlBuilder.generate(
      {:"samlp:AuthnRequest",
       [
         "xmlns:samlp": "urn:oasis:names:tc:SAML:2.0:protocol",
         ID: id,
         Version: "2.0",
         IssueInstant: DateTime.to_iso8601(timestamp)
       ], [{:"saml:Issuer", ["xmlns:saml": "urn:oasis:names:tc:SAML:2.0:assertion"], issuer_id}]}
    )
  end

  defp validate_authresp(conn, relay_state) do
    %{id: idp_id} = conn.private[:saml_idp]
    rs_in_session = get_session(conn, "relay_state")
    idp_id_in_session = get_session(conn, "idp_id")
    url_in_session = get_session(conn, "target_url")

    cond do
      rs_in_session == nil || rs_in_session != relay_state ->
        {:error, :invalid_relay_state}

      idp_id_in_session == nil || idp_id_in_session != idp_id ->
        {:error, :invalid_idp_id}

      url_in_session == nil ->
        {:error, :invalid_target_url}

      true ->
        :ok
    end
  end

  defp gen_id() do
    24 |> :crypto.strong_rand_bytes() |> Base.url_encode64()
  end
end
