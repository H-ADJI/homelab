#!/bin/env bash
HOMELAB="$HOME/homelab"
cd "$HOMELAB" || exit 1
git pull
# TODO: only sync new files
cp -r "$HOMELAB"/setup/dot-config/* "$HOME/.config"
echo "Applied"
