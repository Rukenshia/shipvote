#!/bin/bash
set -ex
export MIX_ENV=prod

cd /root/shipvote/backend
git pull
mix deps.get && \
mix ecto.migrate && \
mix phx.digest && \
sudo systemctl restart shipvote