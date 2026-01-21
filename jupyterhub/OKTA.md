Okta (OIDC) integration for JupyterHub (NOS Cloud Sandbox)

Overview
--------
This repository includes optional Okta support for JupyterHub. The default behavior is unchanged (Google OAuth remains the default). To enable Okta-based login, set the environment variable AUTH_PROVIDER=okta and provide the Okta OIDC configuration via environment variables described below.

Why this approach
------------------
- No code changes are required to the authentication flow; configuration switches the authenticator at startup.
- Secrets (client secret) are read from environment variables — do not commit them to source control.
- Uses the existing `oauthenticator` library (GenericOAuthenticator) which supports standard OIDC flows.

Required Okta setup
-------------------
1. In the Okta Admin Console, create a new OIDC application (Web application).
2. Set the Redirect URI to: https://<JUPYTERHUB_HOST>/hub/oauth_callback
   - Example: https://jupyterhub.example.gov/hub/oauth_callback
3. In the application settings note the Client ID and Client Secret.
4. Decide which Okta authorization server you will use. Commonly this is the `default` server. The issuer URL typically looks like:
   - https://dev-123456.okta.com/oauth2/default

Environment variables
---------------------
Set these environment variables in the JupyterHub service environment (systemd, container, or deployment system):

- AUTH_PROVIDER=okta
- OKTA_CLIENT_ID=<your-client-id>
- OKTA_CLIENT_SECRET=<your-client-secret>  (keep secret)
- OKTA_ISSUER=https://<your-okta-domain>/oauth2/default
- (optional) OKTA_OAUTH_CALLBACK_URL=https://<JUPYTERHUB_HOST>/hub/oauth_callback

Notes and best practices
------------------------
- Keep the client secret out of source control. Use your deployment's secret manager or environment configuration.
- Make sure the Redirect URI in the Okta app exactly matches the callback URL.
- The implementation uses OpenID Connect scopes ['openid', 'profile', 'email']. Ensure your Okta application is allowed to provide profile and email claims.
- The default admin users are still configured in `scripts/system/jupyterhub_config.py`. You can modify admin users in that file or manage them separately.

Testing
-------
1. Set the environment variables on the host where JupyterHub will run.
2. Restart JupyterHub.
3. Visit the Hub URL and start the login flow — you should be redirected to Okta to authenticate.

If you need help mapping Okta groups or customizing the username mapping, we can extend the authenticator configuration while keeping the default flows intact.
