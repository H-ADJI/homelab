#!/bin/env bash
HOMELAB="$HOME/homelab"
cd "$HOMELAB" || exit 1
git pull
cp -r "$HOMELAB"/setup/* "$HOME/.config"
echo "Applied"
cd "$HOME/.config/homelab" || exit 1
