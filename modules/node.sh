#!/usr/bin/env bash
# ============================================================
# modules/node.sh
# Instala NVM y ofrece selector interactivo de versión de Node
# ============================================================

[[ -n "${_NODE_LOADED:-}" ]] && return 0
_NODE_LOADED=1

module_node() {

  # ── NVM ────────────────────────────────────────────────────
  step "NVM (Node Version Manager)..."

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

  # ── Selector de versión Node ────────────────────────────────
  step "Node.js — Selección de versión..."

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

  # Exportar para el resumen final en setup.sh
  export NODE_SELECTED_VERSION="$SELECTED_VERSION"
}
