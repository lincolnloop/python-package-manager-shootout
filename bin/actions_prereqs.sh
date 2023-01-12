#!/bin/bash
set -euf -o pipefail

# sentry dependencies
sudo apt-get update -qq
sudo apt-get install -y libxmlsec1-dev librdkafka-dev
# benchmark setup
pip --disable-pip-version-check --no-cache-dir install mdtable
mkdir -p timings
make requirements.txt