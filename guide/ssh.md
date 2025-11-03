# SSH Hardening

## System update and essential packages

**Goal:** bring the server up to date and install tools we will use for security.

**Commands:**

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y vim curl git ufw fail2ban unattended-upgrades libpam-google-authenticator
```

**Explanation & rationale:**

- `apt update && apt upgrade -y` ensures you have current security fixes. Many SSH vulnerabilities are patched through OS updates.
- `vim`, `curl`, `git` are convenience tools available on most admin workflows.
- `ufw` (Uncomplicated Firewall) gives a simple interface to configure firewall rules.
- `fail2ban` blocks repeated login attempts and reduces brute-force risk.
- `unattended-upgrades` optionally helps with automatic security updates (explained in section 12).
- `libpam-google-authenticator` is used only if you choose to enable local TOTP 2FA.

**Notes:**

- Keep `unattended-upgrades` conservative in a homelab — it can reboot on kernel updates unexpectedly unless configured not to.

---

## 3. Create a non-root admin user

**Goal:** avoid logging in as `root` and use least privilege.

**Commands:**

```bash
sudo adduser yourusername
sudo usermod -aG sudo yourusername
```

**Detailed explanation:**

- Running services or daily tasks as `root` is dangerous. If an attacker gains access as `root`, they control the whole server.
- Creating an unprivileged user who is a member of the `sudo` group preserves the ability to perform administrative actions while keeping interactive sessions tied to a named user.

**Tips:**

- Choose a non-obvious username (but make it memorable). Use strong local passwords for `sudo` prompts if password auth remains enabled temporarily.

---

## 4. Generate and install SSH keys (client-side and server-side)

**Goal:** use public key authentication (strong, phishing-resistant) rather than passwords.

**On your client (laptop) generate keys:**

```bash
ssh-keygen -t ed25519 -C "yourname@homelab"
# optionally add a secure passphrase
```

**Why `ed25519`?**

- It is modern, short keys, fast, and has strong crypto properties; generally preferred to RSA unless you have compatibility constraints.

**Copy the public key to your server:**

```bash
ssh-copy-id yourusername@server_ip
```

OR manually:

```bash
cat ~/.ssh/id_ed25519.pub | ssh yourusername@server_ip 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh'
```

**Detailed rationale:**

- `authorized_keys` should be writeable only by the user. `chmod 600` is mandatory otherwise `sshd` will ignore the file.
- If `ssh-copy-id` is not available, the manual command above ensures directory permissions are correct.

**Passphrases:**

- Add a passphrase to your private key for defense in depth. Consider using an SSH agent (`ssh-agent`, `gpg-agent`) on your client to avoid typing the passphrase every single time.

**Managing multiple keys:**

- Use `~/.ssh/config` on the client to select specific identity files per-host.

---

## 5. Harden the SSH daemon (`sshd`) — explained and with recommended config

**Goal:** reduce attack surface and enforce strong cryptography.

**Important:** Back up the current config before editing.

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
```

**Open the file for editing:**

```bash
sudo vim /etc/ssh/sshd_config
```

**Recommended directives (with inline explanation):**

```text
# LISTENING
# Restrict to specific interfaces if you want (e.g., your LAN IP) instead of 0.0.0.0
ListenAddress 0.0.0.0
# Protocol 2 is the only supported protocol; modern OpenSSH enforces this already
Protocol 2

# AUTHENTICATION
PermitRootLogin no                     # disable root login entirely
PasswordAuthentication no              # force publickey auth only
ChallengeResponseAuthentication no     # disable keyboard-interactive unless using 2FA
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

# USER RESTRICTIONS
AllowUsers yourusername                # limit which unix users can log in
# Alternatively, use AllowGroups sshusers

# BRUTE-FORCE / TIMEOUTS
LoginGraceTime 30                      # shorter time to authenticate
MaxAuthTries 3                         # limit auth attempts
MaxSessions 2                          # concurrent channels per connection

# CONNECTION KEEPALIVE
ClientAliveInterval 300                # server checks client every 300s
ClientAliveCountMax 2                  # disconnect after missed responses

# FORWARDING & TUNNELS (reduce if unused)
AllowTcpForwarding no                  # set to yes only if you need reverse tunnels
PermitTunnel no
X11Forwarding no

# CRYPTOGRAPHY (prefer modern KEX/ciphers/MACs)
KexAlgorithms curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# LOGGING
LogLevel VERBOSE

# Include additional config fragments
Include /etc/ssh/sshd_config.d/*.conf
```

