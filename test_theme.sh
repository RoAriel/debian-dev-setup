#!/usr/bin/env bash
# ============================================================
# test_themes.sh
# Prueba visual de los 4 temas de prompt.
# No instala nada ni modifica ningún archivo del sistema.
# ============================================================

set -euo pipefail

# Resolver directorio del proyecto
# Asume que test_themes.sh está en la raíz del proyecto
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SETUP_DIR/lib/utils.sh"

NC='\e[0m'
BOLD='\e[1m'
DIM='\e[2m'

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🎨  Preview de temas de prompt${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

_preview_theme() {
  local THEME_FILE="$SETUP_DIR/themes/${1}.sh"
  [[ -f "$THEME_FILE" ]] || { echo "  ✖ Tema no encontrado: $1"; return 1; }

  unset _THEME_LOADED
  source "$THEME_FILE"

  echo -e "${BOLD}  [$2] ${THEME_NAME}${NC}"
  echo -e "  ${DIM}$(printf '%.0s─' {1..46})${NC}"

  # ── Simular prompt: usuario normal, directorio, git limpio ──
  echo -e "  ${DIM}Prompt normal:${NC}"
  printf "  "
  echo -e "  \n  ${THEME_USER}roariel${NC} ${THEME_PATH}~/proyectos/mi-app${NC} ${THEME_GIT} main ${THEME_OK}●${NC}\n  ${THEME_OK}❯${NC} "

  # ── Simular prompt: rama git sucia ──
  echo -e "  ${DIM}Con cambios sin commitear:${NC}"
  printf "  "
  echo -e "  \n  ${THEME_USER}roariel${NC} ${THEME_PATH}~/proyectos/mi-app${NC} ${THEME_GIT} feature/login ${THEME_ERROR}●${NC}\n  ${THEME_OK}❯${NC} "

  # ── Simular prompt: último comando con error ──
  echo -e "  ${DIM}Último comando falló (exit code ≠ 0):${NC}"
  printf "  "
  echo -e "  \n  ${THEME_USER}roariel${NC} ${THEME_PATH}~/proyectos/mi-app${NC} ${THEME_GIT} main ${THEME_OK}●${NC}\n  ${THEME_ERROR}❯${NC} "

  # ── Simular prompt: con venv activo ──
  echo -e "  ${DIM}Con virtualenv activo:${NC}"
  printf "  "
  echo -e "  \n  ${THEME_VENV}(🐍 mi-venv)${NC} ${THEME_USER}roariel${NC} ${THEME_PATH}~/proyectos/mi-app${NC}\n  ${THEME_OK}❯${NC} "

  # ── Simular prompt: root ──
  echo -e "  ${DIM}Sesión root:${NC}"
  printf "  "
  echo -e "  \n  ${THEME_ROOT}root${NC} ${THEME_PATH}~/proyectos/mi-app${NC}\n  ${THEME_ROOT}#${NC} "

  # ── Paleta de colores del tema ──
  echo -e "  ${DIM}Paleta:${NC}"
  echo -e "  ${THEME_USER}██ USER${NC}  ${THEME_ROOT}██ ROOT/ERR${NC}  ${THEME_PATH}██ PATH${NC}  ${THEME_GIT}██ GIT${NC}  ${THEME_OK}██ OK${NC}  ${THEME_VENV}██ VENV${NC}"
  echo ""
}

_preview_theme "nord"       "1"
_preview_theme "dracula"    "2"
_preview_theme "gruvbox"    "3"
_preview_theme "catppuccin" "4"

echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ¿Qué tema te gustó más?"
echo ""

while true; do
  read -rp "  Ingresá el número [1-4] para ver más detalles, o Enter para salir: " CHOICE || break
  [[ -z "$CHOICE" ]] && break

  case "$CHOICE" in
    1) SELECTED="nord"       ;;
    2) SELECTED="dracula"    ;;
    3) SELECTED="gruvbox"    ;;
    4) SELECTED="catppuccin" ;;
    *) warn "Ingresá un número entre 1 y 4."; continue ;;
  esac

  unset _THEME_LOADED
  source "$SETUP_DIR/themes/${SELECTED}.sh"

  echo ""
  echo -e "  ${BOLD}Tema seleccionado: ${THEME_NAME}${NC}"
  echo -e "  Para usarlo al instalar: ${DIM}./setup.sh${NC} → elegí la opción correspondiente"
  echo ""
  break
done

echo -e "  ${DIM}Este script no modificó ningún archivo del sistema.${NC}"
echo ""