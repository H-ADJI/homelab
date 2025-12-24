# Taskwarrior

## references

- [Reddit: Sync setup for taskwarrior 3.0](https://www.reddit.com/r/taskwarrior/comments/1bt1ixi/sync_setup_for_taskwarrior_30/)
- [The sync server for Taskchampion](https://github.com/GothenburgBitFactory/taskchampion-sync-server)
- [Syncing Tasks](https://taskwarrior.org/docs/sync/)

## Steps

- run taskchampion server

```sh

# TODO: find fix to pod attached to ssh user session
podman image pull ghcr.io/gothenburgbitfactory/taskchampion-sync-server

podman container run -d \
--name=taskchampion-sync-server \
-p 8080:8080 \
-e RUST_LOG=debug \
--mount type=volume,source=taskchampion_data,target=/var/lib/taskchampion-sync-server/data \
taskchampion-sync-server

```

- add taskrc sync config :

```ini
sync.server.url=http:\/\/{DOMAIN}
sync.server.client_id=019aef70-e855-75ad-8adc-744b67375036
sync.encryption_secret=0806
```