**Notes on cryptographic directives:**

- Modern Ubuntu/OpenSSH already uses strong defaults; the explicit lists above force only strong options. If you use some older SSH clients, you might need to allow additional algorithms temporarily.
- `chacha20-poly1305` is a good, fast AEAD cipher and widely supported.

**AllowUsers vs AllowGroups:**

- `AllowUsers` explicitly lists allowed users. If you expect to add more admin users, create a group (eg. `sshadmins`) and use `AllowGroups` instead.

**Why disable forwarding and X11 by default?**

- Both forwarding and X11 are legitimate features but increase attack surface. Enable only when required for a specific workflow.

---

## 6. Apply and test the configuration safely

**Important safety procedure:** always test `sshd` reconfiguration from a separate session so you do not lock yourself out.

**Steps:**

1. From your current SSH session, open a second terminal window (or tab).
2. In the second terminal, try to start a new SSH connection:

   ```bash
   ssh -i ~/.ssh/id_ed25519 yourusername@server_ip
   ```

3. If it connects, apply the new config and restart `sshd`:

   ```bash
   sudo systemctl restart ssh
   ```

4. If the new session stays alive and you can authenticate, the config is safe.

**If something breaks:**

- Restore the backup:

```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh
```

- If you have console access (physical or via provider KVM), use it to fix SSH.

---

## 7. Firewall (UFW) configuration

**Goal:** permit only desired incoming traffic and block the rest.

**Basic UFW commands:**

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
# allow standard SSH
sudo ufw allow OpenSSH
sudo ufw enable
sudo ufw status verbose
```

**If you changed SSH port to 2222:**

```bash
sudo ufw allow 2222/tcp
sudo ufw delete allow OpenSSH # if you want to remove default 22 rule
```

**Explanation:**

- Default-deny is the safest stance: only open the ports you actually need for homelab services.
- Leaving `allow outgoing` open ensures the server can reach updates, remote APIs, etc.

**Tip for remote WAN access:**

- If your server is behind a router, prefer forwarding a non-standard port and combine that with port knocking, VPN, or SSH via an access-only tunnel service (Tailscale/Cloudflare/Twingate).

---

## 8. Fail2Ban setup and explanation

**Goal:** automatically block IPs that show malicious activity patterns (repeated failed logins).

**Install & copy config:**

```bash
sudo apt install fail2ban -y
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

**Recommended `jail.local` snippet (sshd):**

```ini
[sshd]
enabled = true
port = ssh
maxretry = 3
findtime = 600
bantime = 3600
# ignoreip = 127.0.0.1/8 ::1 192.168.1.0/24  # add your local trusted subnets
```

**Explanation of parameters:**

- `maxretry=3`: ban after 3 failed attempts within `findtime` seconds.
- `findtime=600`: the time window to count failures.
- `bantime=3600`: how long the ban lasts (1 hour). Use permanent ban only for repeat offenders.

**Testing Fail2Ban:**

- Use `fail2ban-client status sshd` to see which jails and banned IPs exist.

**Important note:**

- If you use a dynamic IP or cloud provider, be careful with `bantime` and `ignoreip` to avoid accidental lockout.

---

## 9. Optional enhancements and why you might use them

### a) Change SSH port (obscurity only)

**Commands**

```bash
# edit /etc/ssh/sshd_config -> Port 2222
sudo ufw allow 2222/tcp
sudo systemctl restart ssh
```

**Why:** Reduces noise from automated bots scanning port 22. **Not** a real security control — combine with other controls.

**Risks:** If you forget to allow the new port, you may lock yourself out. Always test in a second session.

---

### b) Two-Factor Authentication (TOTP based)

**When to use:** If you want an extra layer beyond SSH keys (useful for shared keys or additional protection).

**Install & configure** (local TOTP using `libpam-google-authenticator`):

