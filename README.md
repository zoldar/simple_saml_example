# SimpleSamlExample

Minimal example of SAML SSO based on [simple_saml](https://github.com/MBXSystems/simple_saml)
and [xml_builder](https://github.com/joshnuss/xml_builder).

## Setup

```
mix deps.get
docker-compose up -d
curl http://localhost:8080/simplesaml/module.php/saml/idp/certs.php/idp.crt -o priv/idp.crt
iex -S mix phx.server
```

## Usage

- Open http://localhost:4000/saml/auth/signin/dummy-simplesaml in the browser
- Provide "user1" or "user2" for username and "password" for password in IdP login form
- Observe printout of parsed assertion in elixir console

## Implementation

See the commit titled "Implement minimal SAML example" for implementation.
