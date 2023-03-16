# JupyterHub Setup Instructions

The Cloud Sandbox setup will automatically install the JupyterHub dependencies. However, additional configuration is required in order to enable user authentication. JupyterHub is installed in the `base` conda environment by default. 

- Conda install: `/opt/conda`
- JupyterHub config: `/etc/jupyterhub/jupyterhub_config.py`
- JupyterHub run script: `/etc/jupyterhub/runJupyterhub.sh`
- Nginx config: `/etc/nginx/conf.d/jupyterhub.conf`

## Helpful References

- [How-to Install JupyterHub Using Conda Without Running as Root and Make It a Service](https://medium.com/swlh/how-to-install-jupyterhub-using-conda-without-runing-as-root-and-make-it-a-service-59b843fead12)
- [JupyterHub The Hard Way](https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md): Manual installation guide
- [JupyterHub Deployment Course](https://professorkazarinoff.github.io/jupyterhub-engr114/google_oauth/)

## Google Authentication

See [these instructions](https://oauthenticator.readthedocs.io/en/latest/getting-started.html#google-setup) for configuring your Google credentials with OAuthenticator. You will [create a key on the Google platform](https://developers.google.com/identity/protocols/oauth2) and modify the JupyterHub config to have the public key.

Once you've created the key, modify `/etc/jupyterhub/jupyterhub_config.py` values:

```
c.GoogleOAuthenticator.client_id = "your_client_id"
c.GoogleOAuthenticator.client_secret = "your_client_secret"
```

## Adding Users

First, create the Linux user account if it doesn't already exist on the system.

```
sudo useradd example_user
sudo usermod -aG wheel example_user
```

Next, fill out the username mapping to map the Google user to a local Unix user. For example:

```
c.Authenticator.username_map = { "example_user@gmail.com": "example_user" }
```

Optionally, you can assign administrators using the `c.Authenticator.admin_users` setting:

```
c.Authenticator.admin_users = {'example_user@gmail.com'}
```

## Setting up Conda environment

Once the user account is created, that user will need to log in to the machine to set up their Conda environment.

First, if you haven't already, set a password for the user account to login with:
```
sudo passwd example_user
```
Then login as that user: `su example_user`

Run `conda init`

After creating the new Conda environment, run these commands to make it visible to the base kernel:

```
conda install ipykernel
ipython kernel install --user --name=<any_name_for_kernel>
```


## Setting up SSL/HTTPS

It is recommended to run Nginx as a reverse proxy to your JupyterHub instance. 
Nginx is installed as part of the Cloud Sandbox installation but additional configuration is likely needed for custom deployments. 
Follow [these instructions](https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md#using-nginx) to configure Nginx. 

If you are planning on running SSL/HTTPS, you will need to generate your own certificates and point the Nginx configuration to those.

The Nginx configuration is located in `/etc/nginx/conf.d/`

## Debugging

The JupyterHub logs are part of the `jupyterhub.service`. To inspect the logs:

```
sudo systemctl status jupyterhub.service
```

The JupyterHub service usually needs to be restarted for configuration changes to take effect. To restart the service:

```
sudo systemctl restart jupyterhub.service
```
