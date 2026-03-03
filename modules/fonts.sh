#!/usr/bin/env bash
# ============================================================
# modules/fonts.sh
# Instala/actualiza Cascadia Code desde GitHub Releases
# Usa un archivo .installed-version para evitar reinstalaciones
# ============================================================

[[ -n "${_FONTS_LOADED:-}" ]] && return 0
_FONTS_LOADED=1

module_fonts() {
  step "Fuentes Cascadia Code..."

  FONT_DIR="$HOME/.local/share/fonts/CascadiaCode"
  FONT_VERSION_FILE="$FONT_DIR/.installed-version"

  echo "  Consultando última versión en GitHub..."

  if [[ "${DRY_RUN:-false}" == true ]]; then
    dry_log "curl → GitHub API: microsoft/cascadia-code latest release"
    dry_log "wget → CascadiaCode-X.X.zip"
    dry_log "unzip + cp *.ttf/*.otf → $FONT_DIR"
    dry_log "fc-cache -f"
    dry_log "echo VERSION > $FONT_VERSION_FILE"
    return 0
  fi

  LATEST_VERSION=$(
    curl -sf https://api.github.com/repos/microsoft/cascadia-code/releases/latest \
      | grep '"tag_name"' | cut -d'"' -f4
  )
  [[ -n "$LATEST_VERSION" ]] || error "No se pudo obtener la versión de Cascadia Code desde GitHub."

  # Leer versión instalada localmente
  INSTALLED_VERSION=""
  [[ -f "$FONT_VERSION_FILE" ]] && INSTALLED_VERSION=$(cat "$FONT_VERSION_FILE")

  # ── Decidir qué hacer ──
  if [[ -n "$INSTALLED_VERSION" && "$INSTALLED_VERSION" == "$LATEST_VERSION" ]]; then
    skipped
    ok "Cascadia Code ${INSTALLED_VERSION} (última versión, sin cambios)"
    export CASCADIA_VERSION="$INSTALLED_VERSION"
    return 0
  fi

  if [[ -n "$INSTALLED_VERSION" && "$INSTALLED_VERSION" != "$LATEST_VERSION" ]]; then
    warn "Versión instalada: ${INSTALLED_VERSION} → disponible: ${LATEST_VERSION}"
    if ! confirm "¿Querés actualizar Cascadia Code a ${LATEST_VERSION}?"; then
      ok "Se mantiene Cascadia Code ${INSTALLED_VERSION} sin cambios"
      export CASCADIA_VERSION="$INSTALLED_VERSION"
      return 0
    fi
  fi

  # ── Instalar ──
  local INSTALL_VERSION="$LATEST_VERSION"
  local CASCADIA_URL="https://github.com/microsoft/cascadia-code/releases/download/${INSTALL_VERSION}/CascadiaCode-${INSTALL_VERSION#v}.zip"

  echo "  Descargando Cascadia Code ${INSTALL_VERSION}..."

  local TMP_FONTS
  TMP_FONTS=$(mktemp -d /tmp/cascadia-XXXXXX)
  trap 'rm -rf "$TMP_FONTS"' RETURN

  wget -qO "$TMP_FONTS/CascadiaCode.zip" "$CASCADIA_URL"
  unzip -q "$TMP_FONTS/CascadiaCode.zip" -d "$TMP_FONTS/cascadia"

  mkdir -p "$FONT_DIR"
  find "$TMP_FONTS/cascadia" \( -name "*.ttf" -o -name "*.otf" \) \
    -exec cp {} "$FONT_DIR/" \;

  echo "$INSTALL_VERSION" > "$FONT_VERSION_FILE"
  fc-cache -f 2>/dev/null

  ok "Cascadia Code ${INSTALL_VERSION} instalado en $FONT_DIR"
  export CASCADIA_VERSION="$INSTALL_VERSION"
}
