#!/usr/bin/env bash
# ============================================================
# test_flags.sh
# Prueba los flags --dry-run y --minimal del orquestador.
# No instala nada ni modifica ningún archivo del sistema.
# ============================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SETUP_DIR/lib/utils.sh"

BOLD='\e[1m'
DIM='\e[2m'
NC='\e[0m'

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🧪  Test de flags: --dry-run y --minimal${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${DIM}Este test ejecuta setup.sh en modo simulación.${NC}"
echo -e "  ${DIM}No se instalará ni modificará nada en tu sistema.${NC}"
echo ""

# ── Detectar estado de Git para generar respuestas correctas ──
# El flujo de preguntas cambia según si ya hay config de Git o no:
#   Con config previa:   shell → tema → ¿modificar git? (n) → confirmar (S)
#   Sin config previa:   shell → tema → nombre → email → confirmar (S)
_GIT_NAME=$(git config --global user.name  2>/dev/null || echo "")
_GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$_GIT_NAME" && -n "$_GIT_EMAIL" ]]; then
  echo -e "  ${DIM}Git detectado: ${_GIT_NAME} <${_GIT_EMAIL}>${NC}"
  echo -e "  ${DIM}Las respuestas automáticas mantendrán esta configuración.${NC}"
  _GIT_CONFIGURED=true
else
  echo -e "  ${DIM}Git sin configurar — los tests usarán 'Test User <test@example.com>'.${NC}"
  _GIT_CONFIGURED=false
fi
echo ""

# Genera la secuencia de respuestas correcta según estado de Git
# $1 = número de shell (1=bash, 2=zsh)
# $2 = número de tema  (1=nord, 2=dracula, 3=gruvbox, 4=catppuccin)
_answers_for() {
  local SHELL_N="$1"
  local THEME_N="$2"
  if [[ "$_GIT_CONFIGURED" == true ]]; then
    # Git ya existe → pregunta "¿modificar?" → n → confirmar → S
    printf "%s\n%s\nn\nS\n" "$SHELL_N" "$THEME_N"
  else
    # Git vacío → pide nombre y email → confirmar → S
    printf "%s\n%s\nTest User\ntest@example.com\nS\n" "$SHELL_N" "$THEME_N"
  fi
}

_run_test() {
  local LABEL="$1"
  local FLAGS="$2"
  local ANSWERS="$3"

  echo -e "${BOLD}  ── Test: ${LABEL} ──${NC}"
  echo -e "  ${DIM}Comando: ./setup.sh ${FLAGS}${NC}"
  echo ""

  echo "$ANSWERS" | bash "$SETUP_DIR/setup.sh" $FLAGS 2>&1 | \
    sed 's/^/  /' | head -80

  echo ""
  echo -e "  ${DIM}$(printf '%.0s─' {1..46})${NC}"
  echo ""
}

# ── Test 1: --help ────────────────────────────────────────────
echo -e "${BOLD}  ── Test 1: --help ──${NC}"
echo ""
bash "$SETUP_DIR/setup.sh" --help 2>&1 | sed 's/^/  /'
echo ""
echo -e "  ${DIM}$(printf '%.0s─' {1..46})${NC}"
echo ""

# ── Test 2: flag inválido ─────────────────────────────────────
echo -e "${BOLD}  ── Test 2: flag desconocido ──${NC}"
echo ""
bash "$SETUP_DIR/setup.sh" --unknown 2>&1 | sed 's/^/  /' || true
echo ""
echo -e "  ${DIM}$(printf '%.0s─' {1..46})${NC}"
echo ""

read -rp "  Presioná Enter para continuar con --dry-run completo..." _ || true

# ── Test 3: --dry-run completo ────────────────────────────────
_run_test "--dry-run completo (Bash + Nord)" \
  "--dry-run" \
  "$(_answers_for 1 1)"

read -rp "  Presioná Enter para continuar con --dry-run + --minimal..." _ || true

# ── Test 4: --dry-run + --minimal ─────────────────────────────
_run_test "--dry-run + --minimal (Bash + Dracula)" \
  "--dry-run --minimal" \
  "$(_answers_for 1 2)"

read -rp "  Presioná Enter para continuar con --dry-run Zsh..." _ || true

# ── Test 5: --dry-run con Zsh + Catppuccin ────────────────────
_run_test "--dry-run completo (Zsh + Catppuccin)" \
  "--dry-run" \
  "$(_answers_for 2 4)"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
ok "Todos los tests de flags completados"
echo -e "  ${DIM}Ningún archivo fue modificado en tu sistema.${NC}"
echo ""