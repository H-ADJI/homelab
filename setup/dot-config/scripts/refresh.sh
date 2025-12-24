#!/bin/env bash
HOMELAB="$HOME/homelab"
cd "$HOMELAB" || exit 1
git pull
cp -r "$HOMELAB"/setup/dot-config/* "$HOME/.config"
sudo cp -r "$HOMELAB"/setup/etc/* /etc
echo "Applied"
