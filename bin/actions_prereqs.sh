#!/bin/bash
set -euf -o pipefail

# sentry dependencies
wget -qO - https://packages.confluent.io/deb/7.2/archive.key | sudo apt-key add -
sudo add-apt-repository "deb https://packages.confluent.io/clients/deb $(lsb_release -cs) main"
sudo apt-get update -qq
sudo apt-get install -y libxmlsec1-dev librdkafka-dev
# benchmark setup
pip --disable-pip-version-check --no-cache-dir install mdtable
mkdir -p timings
make requirements.txt