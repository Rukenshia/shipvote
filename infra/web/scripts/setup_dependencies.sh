#!/bin/bash
yum install --allowerasing -y git gnupg2 gawk curl openssl-devel make automake autoconf ncurses-devel gcc g++
mkdir -p /opt/shipvote

# install asdf
git clone https://github.com/asdf-vm/asdf.git --branch v0.13.1 /opt/asdf

. /opt/asdf/asdf.sh

# install erlang + elixir
asdf plugin add erlang https://github.com/asdf-vm/asdf-erlang.git &
asdf plugin add elixir https://github.com/asdf-vm/asdf-elixir.git &
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git &
wait

asdf install erlang latest &
asdf install elixir latest &
asdf install nodejs latest &
wait

asdf global erlang latest
asdf global elixir latest
asdf global nodejs latest
