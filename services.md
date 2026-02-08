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

- `loginctl enable-linger $USER` to enable services even when logged of
- `systemctl --user daemon-reload` to refresh systemd config file
- `systemctl --user enable --now {NAME}.service` to enable a service
- `journalctl --user -u {NAME}.service` to inspect service logs

### references

- [podman systemd integration](https://mikebarkas.dev/start-podman-containers-systemd/)
