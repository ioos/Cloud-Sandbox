#!/bin/env bash

  # install npm
  curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
  sudo yum clean all && sudo yum makecache fast
  sudo yum install -y gcc-c++ make # this is already installed in the image
  sudo yum install -y nodejs

  # install JupyterHub (https://github.com/jupyterhub/jupyterhub-the-hard-way/blob/HEAD/docs/installation-guide-hard.md)
  # create virtual python environment
  sudo python3 -m venv /opt/jupyterhub/
  /opt/jupyterhub/bin/python -m pip install jupyterhub
  sudo -E env "PATH=$PATH" npm install -g configurable-http-proxy
  /opt/jupyterhub/bin/python -m pip install jupyterlab notebook  # needed if running the notebook servers in the same environment

  # Copy config over
  sudo curl "https://ioos-cloud-sandbox.s3.amazonaws.com/public/jupyterhub/jupyterhub_config.py" -o /opt/jupyterhub/jupyterhub_config.py

  # created systemd service
  sudo mkdir -p /opt/jupyterhub/etc/systemd
  sudo curl "https://ioos-cloud-sandbox.s3.amazonaws.com/public/jupyterhub/jupyterhub.service" -o /opt/jupyterhub/etc/systemd/jupyterhub.service
  sudo ln -s /opt/jupyterhub/etc/systemd/jupyterhub.service /etc/systemd/system/jupyterhub.service
  sudo systemctl daemon-reload
  sudo systemctl enable jupyterhub.service
  sudo systemctl start jupyterhub.service

  # install conda
  curl "https://repo.anaconda.com/archive/Anaconda3-2022.05-Linux-x86_64.sh"
  sudo echo "yes /opt/conda" |./Anaconda3-2022.05-Linux-x86_64.sh # surpress -y and change default path 
  sudo ln -s /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

  # setup Python environment for users
  sudo /opt/conda/bin/conda create --prefix /opt/conda/envs/python ipykernel
  sudo /opt/conda/envs/python/bin/python -m ipykernel install --prefix=/opt/jupyterhub/ --name 'python' --display-name "Python (default)"
  
  # ************** Work in progress ******************
  sudo /opt/jupyterhub/bin/python -m pip install sudospawner

