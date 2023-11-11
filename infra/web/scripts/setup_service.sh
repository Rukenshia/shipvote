#!/bin/bash
mv /tmp/shipvote.service /etc/systemd/system/shipvote.service
mv /tmp/shipvote.env /opt/shipvote/shipvote.env
systemctl daemon-reload
systemctl enable shipvote
