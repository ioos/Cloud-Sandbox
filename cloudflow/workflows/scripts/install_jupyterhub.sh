#!/bin/env bash

  # install JupyterHub (https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md)

  # install npm 
  curl -fsSL https://rpm.nodesource.com/setup_16.x | sudo bash -
  sudo yum clean all && sudo yum makecache fast
  sudo yum install -y gcc-c++ make
  sudo yum install -y nodejs

  # install nginx
  sudo yum install -y nginx
  sudo cp system/jupyterhub.conf /etc/nginx/conf.d/jupyterhub.conf
  #TODO: Copy certs to correct place
  # /etc/ssl/star_rpsgroup_com.crt
  sudo systemctl enable nginx
  sudo systemctl start nginx

  # create virtual python environment
  sudo python3 -m venv /opt/jupyterhub/
  sudo /opt/jupyterhub/bin/python -m pip install --upgrade pip
  sudo /opt/jupyterhub/bin/python -m pip install wheel
  sudo /opt/jupyterhub/bin/python -m pip install setuptools_rust
  sudo /opt/jupyterhub/bin/python3 -m pip install ipywidgets
  sudo /opt/jupyterhub/bin/python -m pip install jupyterhub jupyterlab
  # allow interaction with conda-store (https://pypi.org/project/nb-conda-store-kernels/)
  #sudo /opt/jupyterhub/bin/python -m pip install nb_conda_store_kernels
  #sudo /opt/jupyterhub/bin/python -m nb_conda_store_kernels.install --enable

  # needed if running the notebook servers in the same environment
  sudo /opt/jupyterhub/bin/python -m pip install notebook
  sudo /opt/jupyterhub/bin/python -m pip install oauthenticator

  sudo -E env "PATH=$PATH" npm install -g configurable-http-proxy

  # start the proxy - this is done automatically by jupyterhub
  # configurable-http-proxy --default-target=http://localhost:8888

  # Copy config over
  # sudo curl "https://ioos-cloud-sandbox.s3.amazonaws.com/public/jupyterhub/jupyterhub_config.py" -o /opt/jupyterhub/jupyterhub_config.py
  sudo cp system/jupyterhub_config.py /opt/jupyterhub/jupyterhub_config.py

  # create systemd service
  sudo useradd --system --shell "/sbin/nologin" --home-dir "/etc/jupyter" --comment "JupytherHub system user" jupyter
  sudo chown jupyter:jupyter /opt/jupyterhub

  sudo mkdir -p /opt/jupyterhub/etc/systemd
  #sudo curl "https://ioos-cloud-sandbox.s3.amazonaws.com/public/jupyterhub/jupyterhub.service" -o /opt/jupyterhub/etc/systemd/jupyterhub.service
  sudo cp system/jupyterhub.service /opt/jupyterhub/etc/systemd/jupyterhub.service
  sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /usr/lib/systemd/system/jupyterhub.service
  sudo systemctl daemon-reload
  sudo systemctl enable jupyterhub
  sudo systemctl start jupyterhub

  # install conda
  rm /tmp/Anaconda3-2022.05-Linux-x86_64.sh
  curl "https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh" -o /tmp/Anaconda3-2022.05-Linux-x86_64.sh
  sudo bash /tmp/Anaconda3-2022.05-Linux-x86_64.sh -b -p /opt/conda
  sudo ln -sf /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

  # allows all users to make changes to conda environments (alternatively could give permissions to each user)
  sudo chmod -R a+rwX /opt/conda/envs

  # make kernel visible to JupyterHub
  sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/pangeo xarray zarr dask ipykernel --yes
  sudo /opt/jupyterhub/bin/jupyter kernelspec install /opt/conda/envs/python

  # To activate this environment, use
  #     $ conda activate /opt/conda/envs/python
  #
  # To deactivate an active environment, use
  #     $ conda deactivate

  # setup Python environment for users
  # Setting up users' own conda environments
  # On login they should run conda init or /opt/conda/bin/conda. 
  # They can then use conda to set up their environment, although they must also install ipykernel. 
  # Once done, they can enable their kernel using:

  # /path/to/kernel/env/bin/python -m ipykernel install --user --name 'python-my-env' --display-name "Python My Env"
  sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (default)"

  sudo /opt/conda/envs/python/bin/python -m ipykernel install --user --name 'python' --display-name "Python (default spec)"

  # ************** Work in progress ******************
  # TODO: configure sudospawner so we can run jupyterhub as jupyter user
  # sudo /opt/jupyterhub/bin/python -m pip install sudospawner