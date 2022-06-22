# JupyterHub Setup Instructions

The Cloud Sandbox setup will automatically install the JupyterHub dependencies. However, additional configuration is required in order to enable user authentication.

- JupyterHub install path: `/opt/jupyterhub`
- JupyterHub config: `/opt/jupyterhub/jupyterhub_config.py`
- Nginx config: `/etc/nginx/conf.d/default.conf`

## Helpful References

- [JupyterHub The Hard Way](https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md): Manual installation guide
- [JupyterHub Deployment Course](https://professorkazarinoff.github.io/jupyterhub-engr114/google_oauth/)

## Google Authentication and User Configuration

See [these instructions](https://oauthenticator.readthedocs.io/en/latest/getting-started.html#google-setup) for configuring your Google credentials with OAuthenticator. You will [create a key on the Google platform](https://developers.google.com/identity/protocols/oauth2) and modify the JupyterHub config to have the public key.

Once you've created the key, modify `/opt/jupyterhub/jupyterhub_config.py` values:

```
c.GoogleOAuthenticator.client_id = "your_client_id"
c.GoogleOAuthenticator.client_secret = "your_client_secret"
```

Next, fill out the username mapping to map the Google user to a local Unix user. For example:

```
c.Authenticator.username_map = { "example_user@gmail.com": "example_user" }
```

You can assign administrators using the `c.Authenticator.admin_users` setting:

```
c.Authenticator.admin_users = {'example_user@gmail.com'}
```

As long as `c.LocalAuthenticator.create_system_users = True` is enables, this user will be created automatically. For better user permission management, you can create this user ahead of time and assign permissions as needed. It is recommended to add all users to a common group for simpler permission management. 

```
sudo groupadd jupyterhub-users
usermod -g jupyterhub_users example_user
```

Then in the config, set this line to allow JupyterHub to use this group.

```
c.LocalAuthenticator.group_whitelist = ['jupyterhub-users']
```

## Setting up SSL/HTTPS

It is recommended to run Nginx as a reverse proxy to your JupyterHub instance. Nginx has already been installed as part of the Cloud Sandbox. Follow [these instructions](https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md#using-nginx) to configure Nginx. 

If you are planning on running SSL/HTTPS, you will need to generate your own certificates and point the Nginx configuration to those.

## Debugging

The JupyterHub logs are part of the `jupyterhub.service`. To inspect the logs:

```
sudo systemctl status jupyterhub.service
```

The JupyterHub service usually needs to be restarted for configuration changes to take effect. To restart the service:

```
sudo systemctl restart jupyterhub.service
```

