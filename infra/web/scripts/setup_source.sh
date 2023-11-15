#!/bin/bash

# set up shipvote repo
cd /tmp/shipvote_src

# install dependencies
. /opt/asdf/asdf.sh
export MIX_ENV=prod

rm -rf ./_build ./deps

mix local.hex --force
mix local.rebar --force
mix deps.get
mix deps.compile appsignal --include-children
cat _build/prod/lib/appsignal/priv/install.report
