#!/bin/bash
set -ex
export MIX_ENV=prod

cd /root/shipvote/backend
git pull
mix deps.get && \
mix ecto.migrate && \
sudo systemctl restart shipvote