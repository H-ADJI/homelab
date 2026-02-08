# Server setup

- update && upgrade :
  `sudo apt update && sudo apt upgrade -y`
- install packages :
  `sudo apt intall -y fzf nvim tmux`
- add nvim options :

  ```lua
  vim.o.ignorecase = true
  vim.o.smartcase = true
  vim.o.cursorline = true
  ```

- fzf setup :
  `sudo apt install -y fzf`
  `git clone --depth 1 --branch 0.44.0 https://github.com/junegunn/fzf.git`
- add to .bashrc
  ```sh
    source fzf/shell/completion.bash
    source fzf/shell/key-bindings.bash
    PATH=$PATH:"$HOME/.config/scripts"
    alias c="clear"
    alias e="nvim"
    alias vim="nvim"
    alias update="sudo apt update && sudo apt upgrade -y"
    alias ggl="git pull"
    alias lab="cd ~/.config/homelab"
    alias conf="cd ~/.config"
    alias ..="cd .."
    alias enable_service="systemctl --user enable --now"
    alias restart_service="systemctl --user restart"
    alias journal="journalctl --user -f -u"
  ```
- `ssh-copy-id -fi ~/.ssh/{SSH_PUB_KEY} {USER}@{IP}`
- add this to /etc/ssh/sshd_config

```ini
    PasswordAuthentication no
    PermitEmptyPasswords no
    ChallengeResponseAuthentication no
    KerberosAuthentication no
    GSSAPIAuthentication no
    PermitRootLogin no
    MaxAuthTries 3
    LoginGraceTime 20
    AllowAgentForwarding no
    AllowTcpForwarding no
    PermitTunnel no
    # PermitUserEnvironment no
    X11Forwarding no
    DebianBanner no
    AllowUsers khalil
    ClientAliveInterval 300
    ClientAliveCountMax 0
    MaxSessions 2

```

- reload ssh deamon
  `sudo systemctl reload ssh.service`
- check new configuration is applied
  `sudo sshd -T`
- configure ufw :

  ```sh
  # TODO: fail2ban
  # TODO: expand logical volume
  ```

## Network Setup

- DDNS using ddclient
- NAT / PAT forwarding to non-privileged ports
  - 80:8000
  - 443:8443
  - 22:22

- port forwarding for dns:

```bash
# For external incoming requests
sudo iptables -t nat -A PREROUTING -i enp3s0 -p udp --dport 53 -j REDIRECT --to-port 5300
sudo iptables -t nat -A PREROUTING -i enp3s0 -p tcp --dport 53 -j REDIRECT --to-port 5300
# For requests originating from the server itself
sudo iptables -t nat -A OUTPUT -p udp --dport 53 -j REDIRECT --to-port 5300
sudo iptables -t nat -A OUTPUT -p tcp --dport 53 -j REDIRECT --to-port 5300
sudo netfilter-persistent save
```
