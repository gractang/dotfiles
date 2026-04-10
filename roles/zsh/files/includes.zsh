# ASDF
# . $HOME/.asdf/asdf.sh
# . $HOME/.asdf/completions/asdf.bash

# java
# . ~/.asdf/plugins/java/set-java-home.zsh
#
if command -v devbox &>/dev/null; then
  local _devbox_cache="$HOME/.cache/devbox/shellenv.zsh"
  local _devbox_config="$HOME/.local/share/devbox/global/default/devbox.json"
  if [[ ! -f "$_devbox_cache" || "$_devbox_config" -nt "$_devbox_cache" ]]; then
    mkdir -p "${_devbox_cache:h}"
    devbox global shellenv --init-hook > "$_devbox_cache"
  fi
  source "$_devbox_cache"
fi

if command -v direnv &>/dev/null; then
  eval "$(direnv hook zsh)"
fi
