# Network Setup

- DDNS using no-ip
- NAT / PAT forwarding
- ufw allow 22 - 80 - 443
- route privileged ports :
  ```sh
  sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8000
  sudo iptables -t nat -A PREROUTING -p tcp --dport 443 -j REDIRECT --to-port 8443
  ```
- Create shared container network :
  ```sh
  podman network create proxy
  ```
