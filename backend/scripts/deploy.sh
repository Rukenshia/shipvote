#!/bin/bash
set -ex
export MIX_ENV=prod

cd /root/shipvote/backend
git pull
mix deps.get && \
mix ecto.migrate && \
cd assets && npm ci && npm run deploy && cd .. && \
mix phx.digest && \
sudo systemctl restart shipvote