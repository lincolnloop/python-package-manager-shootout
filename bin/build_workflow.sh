#!/bin/bash
set -euf -o pipefail

cat templates/workflow_preamble.yml
for t in $(make tools); do
  TOOL=$t envsubst '$TOOL' < templates/workflow_tool.yml
done