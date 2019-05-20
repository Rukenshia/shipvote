#!/bin/bash
set -ex

cd /root/shipvote/backend/_build/prod/rel/backend
tar -xzf backend.tar.gz
rm backend.tar.gz
systemctl restart shipvote
