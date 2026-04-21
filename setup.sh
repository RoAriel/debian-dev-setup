#!/usr/bin/env bash
# ============================================================
# setup.sh — Orquestador principal
# Dev Environment Setup para Debian / Ubuntu
#
# Uso:
#   ./setup.sh                  instalación completa interactiva
#   ./setup.sh --minimal        solo herramientas base (sin GUI)
#   ./setup.sh --dry-run        simula sin ejecutar nada
#   ./setup.sh --minimal --dry-run
#
# Req: Debian 12+ / Ubuntu 22.04+ · usuario normal con sudo
# ============================================================

set -euo pipefail

# ── Resolver directorio raíz del proyecto ────────────────────
SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Cargar utils (colores, logging, run, confirm…) ────────────
# shellcheck source=lib/utils.sh
source "$SETUP_DIR/lib/utils.sh"

# ── Parsear flags ─────────────────────────────────────────────
DRY_RUN=false
MINIMAL=false

_usage() {
  echo ""
  echo -e "  ${BOLD}Uso:${NC} ./setup.sh [opciones]"
  echo ""
  echo "  Opciones:"
  echo "    --dry-run     Simula la instalación sin ejecutar nada"
  echo "    --minimal     Solo herramientas base (sin VSCode, Brave ni fuentes)"
  echo "    --help        Muestra esta ayuda"
  echo ""
}

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true  ;;
    --minimal) MINIMAL=true  ;;
    --help)    _usage; exit 0 ;;
    *) error "Flag desconocido: '$arg'. Usá --help para ver las opciones." ;;
  esac
done

export DRY_RUN
export MINIMAL

# ── Banner ────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
echo "  ██████╗ ███████╗██╗   ██╗    ███████╗███████╗████████╗██╗   ██╗██████╗ "
echo "  ██╔══██╗██╔════╝██║   ██║    ██╔════╝██╔════╝╚══██╔══╝██║   ██║██╔══██╗"
echo "  ██║  ██║█████╗  ██║   ██║    ███████╗█████╗     ██║   ██║   ██║██████╔╝"
echo "  ██║  ██║██╔══╝  ╚██╗ ██╔╝    ╚════██║██╔══╝     ██║   ██║   ██║██╔═══╝ "
echo "  ██████╔╝███████╗ ╚████╔╝     ███████║███████╗   ██║   ╚██████╔╝██║     "
echo "  ╚═════╝ ╚══════╝  ╚═══╝      ╚══════╝╚══════╝   ╚═╝    ╚═════╝ ╚═╝     "
echo -e "${NC}"
echo -e "  ${DIM}Debian / Ubuntu — Dev Environment Setup${NC}"
echo ""

[[ "$DRY_RUN" == true  ]] && echo -e "  ${YELLOW}${BOLD}[MODO DRY-RUN] No se ejecutará ningún cambio real.${NC}\n"
[[ "$MINIMAL"  == true ]] && echo -e "  ${YELLOW}${BOLD}[MODO MINIMAL] Se omitirán VSCode, Brave y fuentes.${NC}\n"

# ── Cargar módulos ────────────────────────────────────────────
# shellcheck source=modules/base.sh
source "$SETUP_DIR/modules/base.sh"
# shellcheck source=modules/vscode.sh
source "$SETUP_DIR/modules/vscode.sh"
# shellcheck source=modules/brave.sh
source "$SETUP_DIR/modules/brave.sh"
# shellcheck source=modules/node.sh
source "$SETUP_DIR/modules/node.sh"
# shellcheck source=modules/fonts.sh
source "$SETUP_DIR/modules/fonts.sh"
# shellcheck source=modules/shell.sh
source "$SETUP_DIR/modules/shell.sh"

# ── Validaciones previas ──────────────────────────────────────
step "Verificando entorno..."

command -v apt &>/dev/null \
  || error "Este script requiere un sistema basado en Debian/Ubuntu (apt)."

[[ "$EUID" -ne 0 ]] \
  || error "No ejecutes este script como root. Usá tu usuario normal con sudo disponible."

if [[ "$DRY_RUN" != true ]]; then
  sudo -v || error "Se requiere acceso sudo."
fi

ARCH=$(dpkg --print-architecture)
export ARCH
[[ "$ARCH" =~ ^(amd64|arm64|armhf)$ ]] \
  || warn "Arquitectura '$ARCH' no probada. Algunos repos pueden no estar disponibles."

ok "Sistema: $(lsb_release -ds 2>/dev/null || echo 'Debian/Ubuntu') [$ARCH]"

# ── Preguntas iniciales ───────────────────────────────────────
separator
echo ""
echo -e "  ${BOLD}Antes de arrancar, configuremos algunas preferencias:${NC}"
echo ""

# ·· Shell ·····················································
echo -e "  ${BOLD}1. ¿Qué shell preferís?${NC}"
echo ""
echo -e "     ${BOLD}[1]${NC}  Bash  ${DIM}— tuneado con prompt, info git/venv${NC}"
echo -e "     ${BOLD}[2]${NC}  Zsh   ${DIM}— Oh My Zsh + autosuggestions + syntax highlighting${NC}"
echo ""

