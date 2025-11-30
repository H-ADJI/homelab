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
  ```bash
  source fzf/shell/completion.bash
  source fzf/shell/key-bindings.bash
  alias c="clear"
  alias e="nvim"
  alias vim="nvim"
  alias update="sudo apt update && sudo apt upgrade -y"
  ```
- ssh-copy-id
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
```

- sudo sshd -T to check changed values
