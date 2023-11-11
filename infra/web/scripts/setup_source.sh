#!/bin/bash

# set up shipvote repo
cd /tmp/shipvote_src

# install dependencies
. /opt/asdf/asdf.sh
export MIX_ENV=prod
rm -rf _build
mix local.hex --force
mix local.rebar --force
mix clean --deps --all
mix deps.get
mix deps.compile appsignal --include-children
cat _build/prod/lib/appsignal/priv/install.report