1. On the server, for the user(s) who will use 2FA, run:

```bash
google-authenticator
```

Follow the interactive prompts; save the QR code or secret in your authenticator app.

```
2. Edit `/etc/pam.d/sshd` and add near the top:
```

auth required pam_google_authenticator.so nullok

```
- `nullok` allows users without a TOTP setup to log in — omit if you require TOTP for everyone.

3. In `/etc/ssh/sshd_config`:
```

ChallengeResponseAuthentication yes
AuthenticationMethods publickey,keyboard-interactive

````
4. Restart SSH and test carefully.

**Explanation:**
- `AuthenticationMethods publickey,keyboard-interactive` forces a user to present both a valid SSH key and then respond to a TOTP prompt.

**Caveats:**
- If you lock out your authenticator or lose the seed, recovery requires console access or another administrative account. Consider offline recovery codes or multiple admin accounts.

---

### c) Use a VPN or mesh (recommended for remote WAN access)
**Options:** Tailscale, WireGuard, Cloudflare Zero Trust Tunnel, Twingate.

**Why prefer these:**
- They remove the need to expose SSH to the open internet. If you use Tailscale, for instance, your server is only reachable via the encrypted overlay network.

**Example (Tailscale):**
- Install Tailscale on server and client, login with your identity, then SSH using the Tailscale IP/name.
- Then in UFW, restrict SSH only to the Tailscale interface.

```bash
# block SSH on WAN, allow on tailscale0
sudo ufw deny in on eth0 to any port 22 proto tcp
sudo ufw allow in on tailscale0 to any port 22 proto tcp
````

**Explanation:**

- This is a strong architectural control: even if the server is reachable on the internet, port 22 is not forwarded or open.

---

### d) Forced commands / restricted shells for service accounts

**Use case:** when you create SSH accounts for automated processes (git, backup agents), restrict what they can do.

**Authorized_keys forced command header:**

```
command="/usr/local/bin/only-allowed-action",no-pty,no-agent-forwarding,no-port-forwarding ssh-ed25519 AAAA... user@host
```

**Explanation:**

- This prevents interactive shells and restricts the key to a single action. Good for CI systems or webhook consumers.

---

## 10. Client-side hardening

**Goal:** enforce strong crypto and stability from the client.

**Add to `~/.ssh/config`:**

```text
Host homelab
    HostName server_ip_or_hostname
    User yourusername
    Port 2222   # if you changed it
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    ServerAliveInterval 60
    ServerAliveCountMax 2
    Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
    MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
    KexAlgorithms curve25519-sha256@libssh.org
```

**Why:**

- `IdentitiesOnly yes` avoids `ssh` trying many keys and being blocked due to `MaxAuthTries`.
- `ServerAliveInterval` keeps the connection alive and detects broken networks.

---

## 11. Logging, monitoring and auditing

**Commands:**

- View recent SSH logs:

```bash
sudo journalctl -u ssh -n 200 --no-pager
# or
sudo journalctl -u ssh --since "2 days ago"
```

- See last logins:

```bash
last -a | head -n 40
```

**What to look for:**

- Repeated authentication failures from unknown IPs
- Logins at odd hours
- New users created unexpectedly

**Optional integrations:**

- Ship logs to a central log collector (ELK, Loki, Papertrail) for long-term storage and analysis.

---

## 12. Automated maintenance and upgrades

**Goal:** keep the system patched without excessive surprise reboots.

**Install & configure unattended upgrades**

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

**Advanced configuration:** edit `/etc/apt/apt.conf.d/50unattended-upgrades` to control which packages and whether automatic reboots are allowed.

**Advice:**

- In a homelab, enable security updates but disable automatic reboots or restrict reboots to a maintenance window.

---

## 13. Test checklist and troubleshooting

**Pre-deployment checklist (must pass before you consider SSH hardened):**

- [ ] SSH login works using key only (no password).
- [ ] Root login via SSH is disabled.
- [ ] UFW is enabled and only intended ports are open.
- [ ] Fail2Ban is running and the `sshd` jail is enabled.
- [ ] `sshd_config` backup exists.
- [ ] You have an alternate admin account or console access plan.

**Troubleshooting common issues:**

- `Permission denied` after adding key: check ownership and permissions of `~/.ssh` (700) and `~/.ssh/authorized_keys` (600).
- `sshd` refuses to start after config change: check `sudo sshd -t` for syntax errors and `sudo journalctl -u ssh -b` for logs.
- Locked out after changing port: ensure UFW allows new port and router forwards it if remote.

---

## 14. Recovery steps if you lock yourself out

**Fast fixes:**

- If you have console or KVM access, log in locally, restore `/etc/ssh/sshd_config.backup`, and restart sshd.
- If you have another admin account that still works, use it to restore config.
- If the server is cloud-hosted, use the provider's serial console to fix the config.

**Command to restore backup (if present):**

```bash
sudo cp /etc/ssh/sshd_config.backup /etc/ssh/sshd_config
sudo systemctl restart ssh
```

**If no backups and no console access:**

- You may need to boot into single-user mode via the provider’s rescue environment and edit the file.

---

## 15. Appendix: full `sshd_config` example

> This is a conservative, practical config you can paste into `/etc/ssh/sshd_config` after adapting `AllowUsers` and optionally `ListenAddress`.

```text
# Example SSHD config for homelab
ListenAddress 0.0.0.0
Protocol 2

