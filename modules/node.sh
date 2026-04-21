#!/usr/bin/env bash
# ============================================================
# modules/node.sh
# Instala NVM o FNM según NODE_MANAGER_CHOICE.
# Detecta el manager contrario y ofrece desinstalarlo.
#
# Variables requeridas del orquestador:
#   NODE_MANAGER_CHOICE  — "nvm" | "fnm"
# ============================================================

[[ -n "${_NODE_LOADED:-}" ]] && return 0
_NODE_LOADED=1

# ── Helper: encontrar el binario de FNM ──────────────────────
# El installer puede dejarlo en distintos lugares según la versión
# y el sistema. Devuelve la ruta completa o string vacío.
_find_fnm_bin() {
  local _bin=""

  for _candidate in \
      "$HOME/.local/bin/fnm" \
      "$HOME/.fnm/fnm" \
      "$HOME/.cargo/bin/fnm"; do
    if [[ -x "$_candidate" ]]; then
      _bin="$_candidate"
      break
    fi
  done

  # Último recurso: buscar en todo el HOME (máx. 5 niveles)
  if [[ -z "$_bin" ]]; then
    _bin=$(find "$HOME" -maxdepth 5 -name "fnm" -type f -perm /111 2>/dev/null | head -1)
  fi

  echo "$_bin"
}

# ── Desinstalador de NVM ──────────────────────────────────────
_uninstall_nvm() {
  echo "  Desinstalando NVM..."

  local RC_FILE
  case "${SHELL_CHOICE:-bash}" in
    zsh)  RC_FILE="$HOME/.zshrc"  ;;
    *)    RC_FILE="$HOME/.bashrc" ;;
  esac

  if [[ -f "$RC_FILE" ]]; then
    run "sed -i '/NVM_DIR/d; /nvm\\.sh/d; /nvm.*bash_completion/d' \"$RC_FILE\""
  fi

  run "rm -rf \"$HOME/.nvm\""
  ok "NVM desinstalado"
}

# ── Desinstalador de FNM ──────────────────────────────────────
_uninstall_fnm() {
  echo "  Desinstalando FNM..."

  local RC_FILE
  case "${SHELL_CHOICE:-bash}" in
    zsh)  RC_FILE="$HOME/.zshrc"  ;;
    *)    RC_FILE="$HOME/.bashrc" ;;
  esac

  if [[ -f "$RC_FILE" ]]; then
    run "sed -i '/fnm/d' \"$RC_FILE\""
  fi

  run "rm -f \"$HOME/.local/bin/fnm\""
  run "rm -f \"$HOME/.cargo/bin/fnm\""
  run "rm -f \"$HOME/.fnm/fnm\""
  run "rm -rf \"$HOME/.local/share/fnm\""
  ok "FNM desinstalado"
}

# ── Setup NVM ─────────────────────────────────────────────────
_setup_nvm() {
  step "NVM (Node Version Manager)..."

  # Detección cruzada: FNM instalado → ofrecer desinstalar
  if [[ -n "$(_find_fnm_bin)" ]]; then
    warn "FNM está instalado en este sistema."
    if [[ "${DRY_RUN:-false}" == true ]]; then
      dry_log "Preguntaría: ¿Desinstalar FNM antes de instalar NVM?"
    else
      if confirm "¿Querés desinstalar FNM antes de continuar con NVM?"; then
        _uninstall_fnm
      else
        warn "FNM y NVM pueden convivir pero pueden generar conflictos de PATH."
      fi
    fi
  fi

  if [ -d "$HOME/.nvm" ]; then
    skipped
  else
    echo "  Obteniendo última versión de NVM..."
    NVM_VERSION=$(
      curl -sf https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4
    )
    [[ -n "$NVM_VERSION" ]] || error "No se pudo obtener la versión de NVM desde GitHub."

    run "curl -fsSo- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash"
    ok "NVM ${NVM_VERSION} instalado"
  fi

  # Cargar NVM en la sesión actual
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  _select_node_version_nvm
}

