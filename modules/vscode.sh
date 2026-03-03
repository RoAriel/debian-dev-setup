#!/usr/bin/env bash
# ============================================================
# modules/vscode.sh
# Instala Visual Studio Code desde el repo oficial de Microsoft
# ============================================================

[[ -n "${_VSCODE_LOADED:-}" ]] && return 0
_VSCODE_LOADED=1

module_vscode() {
  step "Visual Studio Code..."

  if command -v code &>/dev/null; then
    skipped
    ok "VSCode $(code --version 2>/dev/null | head -1)"
    return 0
  fi

  echo "  Agregando repositorio de Microsoft..."

  run "wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo install -D -o root -g root -m 644 /dev/stdin \
        /etc/apt/keyrings/microsoft.gpg"

  run "echo 'deb [arch=${ARCH} signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main' \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null"

  run "sudo apt-get update -qq"
  run "sudo apt-get install -y code"

  if [[ "${DRY_RUN:-false}" != true ]]; then
    ok "VSCode $(code --version 2>/dev/null | head -1) instalado"
  else
    ok "VSCode [instalación simulada]"
  fi
}
