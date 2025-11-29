# Server setup

- update && upgrade :
  `sudo apt update && sudo apt upgrade -y`
- fzf setup :
  `sudo apt install -y fzf`
  `git clone --depth 1 --branch 0.44.0 https://github.com/junegunn/fzf.git`
- add to .bashrc
  `source fzf/shell/completion.bash`
  `source fzf/shell/key-bindings.bash`
