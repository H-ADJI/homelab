#!/bin/env bash
HOMELAB="$HOME/homelab"
cd "$HOMELAB" || exit 1
git pull
echo "Applied"
