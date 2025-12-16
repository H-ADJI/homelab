# Network Setup

- DDNS using no-ip
- NAT / PAT forwarding to non-privileged ports
- Create shared container network :
  ```sh
  podman network create proxy
  ```
- firewall :
  ```sh
  # NOTE: block podman container network connections
  sudo ufw allow 22/tcp comment "SSH access"
  sudo ufw limit 22/tcp comment "SSH rate limiting"
  sudo ufw enable
  sudo ufw status
  ```
