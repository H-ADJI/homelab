# Services

- steps :
  - create compose file
  - create systemd service file

## Podman

- Create shared container network :
  ```sh
  podman network create proxy
  ```

### references

- [podman systemd integration](https://mikebarkas.dev/start-podman-containers-systemd/)

## Systemd

- `sudo loginctl enable-linger username` to enable services even when logged of
- `systemctl --user daemon-reload` to refresh systemd config file
- `systemctl --user enable --now {NAME}.service` to enable a service
- `journalctl --user -u {NAEM}.service` to inspect service logs

### references

- [podman systemd integration](https://mikebarkas.dev/start-podman-containers-systemd/)

## Caddy

### Setup

- configure using Caddyfile

## Grafana

## adguard

## Taskwarrior

### Setup

- add taskrc sync client config :

```ini
sync.server.url=http:\/\/{DOMAIN}
sync.server.client_id=019aef70-e855-75ad-8adc-744b67375036
sync.encryption_secret=0806
```

### references

- [Reddit: Sync setup for taskwarrior 3.0](https://www.reddit.com/r/taskwarrior/comments/1bt1ixi/sync_setup_for_taskwarrior_30/)
- [The sync server for Taskchampion](https://github.com/GothenburgBitFactory/taskchampion-sync-server)
- [Syncing Tasks](https://taskwarrior.org/docs/sync/)

## Jellyfin

### references

- [official website](https://jellyfin.org/)
