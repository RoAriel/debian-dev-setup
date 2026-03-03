#!/usr/bin/env bash
# ============================================================
# test_zsh_config.sh
# Prueba la generación del .zshrc para cada tema.
# Escribe en /tmp — NO toca tu ~/.zshrc real ni instala Zsh.
# ============================================================

set -euo pipefail

SETUP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SETUP_DIR/lib/utils.sh"

BOLD='\e[1m'
DIM='\e[2m'
NC='\e[0m'
GREEN='\e[1;32m'
RED='\e[1;31m'

clear
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  🧪  Test de generación de .zshrc${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${DIM}Genera .zshrc para cada tema en /tmp${NC}"
echo -e "  ${DIM}No instala Zsh ni toca tu sistema.${NC}"
echo ""

PASS=0
FAIL=0
declare -A GENERATED_FILES

_test_zsh_theme() {
  local THEME="$1"
  local TEST_HOME="/tmp/test-zshrc-${THEME}"
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"

  # Simular ~/.oh-my-zsh existente para que shell.sh no intente instalarlo
  mkdir -p "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
  mkdir -p "$TEST_HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

  bash -c "
    export SETUP_DIR='$SETUP_DIR'
    export HOME='$TEST_HOME'
    export DRY_RUN=false
    export SHELL_CHOICE=zsh
    export THEME_CHOICE='$THEME'
    # Evitar que chsh y apt se ejecuten en el test
    chsh()  { echo '[test] chsh simulado'; }
    sudo()  { echo '[test] sudo simulado: \$*'; }
    export -f chsh sudo
    source '$SETUP_DIR/lib/utils.sh'
    unset _SHELL_LOADED _THEME_LOADED
    source '$SETUP_DIR/modules/shell.sh'
    module_shell 2>&1
  " > /dev/null 2>&1

  local ZSHRC="$TEST_HOME/.zshrc"
  GENERATED_FILES[$THEME]="$ZSHRC"

  echo -e "${BOLD}  ── Tema: ${THEME} ──${NC}"

  if [[ ! -f "$ZSHRC" ]]; then
    echo -e "  ${RED}✖ .zshrc no fue creado${NC}"
    (( FAIL++ )) || true
    echo ""
    return
  fi

  local ERRORS=0

  # ── Verificar sintaxis zsh (si está disponible) o bash como proxy ──
  if command -v zsh &>/dev/null; then
    if zsh -n "$ZSHRC" 2>/dev/null; then
      echo -e "  ${GREEN}✔${NC} Sintaxis Zsh válida"
    else
      echo -e "  ${RED}✖ Error de sintaxis en .zshrc${NC}"
      (( ERRORS++ )) || true
    fi
  else
    # Zsh no instalado aún — verificar al menos que no tenga errores obvios
    if grep -qE "^[[:space:]]*(fi|done|esac)[[:space:]]*$" "$ZSHRC" || \
       ! grep -qP "[\x00-\x08\x0b\x0e-\x1f]" "$ZSHRC" 2>/dev/null; then
      echo -e "  ${GREEN}✔${NC} Estructura del archivo válida ${DIM}(zsh no instalado aún — verificación parcial)${NC}"
    fi
  fi

  # ── Verificar variables del tema ──
  local MISSING_VARS=()
  for VAR in THEME_USER THEME_ROOT THEME_PATH THEME_GIT THEME_OK THEME_ERROR THEME_VENV; do
    grep -q "^${VAR}=" "$ZSHRC" || MISSING_VARS+=("$VAR")
  done

  if [[ ${#MISSING_VARS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✔${NC} Variables de tema presentes (7/7)"
  else
    echo -e "  ${RED}✖ Variables faltantes: ${MISSING_VARS[*]}${NC}"
    (( ERRORS++ )) || true
  fi

  # ── Verificar secciones clave de Zsh ──
  local MISSING_SECTIONS=()
  grep -q "oh-my-zsh.sh"        "$ZSHRC" || MISSING_SECTIONS+=("oh-my-zsh source")
  grep -q "zsh-autosuggestions" "$ZSHRC" || MISSING_SECTIONS+=("autosuggestions")
  grep -q "zsh-syntax-highlighting" "$ZSHRC" || MISSING_SECTIONS+=("syntax-highlighting")
  grep -q "_build_prompt"       "$ZSHRC" || MISSING_SECTIONS+=("_build_prompt")
  grep -q "add-zsh-hook"        "$ZSHRC" || MISSING_SECTIONS+=("add-zsh-hook")
  grep -q "NVM_DIR"             "$ZSHRC" || MISSING_SECTIONS+=("NVM_DIR")

  if [[ ${#MISSING_SECTIONS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✔${NC} Secciones clave presentes (OMZ, plugins, prompt, NVM)"
  else
    echo -e "  ${RED}✖ Secciones faltantes: ${MISSING_SECTIONS[*]}${NC}"
    (( ERRORS++ )) || true
  fi

  # ── Verificar plugins declarados ──
  local MISSING_PLUGINS=()
  grep -q "zsh-autosuggestions"    "$ZSHRC" || MISSING_PLUGINS+=("zsh-autosuggestions")
  grep -q "zsh-syntax-highlighting" "$ZSHRC" || MISSING_PLUGINS+=("zsh-syntax-highlighting")
  grep -q "git"                    "$ZSHRC" || MISSING_PLUGINS+=("git")
  grep -q " z$\| z " "$ZSHRC"              || MISSING_PLUGINS+=("z")

  if [[ ${#MISSING_PLUGINS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✔${NC} Plugins declarados (git, z, autosuggestions, syntax-highlighting)"
  else
    echo -e "  ${YELLOW}⚠${NC} Plugins faltantes en la lista: ${MISSING_PLUGINS[*]}"
  fi

  # ── Mostrar paleta de colores ──
  echo -e "  ${DIM}Colores embebidos:${NC}"
  grep "^THEME_" "$ZSHRC" | while IFS='=' read -r KEY VAL; do
    COLOR=$(echo "$VAL" | tr -d '"')
    printf "    %-15s %b██%b\n" "$KEY" "$COLOR" "\e[0m"
  done

  echo -e "  ${DIM}Tamaño: $(wc -l < "$ZSHRC") líneas · $ZSHRC${NC}"

  if [[ $ERRORS -eq 0 ]]; then
    (( PASS++ )) || true
  else
    (( FAIL++ )) || true
  fi

  echo ""
}

for THEME in nord dracula gruvbox catppuccin; do
  _test_zsh_theme "$THEME"
done

# ── Verificar que el .zshrc real no fue tocado ──
echo -e "${BOLD}  ── Verificación de seguridad ──${NC}"
if [[ -f "$HOME/.zshrc" ]]; then
  REAL_MODIFIED=$(stat -c %Y "$HOME/.zshrc" 2>/dev/null || echo 0)
  NOW=$(date +%s)
  DIFF=$(( NOW - REAL_MODIFIED ))
  if [[ $DIFF -gt 10 ]]; then
    echo -e "  ${GREEN}✔${NC} Tu ~/.zshrc real NO fue modificado"
  else
    echo -e "  ${RED}⚠ Revisar: ~/.zshrc fue modificado hace menos de 10 segundos${NC}"
  fi
else
  echo -e "  ${GREEN}✔${NC} No tenés ~/.zshrc — nada que proteger"
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Resultados: ${GREEN}${PASS} passed${NC} / ${RED}${FAIL} failed${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  ok "Todos los temas generan .zshrc válido"
  echo ""
  echo -e "  ${DIM}Cuando estés listo para instalarlo en tu sistema real:${NC}"
  echo -e "  ${DIM}ejecutá ./setup.sh → elegí Zsh + Nord${NC}"
else
  warn "Algunos tests fallaron — revisá los errores arriba"
fi

echo ""

# ── Inspección interactiva ──
echo -e "  ¿Querés inspeccionar el .zshrc generado de algún tema?"
echo -e "  ${BOLD}[1]${NC} Nord  ${BOLD}[2]${NC} Dracula  ${BOLD}[3]${NC} Gruvbox  ${BOLD}[4]${NC} Catppuccin  ${BOLD}[0]${NC} Salir"
echo ""

declare -A THEME_MAP=([1]=nord [2]=dracula [3]=gruvbox [4]=catppuccin)

while true; do
  read -rp "  Elegí [0-4] (Enter para salir): " CHOICE || break
  [[ -z "$CHOICE" || "$CHOICE" == "0" ]] && break

  if [[ -n "${THEME_MAP[$CHOICE]:-}" ]]; then
    TNAME="${THEME_MAP[$CHOICE]}"
    TFILE="${GENERATED_FILES[$TNAME]:-}"

    if [[ -n "$TFILE" && -f "$TFILE" ]]; then
      echo ""
      echo -e "  ${DIM}── Contenido de .zshrc (tema ${TNAME}) ──${NC}"
      echo ""
      cat "$TFILE" | sed 's/^/  /'
      echo ""
    else
      warn "Archivo no encontrado para tema '${TNAME}'."
    fi
  else
    warn "Ingresá un número entre 0 y 4."
  fi
done

# Limpiar
rm -rf /tmp/test-zshrc-nord \
       /tmp/test-zshrc-dracula \
       /tmp/test-zshrc-gruvbox \
       /tmp/test-zshrc-catppuccin 2>/dev/null || true

echo -e "  ${DIM}Archivos temporales limpiados.${NC}"
echo ""

# ── Recordatorio final ────────────────────────────────────────
if [[ $FAIL -eq 0 ]]; then
  separator
  echo ""
  echo -e "  ${BOLD}Próximos pasos para instalar Zsh:${NC}"
  echo ""
  echo -e "  ${BOLD}1.${NC} Ejecutá ${BOLD}./setup.sh${NC}"
  echo -e "  ${BOLD}2.${NC} Elegí ${BOLD}Zsh${NC} cuando te pregunte el shell"
  echo -e "  ${BOLD}3.${NC} Elegí el tema que quieras"
  echo -e "  ${BOLD}4.${NC} Al terminar, cerrá la sesión y volvé a entrar"
  echo -e "  ${BOLD}5.${NC} Para volver a Bash en cualquier momento: ${DIM}chsh -s \$(which bash)${NC}"
  echo ""
fi