# ── Selector de versión Node para NVM ────────────────────────
_select_node_version_nvm() {
  step "Node.js — Selección de versión (NVM)..."

  if [[ "${DRY_RUN:-false}" == true ]]; then
    dry_log "Se mostraría el selector interactivo de versiones de Node.js"
    dry_log "nvm install <version_elegida>"
    dry_log "nvm alias default <version_elegida>"
    return 0
  fi

  echo "  Consultando versiones disponibles en nodejs.org..."

  TMP_NODE_JSON=$(mktemp /tmp/node-releases-XXXXXX.json)
  TMP_PY=$(mktemp /tmp/parse-node-XXXXXX.py)
  trap 'rm -f "$TMP_NODE_JSON" "$TMP_PY"' RETURN

  curl -sf https://nodejs.org/dist/index.json -o "$TMP_NODE_JSON" \
    || error "No se pudo conectar a nodejs.org."

  cat > "$TMP_PY" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
current = data[0]["version"]
lts = next((r["version"] for r in data if r["lts"] is not False), "")
seen, versions = {}, []
for r in data:
    major = r["version"].split(".")[0]
    if major not in seen:
        seen[major] = True
        versions.append(r["version"])
    if len(versions) >= 6:
        break
print("CURRENT=" + current)
print("LTS=" + lts)
print("VERSIONS=" + ",".join(versions))
PYEOF

  NODE_DATA=$(python3 "$TMP_PY" "$TMP_NODE_JSON") \
    || error "Error al parsear versiones de Node.js."

  CURRENT_VERSION=$(echo "$NODE_DATA" | grep '^CURRENT=' | cut -d= -f2)
  LTS_VERSION=$(echo "$NODE_DATA"     | grep '^LTS='     | cut -d= -f2)
  IFS=',' read -ra REMOTE_VERSIONS <<< "$(echo "$NODE_DATA" | grep '^VERSIONS=' | cut -d= -f2)"

  [[ ${#REMOTE_VERSIONS[@]} -gt 0 ]] || error "Lista de versiones vacía."

  INSTALLED_VERSIONS=$(nvm ls --no-colors 2>/dev/null || echo "")

  echo ""
  echo -e "  ${BOLD}Versiones disponibles de Node.js:${NC}"
  echo ""

  declare -A VERSION_MAP
  local INDEX=1

  for V in "${REMOTE_VERSIONS[@]}"; do
    TAGS=""
    [[ "$V" == "$CURRENT_VERSION" ]] && TAGS+=" ${CYAN}[Current]${NC}"
    [[ "$V" == "$LTS_VERSION"     ]] && TAGS+=" ${GREEN}[LTS]${NC}"
    echo "$INSTALLED_VERSIONS" | grep -qF "$V" && TAGS+=" ${YELLOW}[instalada]${NC}"
    echo -e "    ${BOLD}[$INDEX]${NC}  $V${TAGS}"
    VERSION_MAP[$INDEX]="$V"
    (( INDEX++ ))
  done

  echo ""

  ACTIVE_NODE=""
  if command -v node &>/dev/null; then
    ACTIVE_NODE=$(node --version)
    echo -e "  ${YELLOW}⚠  Node activo: ${ACTIVE_NODE}${NC}"
    echo -e "  ${BOLD}[0]${NC}  Mantener versión actual sin cambios"
    echo ""
  fi

  SELECTED_VERSION=""
  while true; do
    read -rp "  Ingresá el número de la versión a instalar: " CHOICE

    if [[ "$CHOICE" == "0" && -n "$ACTIVE_NODE" ]]; then
      ok "Se mantiene Node ${ACTIVE_NODE} sin cambios"
      SELECTED_VERSION="$ACTIVE_NODE"
      break
    fi

    if [[ "$CHOICE" =~ ^[1-9][0-9]*$ ]] && [[ -n "${VERSION_MAP[$CHOICE]:-}" ]]; then
      SELECTED_VERSION="${VERSION_MAP[$CHOICE]}"
      echo ""
      echo "  Instalando Node ${SELECTED_VERSION}..."
      nvm install "$SELECTED_VERSION"
      nvm use "$SELECTED_VERSION"
      ok "Node $(node --version) · npm $(npm --version)"

      echo ""
      if confirm "¿Querés setear Node ${SELECTED_VERSION} como versión predeterminada?"; then
        nvm alias default "$SELECTED_VERSION"
        ok "Node ${SELECTED_VERSION} seteado como predeterminado"
      else
        CURRENT_DEFAULT=$(nvm alias default 2>/dev/null | grep -oP "v[\d.]+" | head -1 || echo "ninguno")
        warn "Default no modificado → sigue siendo ${CURRENT_DEFAULT}"
      fi
      break
    else
      warn "Opción inválida. Ingresá un número entre 0 y $(( INDEX - 1 ))."
    fi
  done

  export NODE_SELECTED_VERSION="$SELECTED_VERSION"
}

# ── Setup FNM ─────────────────────────────────────────────────
_setup_fnm() {
  step "FNM (Fast Node Manager)..."

  # Detección cruzada: NVM instalado → ofrecer desinstalar
  if [ -d "$HOME/.nvm" ]; then
    warn "NVM está instalado en este sistema ($HOME/.nvm)."
    if [[ "${DRY_RUN:-false}" == true ]]; then
      dry_log "Preguntaría: ¿Desinstalar NVM antes de instalar FNM?"
    else
      if confirm "¿Querés desinstalar NVM antes de continuar con FNM?"; then
        _uninstall_nvm
      else
        warn "NVM y FNM pueden convivir pero pueden generar conflictos de PATH."
      fi
    fi
  fi

  # Buscar si FNM ya existe antes de instalar
  local FNM_BIN
  FNM_BIN=$(_find_fnm_bin)

  if [[ -n "$FNM_BIN" ]]; then
    skipped
    ok "FNM $("$FNM_BIN" --version 2>/dev/null) ya instalado"
  else
    echo "  Obteniendo última versión de FNM..."
    FNM_VERSION=$(
      curl -sf https://api.github.com/repos/Schniz/fnm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4
    )
    [[ -n "$FNM_VERSION" ]] || error "No se pudo obtener la versión de FNM desde GitHub."

    run "curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell"
    ok "FNM ${FNM_VERSION} instalado"

    # Re-buscar después de instalar
    FNM_BIN=$(_find_fnm_bin)
    [[ -n "$FNM_BIN" ]] \
      || error "FNM no encontrado tras la instalación. Revisá la salida del installer arriba."
  fi

  ok "FNM binario en: $FNM_BIN"

  # Cargar FNM en la sesión actual.
  # El installer corre en un subshell y no propaga cambios al proceso padre.
  # Agregamos el directorio del binario al PATH y cargamos el entorno
  # usando la ruta explícita — sin depender del hash del shell.
  export PATH="$(dirname "$FNM_BIN"):$PATH"
  hash -r 2>/dev/null || true
  eval "$("$FNM_BIN" env --use-on-cd 2>/dev/null)"

  _select_node_version_fnm
}

# ── Selector de versión Node para FNM ────────────────────────
_select_node_version_fnm() {
  step "Node.js — Selección de versión (FNM)..."

  if [[ "${DRY_RUN:-false}" == true ]]; then
    dry_log "Se mostraría el selector interactivo de versiones de Node.js"
    dry_log "fnm install <version_elegida>"
    dry_log "fnm default <version_elegida>"
    return 0
  fi

  echo "  Consultando versiones disponibles en nodejs.org..."

  TMP_NODE_JSON=$(mktemp /tmp/node-releases-XXXXXX.json)
  TMP_PY=$(mktemp /tmp/parse-node-XXXXXX.py)
  trap 'rm -f "$TMP_NODE_JSON" "$TMP_PY"' RETURN

  curl -sf https://nodejs.org/dist/index.json -o "$TMP_NODE_JSON" \
    || error "No se pudo conectar a nodejs.org."

  cat > "$TMP_PY" << 'PYEOF'
import json, sys
with open(sys.argv[1]) as f:
    data = json.load(f)
current = data[0]["version"]
lts = next((r["version"] for r in data if r["lts"] is not False), "")
seen, versions = {}, []
for r in data:
    major = r["version"].split(".")[0]
    if major not in seen:
        seen[major] = True
        versions.append(r["version"])
    if len(versions) >= 6:
        break
print("CURRENT=" + current)
print("LTS=" + lts)
print("VERSIONS=" + ",".join(versions))
PYEOF

  NODE_DATA=$(python3 "$TMP_PY" "$TMP_NODE_JSON") \
    || error "Error al parsear versiones de Node.js."

  CURRENT_VERSION=$(echo "$NODE_DATA" | grep '^CURRENT=' | cut -d= -f2)
  LTS_VERSION=$(echo "$NODE_DATA"     | grep '^LTS='     | cut -d= -f2)
  IFS=',' read -ra REMOTE_VERSIONS <<< "$(echo "$NODE_DATA" | grep '^VERSIONS=' | cut -d= -f2)"

  [[ ${#REMOTE_VERSIONS[@]} -gt 0 ]] || error "Lista de versiones vacía."

  INSTALLED_VERSIONS=$(fnm ls 2>/dev/null || echo "")

  echo ""
  echo -e "  ${BOLD}Versiones disponibles de Node.js:${NC}"
  echo ""

  declare -A VERSION_MAP
  local INDEX=1

  for V in "${REMOTE_VERSIONS[@]}"; do
    TAGS=""
    [[ "$V" == "$CURRENT_VERSION" ]] && TAGS+=" ${CYAN}[Current]${NC}"
    [[ "$V" == "$LTS_VERSION"     ]] && TAGS+=" ${GREEN}[LTS]${NC}"
    echo "$INSTALLED_VERSIONS" | grep -qF "${V#v}" && TAGS+=" ${YELLOW}[instalada]${NC}"
    echo -e "    ${BOLD}[$INDEX]${NC}  $V${TAGS}"
    VERSION_MAP[$INDEX]="$V"
    (( INDEX++ ))
  done

  echo ""

  ACTIVE_NODE=""
  if command -v node &>/dev/null; then
    ACTIVE_NODE=$(node --version)
    echo -e "  ${YELLOW}⚠  Node activo: ${ACTIVE_NODE}${NC}"
    echo -e "  ${BOLD}[0]${NC}  Mantener versión actual sin cambios"
    echo ""
  fi

  SELECTED_VERSION=""
  while true; do
    read -rp "  Ingresá el número de la versión a instalar: " CHOICE

    if [[ "$CHOICE" == "0" && -n "$ACTIVE_NODE" ]]; then
      ok "Se mantiene Node ${ACTIVE_NODE} sin cambios"
      SELECTED_VERSION="$ACTIVE_NODE"
      break
    fi

    if [[ "$CHOICE" =~ ^[1-9][0-9]*$ ]] && [[ -n "${VERSION_MAP[$CHOICE]:-}" ]]; then
      SELECTED_VERSION="${VERSION_MAP[$CHOICE]}"
      echo ""
      echo "  Instalando Node ${SELECTED_VERSION}..."
      fnm install "$SELECTED_VERSION"
      fnm use "$SELECTED_VERSION"
      ok "Node $(node --version) · npm $(npm --version)"

      echo ""
      if confirm "¿Querés setear Node ${SELECTED_VERSION} como versión predeterminada?"; then
        fnm default "$SELECTED_VERSION"
        ok "Node ${SELECTED_VERSION} seteado como predeterminado"
      else
        CURRENT_DEFAULT=$(fnm default 2>/dev/null | head -1 || echo "ninguno")
        warn "Default no modificado → sigue siendo ${CURRENT_DEFAULT}"
      fi
      break
    else
      warn "Opción inválida. Ingresá un número entre 0 y $(( INDEX - 1 ))."
    fi
  done

  export NODE_SELECTED_VERSION="$SELECTED_VERSION"
}

# ── Punto de entrada ──────────────────────────────────────────
module_node() {
  case "${NODE_MANAGER_CHOICE:-nvm}" in
    nvm) _setup_nvm ;;
    fnm) _setup_fnm ;;
    *)   error "Node manager no reconocido: '${NODE_MANAGER_CHOICE}'. Debe ser 'nvm' o 'fnm'." ;;
  esac
}