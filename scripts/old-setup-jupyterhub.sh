#!/usr/bin/env bash

# https://jupyterhub.readthedocs.io/en/stable/quickstart.html#prerequisites
# https://docs.npmjs.com/downloading-and-installing-node-js-and-npm

# https://github.com/nvm-sh/nvm#installing-and-updating
# Install nodejs/npm using nvm
# If the environment variable $XDG_CONFIG_HOME is present, it will place the nvm files there.
# 
# You can add --no-use to the end of the above script (...nvm.sh --no-use) to postpone using nvm 
# until you manually use it.
# 
# You can customize the install source, directory, profile, and version using the NVM_SOURCE, 
# NVM_DIR, PROFILE, and NODE_VERSION variables. Eg: curl ... | NVM_DIR="path/to/nvm". Ensure 
# that the NVM_DIR does not contain a trailing slash.
# 
# curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Install nvm

export NVM_DIR=/save/opt/nvm
[ -d $NVM_DIR ] && mkdir -p $NVM_DIR

#curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

echo "Can add --no-use to ~/.bashrc to only use nvm it when manually used"
echo "e.g. [ -s \"$NVM_DIR/nvm.sh\" ] && \. \"$NVM_DIR/nvm.sh\" --no-use  # This loads nvm"

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# nvm install node
nvm use node


