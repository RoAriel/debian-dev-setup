#!/usr/bin/env bash
# ============================================================
# modules/brave.sh
# Instala Brave Browser desde el repo oficial de Brave
# ============================================================

[[ -n "${_BRAVE_LOADED:-}" ]] && return 0
_BRAVE_LOADED=1

module_brave() {
  step "Brave Browser..."

  if command -v brave-browser &>/dev/null; then
    skipped
    ok "$(brave-browser --version 2>/dev/null | head -1)"
    return 0
  fi

  echo "  Agregando repositorio de Brave..."

  run "sudo curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"

  run "echo 'deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg] \
https://brave-browser-apt-release.s3.brave.com/ stable main' \
    | sudo tee /etc/apt/sources.list.d/brave-browser-release.list > /dev/null"

  run "sudo apt-get update -qq"
  run "sudo apt-get install -y brave-browser"

  if [[ "${DRY_RUN:-false}" != true ]]; then
    ok "$(brave-browser --version 2>/dev/null | head -1) instalado"
  else
    ok "Brave Browser [instalación simulada]"
  fi
}