SHELL_CHOICE=""
while true; do
  read -rp "  Elegí una opción [1/2]: " _SC
  case "$_SC" in
    1) SHELL_CHOICE="bash"; break ;;
    2) SHELL_CHOICE="zsh";  break ;;
    *) warn "Ingresá 1 (Bash) o 2 (Zsh)." ;;
  esac
done
export SHELL_CHOICE

# ·· Tema de prompt ·············································
echo ""
separator
echo ""
echo -e "  ${BOLD}2. ¿Qué tema de colores querés para el prompt?${NC}"
echo ""
echo -e "     ${BOLD}[1]${NC}  Nord        ${DIM}— Azules fríos y verdes apagados (el clásico)${NC}"
echo -e "     ${BOLD}[2]${NC}  Dracula     ${DIM}— Púrpuras, rosas y verdes vibrantes${NC}"
echo -e "     ${BOLD}[3]${NC}  Gruvbox     ${DIM}— Marrones cálidos y amarillos retro${NC}"
echo -e "     ${BOLD}[4]${NC}  Catppuccin  ${DIM}— Pasteles suaves, moderno y relajado${NC}"
echo ""

THEME_CHOICE=""
while true; do
  read -rp "  Elegí un tema [1-4]: " _TC
  case "$_TC" in
    1) THEME_CHOICE="nord";       break ;;
    2) THEME_CHOICE="dracula";    break ;;
    3) THEME_CHOICE="gruvbox";    break ;;
    4) THEME_CHOICE="catppuccin"; break ;;
    *) warn "Ingresá un número entre 1 y 4." ;;
  esac
done
export THEME_CHOICE

# ·· Node Version Manager ·······································
echo ""
separator
echo ""
echo -e "  ${BOLD}3. ¿Qué manager de versiones de Node.js querés usar?${NC}"
echo ""
echo -e "     ${BOLD}[1]${NC}  NVM  ${DIM}— Node Version Manager. El estándar histórico, ampliamente documentado.${NC}"
echo -e "     ${BOLD}[2]${NC}  FNM  ${DIM}— Fast Node Manager. Escrito en Rust, más rápido, compatible con .nvmrc.${NC}"
echo ""

# Detectar instalaciones existentes y avisar
_NVM_INSTALLED=false
_FNM_INSTALLED=false
[ -d "$HOME/.nvm" ]             && _NVM_INSTALLED=true
command -v fnm &>/dev/null      && _FNM_INSTALLED=true

if [[ "$_NVM_INSTALLED" == true ]]; then
  echo -e "  ${YELLOW}⚠  NVM detectado en ${HOME}/.nvm${NC}"
fi
if [[ "$_FNM_INSTALLED" == true ]]; then
  echo -e "  ${YELLOW}⚠  FNM detectado en PATH ($(command -v fnm))${NC}"
fi
[[ "$_NVM_INSTALLED" == true || "$_FNM_INSTALLED" == true ]] && echo ""

NODE_MANAGER_CHOICE=""
while true; do
  read -rp "  Elegí una opción [1/2]: " _NM
  case "$_NM" in
    1) NODE_MANAGER_CHOICE="nvm"; break ;;
    2) NODE_MANAGER_CHOICE="fnm"; break ;;
    *) warn "Ingresá 1 (NVM) o 2 (FNM)." ;;
  esac
done
export NODE_MANAGER_CHOICE

# ·· Git config ·················································
echo ""
separator
echo ""
echo -e "  ${BOLD}4. Configuración de Git${NC}"
echo ""

GIT_NAME=""
GIT_EMAIL=""

_CURRENT_GIT_NAME=$(git config --global user.name  2>/dev/null || echo "")
_CURRENT_GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

if [[ -n "$_CURRENT_GIT_NAME" && -n "$_CURRENT_GIT_EMAIL" ]]; then
  echo -e "  ${YELLOW}⚠  Git ya configurado:${NC}"
  echo -e "     Nombre: ${BOLD}${_CURRENT_GIT_NAME}${NC}"
  echo -e "     Email:  ${BOLD}${_CURRENT_GIT_EMAIL}${NC}"
  echo ""
  if confirm "¿Querés modificar la configuración de Git?"; then
    _ASK_GIT=true
  else
    GIT_NAME="$_CURRENT_GIT_NAME"
    GIT_EMAIL="$_CURRENT_GIT_EMAIL"
    ok "Se mantiene la configuración actual de Git"
    _ASK_GIT=false
  fi
else
  _ASK_GIT=true
fi

if [[ "${_ASK_GIT:-false}" == true ]]; then
  echo ""
  read -rp "  Nombre para Git (ej: Juan Pérez): " GIT_NAME
  read -rp "  Email para Git  (ej: juan@mail.com): " GIT_EMAIL

  [[ -n "$GIT_NAME"  ]] || error "El nombre de Git no puede estar vacío."
  [[ "$GIT_EMAIL" == *@*.* ]] || error "El email '$GIT_EMAIL' no parece válido."
