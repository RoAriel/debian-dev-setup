#!/usr/bin/env bash
# ============================================================
# lib/utils.sh
# Helpers compartidos: colores, funciones de logging y wrapper
# de ejecución con soporte para --dry-run.
#
# Uso: source "$(dirname "$0")/lib/utils.sh"
# ============================================================

# ── Guard: evitar doble source ────────────────────────────────
[[ -n "${_UTILS_LOADED:-}" ]] && return 0
_UTILS_LOADED=1

# ── Colores ANSI ──────────────────────────────────────────────
YELLOW='\033[1;33m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
RED='\033[1;31m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ── Logging ───────────────────────────────────────────────────

# Sección principal (con línea en blanco antes)
step() { echo -e "\n${CYAN}${BOLD}▶ $*${NC}"; }

# Éxito
ok() { echo -e "  ${GREEN}✔ $*${NC}"; }

# Advertencia (no detiene el script)
warn() { echo -e "  ${YELLOW}⚠ $*${NC}"; }

# Error fatal (imprime a stderr y sale)
error() {
  echo -e "\n${RED}${BOLD}✖ ERROR: $*${NC}\n" >&2
  exit 1
}

# Ya instalado — se omite
skipped() { echo -e "  ${YELLOW}⟳ Ya instalado — omitiendo${NC}"; }

# Acción simulada en dry-run
dry_log() { echo -e "  ${DIM}[dry-run]${NC} ${DIM}$*${NC}"; }

# ── Wrapper de ejecución ──────────────────────────────────────
#
# Uso: run <comando completo como string>
#
# - En modo normal:   ejecuta el comando
# - En modo dry-run:  solo lo imprime, no ejecuta nada
#
# DRY_RUN se define en setup.sh al parsear los flags.
# Por defecto es false si no está definido.
#
run() {
  if [[ "${DRY_RUN:-false}" == true ]]; then
    dry_log "$*"
  else
    eval "$@"
  fi
}

# ── Versión silenciosa de run (sin imprimir en dry-run) ───────
# Útil para comandos de verificación que no deberían mostrarse
run_silent() {
  if [[ "${DRY_RUN:-false}" != true ]]; then
    eval "$@"
  fi
}

# ── Confirmación interactiva ──────────────────────────────────
#
# Uso: confirm "¿Querés continuar?" && echo "sí" || echo "no"
# Default: S (confirma con Enter)
#
confirm() {
  local MSG="${1:-¿Continuar?}"
  local RESP
  read -rp "  ${MSG} [S/n]: " RESP
  RESP="${RESP:-S}"
  [[ "$RESP" =~ ^[SsYy]$ ]]
}

# ── Separador visual ──────────────────────────────────────────
separator() {
  echo -e "\n${DIM}────────────────────────────────────────${NC}"
}

# ── Verificar dependencia ─────────────────────────────────────
#
# Uso: require curl "curl no está instalado"
#
require() {
  local CMD="$1"
  local MSG="${2:-El comando '$CMD' es requerido pero no está disponible.}"
  command -v "$CMD" &>/dev/null || error "$MSG"
}