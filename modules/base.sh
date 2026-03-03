#!/usr/bin/env bash
# ============================================================
# modules/base.sh
# Paquetes base del sistema: curl, git, python3, build-essential
# ============================================================

[[ -n "${_BASE_LOADED:-}" ]] && return 0
_BASE_LOADED=1

module_base() {
  step "Paquetes base del sistema..."

  run "sudo apt-get update -qq"
  run "sudo apt-get install -y --no-install-recommends \
    curl wget gpg apt-transport-https ca-certificates \
    gnupg lsb-release unzip fontconfig \
    git python3 python3-pip python3-venv \
    build-essential \
    tree"

  if [[ "${DRY_RUN:-false}" != true ]]; then
    git --version &>/dev/null   || error "Git no se instaló correctamente."
    python3 --version &>/dev/null || error "Python no se instaló correctamente."
    ok "Git $(git --version)"
    ok "$(python3 --version)"
  fi

  ok "Paquetes base instalados"
}