PermitRootLogin no
PasswordAuthentication no
ChallengeResponseAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys

AllowUsers yourusername

LoginGraceTime 30
MaxAuthTries 3
MaxSessions 2

ClientAliveInterval 300
ClientAliveCountMax 2

AllowTcpForwarding no
PermitTunnel no
X11Forwarding no

KexAlgorithms curve25519-sha256@libssh.org
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

LogLevel VERBOSE
Include /etc/ssh/sshd_config.d/*.conf
```

**Reminder:** test from another session before closing your current session.

---

## 16. References

I used the references you provided as source material and to align recommendations with published best practices. The guide integrates patterns and strong defaults commonly recommended by those sources and adapts them for homelab usage (tradeoffs between convenience and strict production lock-down were considered).

Provided references (as you supplied them):

- How To Harden OpenSSH on Ubuntu 20.04 — DigitalOcean
- How To Harden OpenSSH Client on Ubuntu 20.04 — DigitalOcean
- Initial Server Setup with Ubuntu — DigitalOcean
- SSH server hardening on Ubuntu — Tensordock docs
- 5 Effective Tips to Harden SSH Server on Ubuntu — LinuxBabe
- Hardening SSH Access on Ubuntu VPS: The Ultimate Guide — InterServer
- Harden your Linux server: Best practices for securing SSH, User Privileges, firewall configurations — Medium article

---

## Final notes and next steps

- If you want, I can generate a **ready-to-run bash script** that performs the non-destructive parts of this guide with interactive prompts (username, SSH port, whether to enable 2FA, etc.). I will include multiple safety checks and will not restart `sshd` until we've verified connectivity.
- I can also produce a shorter **one-page checklist** printable as PDF.

---

_End of guide._

## references

- [How To Harden OpenSSH on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-on-ubuntu-20-04#step-3-restricting-the-shell-of-a-user)
- [How To Harden OpenSSH Client on Ubuntu 20.04](https://www.digitalocean.com/community/tutorials/how-to-harden-openssh-client-on-ubuntu-20-04)

- [Initial Server Setup with Ubuntu](https://www.digitalocean.com/community/tutorials/initial-server-setup-with-ubuntu)

- [SSH server hardening on Ubuntu](https://docs.tensordock.com/virtual-machines/ssh-server-hardening-on-ubuntu)

- [5 Effective Tips to Harden SSH Server on Ubuntu](https://www.linuxbabe.com/security/harden-ssh-server)

- [Hardening SSH Access on Ubuntu VPS: The Ultimate Guide](https://www.interserver.net/tips/kb/hardening-ssh-access-on-ubuntu-vps-the-ultimate-guide/)

- [Harden your Linux server: Best practices for securing SSH,User Privileges, firewall configurations](https://medium.com/@habibullah.127.0.0.1/harden-your-linux-server-best-practices-for-securing-ssh-user-privileges-firewall-configurations-b3c7f1007543)
