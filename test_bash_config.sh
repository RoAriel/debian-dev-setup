#!/usr/bin/env bash
# ============================================================
# test_bash_config.sh
# Prueba la generación del .bashrc para cada tema.
# Escribe en /tmp — NO toca tu ~/.bashrc real.
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
echo -e "${BOLD}  🧪  Test de generación de .bashrc${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  ${DIM}Genera .bashrc para cada tema en /tmp${NC}"
echo -e "  ${DIM}No toca tu ~/.bashrc real.${NC}"
echo ""

PASS=0
FAIL=0

# Mapa tema → ruta del .bashrc generado (para inspección posterior)
declare -A GENERATED_FILES

_test_bash_theme() {
  local THEME="$1"

  # Crear directorio temporal con nombre fijo y conocido
  local TEST_HOME="/tmp/test-bashrc-${THEME}"
  rm -rf "$TEST_HOME"
  mkdir -p "$TEST_HOME"

  bash -c "
    export SETUP_DIR='$SETUP_DIR'
    export HOME='$TEST_HOME'
    export DRY_RUN=false
    export SHELL_CHOICE=bash
    export THEME_CHOICE='$THEME'
    source '$SETUP_DIR/lib/utils.sh'
    unset _SHELL_LOADED _THEME_LOADED
    source '$SETUP_DIR/modules/shell.sh'
    module_shell 2>&1
  " > /dev/null 2>&1

  local BASHRC="$TEST_HOME/.bashrc"

  # Guardar ruta para poder inspeccionarla después
  GENERATED_FILES[$THEME]="$BASHRC"

  echo -e "${BOLD}  ── Tema: ${THEME} ──${NC}"

  if [[ ! -f "$BASHRC" ]]; then
    echo -e "  ${RED}✖ .bashrc no fue creado${NC}"
    (( FAIL++ )) || true
    echo ""
    return
  fi

  local ERRORS=0

  # Verificar sintaxis bash
  if bash -n "$BASHRC" 2>/dev/null; then
    echo -e "  ${GREEN}✔${NC} Sintaxis bash válida"
  else
    echo -e "  ${RED}✖ Error de sintaxis en .bashrc${NC}"
    (( ERRORS++ )) || true
  fi

  # Verificar variables del tema
  local MISSING_VARS=()
  for VAR in THEME_USER THEME_ROOT THEME_PATH THEME_GIT THEME_OK THEME_ERROR THEME_VENV; do
    grep -q "^${VAR}=" "$BASHRC" || MISSING_VARS+=("$VAR")
  done

  if [[ ${#MISSING_VARS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✔${NC} Variables de tema presentes (7/7)"
  else
    echo -e "  ${RED}✖ Variables faltantes: ${MISSING_VARS[*]}${NC}"
    (( ERRORS++ )) || true
  fi

  # Verificar secciones clave
  local MISSING_SECTIONS=()
  grep -q "build_prompt"    "$BASHRC" || MISSING_SECTIONS+=("build_prompt")
  grep -q "PROMPT_COMMAND"  "$BASHRC" || MISSING_SECTIONS+=("PROMPT_COMMAND")
  grep -q "NVM_DIR"         "$BASHRC" || MISSING_SECTIONS+=("NVM_DIR")
  grep -q "bash_completion" "$BASHRC" || MISSING_SECTIONS+=("bash_completion")

  if [[ ${#MISSING_SECTIONS[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✔${NC} Secciones clave presentes (build_prompt, PROMPT_COMMAND, NVM, completion)"
  else
    echo -e "  ${RED}✖ Secciones faltantes: ${MISSING_SECTIONS[*]}${NC}"
    (( ERRORS++ )) || true
  fi

  # Mostrar paleta de colores embebidos
  echo -e "  ${DIM}Colores embebidos:${NC}"
  grep "^THEME_" "$BASHRC" | while IFS='=' read -r KEY VAL; do
    COLOR=$(echo "$VAL" | tr -d '"')
    printf "    %-15s %b██%b\n" "$KEY" "$COLOR" "\e[0m"
  done

  echo -e "  ${DIM}Tamaño: $(wc -l < "$BASHRC") líneas · $BASHRC${NC}"

  if [[ $ERRORS -eq 0 ]]; then
    (( PASS++ )) || true
  else
    (( FAIL++ )) || true
  fi

  echo ""
}

for THEME in nord dracula gruvbox catppuccin; do
  _test_bash_theme "$THEME"
done

# Verificar que el .bashrc real no fue tocado
echo -e "${BOLD}  ── Verificación de seguridad ──${NC}"
REAL_MODIFIED=$(stat -c %Y "$HOME/.bashrc" 2>/dev/null || echo 0)
NOW=$(date +%s)
DIFF=$(( NOW - REAL_MODIFIED ))
if [[ $DIFF -gt 10 ]]; then
  echo -e "  ${GREEN}✔${NC} Tu ~/.bashrc real NO fue modificado"
else
  echo -e "  ${RED}⚠ Revisar: ~/.bashrc fue modificado hace menos de 10 segundos${NC}"
fi

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "  Resultados: ${GREEN}${PASS} passed${NC} / ${RED}${FAIL} failed${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
  ok "Todos los temas generan .bashrc válido"
  echo ""
  echo -e "  ${DIM}Cuando estés listo para aplicar uno a tu ~/.bashrc real,${NC}"
  echo -e "  ${DIM}ejecutá: ./setup.sh (elegí el tema que quieras)${NC}"
else
  warn "Algunos tests fallaron — revisá los errores arriba"
fi

echo ""

# Inspección interactiva — ahora con rutas conocidas y confiables
echo -e "  ¿Querés inspeccionar el .bashrc generado de algún tema?"
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
      echo -e "  ${DIM}── Contenido de .bashrc (tema ${TNAME}) ──${NC}"
      echo ""
      cat "$TFILE" | sed 's/^/  /'
      echo ""
    else
      warn "Archivo no encontrado para tema '${TNAME}' — puede que el test haya fallado."
    fi
  else
    warn "Ingresá un número entre 0 y 4."
  fi
done

# Limpiar
rm -rf /tmp/test-bashrc-nord \
       /tmp/test-bashrc-dracula \
       /tmp/test-bashrc-gruvbox \
       /tmp/test-bashrc-catppuccin 2>/dev/null || true

echo -e "  ${DIM}Archivos temporales limpiados.${NC}"
echo ""