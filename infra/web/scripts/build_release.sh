#!/bin/bash
cd /tmp/shipvote_src
. /opt/asdf/asdf.sh

# build release
export MIX_ENV=prod
mix assets.deploy
mix release

# extract release
mkdir -p /opt/shipvote
mv _build/prod/rel/backend/* /opt/shipvote
