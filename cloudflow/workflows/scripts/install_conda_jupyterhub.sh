#!/bin/env bash

  # install nginx
  sudo yum install -y nginx
  sudo cp system/jupyterhub.conf /etc/nginx/conf.d/jupyterhub.conf
  #TODO: Copy certs to correct place
  # /etc/ssl/star_rpsgroup_com.crt
  sudo systemctl enable nginx
  sudo systemctl start nginx

  # install conda
  rm /tmp/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh
  curl "Miniconda3-py310_23.1.0-1-Linux-x86_64.sh" -o /tmp/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh
  sudo bash /tmp/Miniconda3-py310_23.1.0-1-Linux-x86_64.sh -b -p /opt/conda
  sudo ln -sf /opt/conda/etc/profile.d/conda.sh /etc/profile.d/conda.sh

  # allows all users to make changes to conda environments (alternatively could give permissions to each user)
  sudo chmod -R a+rwX /opt/conda/envs
  sudo chown -R ec2-user/ec2-user /opt/conda # allow user to install here; one should not use 'sudo conda' commands

  # install JupyterHub under conda environment (https://jupyterhub.readthedocs.io/en/stable/quickstart.html)
  conda activate base
  conda install -yc conda-forge jupyterhub oauthenticator sudospawner # installs jupyterhub and proxy
  conda install -y jupyterlab notebook  # needed if running the notebook servers in the same environment

  # create system account that will run jupyterhub
  sudo useradd jupyter
  sudo groupadd jupyterhub
  sudo usermod jupyter -G jupyterhub

  sudo cp system/jupytersudoers /etc/sudoers.d/jupytersudoers

  # copy over configs
  sudo mkdir /etc/jupyterhub
  sudo chown jupyter /etc/jupyterhub
  sudo cp system/jupyterhub_config.py /opt/jupyterhub/jupyterhub_config.py

  # create the systemd service
  sudo setenforce 0 # may or may not be needed, disables SELinux to prevent issues with these steps
  sudo mkdir /etc/jupyterhub/service
  sudo cp system/jupyterhub.service /etc/jupyterhub/service/jupyterhub.service
  sudo chown -R jupyter /etc/jupyter/service
  sudo ln -s /etc/jupyterhub/service/jupyterhub.service /etc/systemd/system/jupyterhub.service
  sudo systemctl daemon-reload
  sudo systemctl enable jupyterhub
  sudo systemctl start jupyterhub