fi

export GIT_NAME
export GIT_EMAIL

# ── Resumen de configuración elegida ─────────────────────────
separator
echo ""
echo -e "  ${BOLD}Configuración seleccionada:${NC}"
echo ""
echo -e "  ${GREEN}✔${NC}  Shell:          ${BOLD}${SHELL_CHOICE}${NC}"
echo -e "  ${GREEN}✔${NC}  Tema:           ${BOLD}${THEME_CHOICE}${NC}"
echo -e "  ${GREEN}✔${NC}  Node manager:   ${BOLD}${NODE_MANAGER_CHOICE^^}${NC}"
echo -e "  ${GREEN}✔${NC}  Git:            ${BOLD}${GIT_NAME}${NC} <${GIT_EMAIL}>"
[[ "$MINIMAL"  == true ]] && echo -e "  ${GREEN}✔${NC}  Modo:           ${BOLD}minimal${NC} (sin VSCode, Brave ni fuentes)"
[[ "$DRY_RUN"  == true ]] && echo -e "  ${GREEN}✔${NC}  Modo:           ${BOLD}dry-run${NC} (simulación)"
echo ""

if ! confirm "¿Querés continuar con la instalación?"; then
  echo ""
  warn "Instalación cancelada por el usuario."
  exit 0
fi

# ── Ejecutar módulos ──────────────────────────────────────────
module_base

if [[ "$MINIMAL" != true ]]; then
  module_vscode
  module_brave
fi

module_node   # Usa NODE_MANAGER_CHOICE internamente

if [[ "$MINIMAL" != true ]]; then
  module_fonts
fi

module_shell  # Usa NODE_MANAGER_CHOICE para escribir el bloque correcto en el rc file

# ── Configurar Git ────────────────────────────────────────────
step "Configurando Git..."

run "git config --global user.name  \"${GIT_NAME}\""
run "git config --global user.email \"${GIT_EMAIL}\""
run "git config --global init.defaultBranch main"
run "git config --global core.autocrlf input"
run "git config --global pull.rebase false"

if [[ "$DRY_RUN" != true ]]; then
  ok "Git configurado: ${GIT_NAME} <${GIT_EMAIL}>"
  ok "Branch por defecto: main"
fi

# ── Resumen final ─────────────────────────────────────────────
separator
echo ""
echo -e "${GREEN}${BOLD}  ╔══════════════════════════════════════════╗"
echo -e "  ║      ✅  Setup completado exitosamente   ║"
echo -e "  ╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}✔${NC}  Git              $(git --version 2>/dev/null)"
echo -e "  ${GREEN}✔${NC}  Python           $(python3 --version 2>/dev/null)"

if [[ "$MINIMAL" != true ]]; then
  echo -e "  ${GREEN}✔${NC}  VSCode           $(code --version 2>/dev/null | head -1 || echo 'instalado')"
  echo -e "  ${GREEN}✔${NC}  Brave            $(brave-browser --version 2>/dev/null | head -1 || echo 'instalado')"
  echo -e "  ${GREEN}✔${NC}  Cascadia Code    ${CASCADIA_VERSION:-'(sin cambios)'}"
fi

# Mostrar versión del node manager activo
case "$NODE_MANAGER_CHOICE" in
  fnm)
    FNM_VER=$(fnm --version 2>/dev/null || echo "instalado")
    echo -e "  ${GREEN}✔${NC}  FNM              ${FNM_VER}"
    ;;
  nvm)
    # NVM no es un binario, leer versión del archivo de release si existe
    NVM_VER=$(cat "$HOME/.nvm/package.json" 2>/dev/null \
              | grep '"version"' | head -1 | cut -d'"' -f4 \
              || echo "instalado")
    echo -e "  ${GREEN}✔${NC}  NVM              ${NVM_VER}"
    ;;
esac

echo -e "  ${GREEN}✔${NC}  Node / npm       $(node --version 2>/dev/null) / $(npm --version 2>/dev/null)${NODE_SELECTED_VERSION:+ — default: $NODE_SELECTED_VERSION}"
echo -e "  ${GREEN}✔${NC}  Shell            ${SHELL_CHOICE} · tema ${THEME_CHOICE}"
echo -e "  ${GREEN}✔${NC}  Git user         ${GIT_NAME} <${GIT_EMAIL}>"
echo ""

# Instrucción final según el shell elegido
if [[ "$SHELL_CHOICE" == "zsh" ]]; then
  echo -e "  ${YELLOW}${BOLD}➜  Cerrá sesión y volvé a entrar para activar Zsh como shell default.${NC}"
  echo -e "  ${DIM}   O ejecutá manualmente: exec zsh${NC}"
else
  echo -e "  ${YELLOW}${BOLD}➜  Ejecutá 'source ~/.bashrc' o abrí una nueva terminal para aplicar los cambios.${NC}"
fi

echo ""