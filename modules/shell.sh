#!/usr/bin/env bash
# ============================================================
# modules/shell.sh
# Configura el shell elegido (Bash o Zsh + Oh My Zsh)
# aplicando el tema de colores seleccionado.
#
# Variables requeridas del orquestador:
#   SHELL_CHOICE  — "bash" o "zsh"
#   THEME_CHOICE  — "nord" | "dracula" | "gruvbox" | "catppuccin"
#   SETUP_DIR     — ruta absoluta al directorio raíz del proyecto
# ============================================================

[[ -n "${_SHELL_LOADED:-}" ]] && return 0
_SHELL_LOADED=1

# ── Helper: cargar tema ───────────────────────────────────────
_load_theme() {
  local THEME_FILE="$SETUP_DIR/themes/${THEME_CHOICE}.sh"
  [[ -f "$THEME_FILE" ]] || error "Archivo de tema no encontrado: $THEME_FILE"
  unset _THEME_LOADED
  # shellcheck source=themes/nord.sh
  source "$THEME_FILE"
}

# ── Configurar Bash ───────────────────────────────────────────
_setup_bash() {
  step "Configurando Bash + tema ${THEME_NAME}..."

  local BASHRC="$HOME/.bashrc"
  local BACKUP="${BASHRC}.backup.$(date +%Y%m%d_%H%M%S)"

  if [[ "$DRY_RUN" == true ]]; then
    dry_log "cp $BASHRC $BACKUP"
    dry_log "Escribir ~/.bashrc con tema ${THEME_NAME}"
    return 0
  fi

  [[ -f "$BASHRC" ]] && cp "$BASHRC" "$BACKUP" && warn "Backup guardado: $BACKUP"

  # Capturar colores del tema en variables locales
  # para que se expandan correctamente dentro del heredoc
  local T_USER="$THEME_USER" T_ROOT="$THEME_ROOT" T_PATH="$THEME_PATH"
  local T_GIT="$THEME_GIT"   T_OK="$THEME_OK"     T_ERR="$THEME_ERROR"
  local T_VENV="$THEME_VENV" T_NAME="$THEME_NAME"

  cat > "$BASHRC" << BASHRC_EOF
# ==============================
# 🧠 BASICS
# ==============================
case \$- in
  *i*) ;;
  *) return;;
esac

HISTCONTROL=ignoreboth
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend
shopt -s checkwinsize
shopt -s globstar 2>/dev/null

PROMPT_DIRTRIM=3

if [ -x /usr/bin/dircolors ]; then
  eval "\$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
fi

[ -f ~/.bash_aliases ] && . ~/.bash_aliases

if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

export VIRTUAL_ENV_DISABLE_PROMPT=1

# ==============================
# 🎨 PROMPT — Tema: ${T_NAME}
# ==============================
THEME_USER="${T_USER}"
THEME_ROOT="${T_ROOT}"
THEME_PATH="${T_PATH}"
THEME_GIT="${T_GIT}"
THEME_OK="${T_OK}"
THEME_ERROR="${T_ERR}"
THEME_VENV="${T_VENV}"

build_prompt() {
  local EXIT_CODE="\$?"

  local VENV_PART=""
  if [[ -n "\${VIRTUAL_ENV:-}" ]]; then
    VENV_PART="\[\${THEME_VENV}\](🐍 \$(basename "\$VIRTUAL_ENV"))\[\e[0m\] "
  fi

  local USER_PART
  if [[ \$EUID -eq 0 ]]; then
    USER_PART="\[\${THEME_ROOT}\]\u"
  else
    USER_PART="\[\${THEME_USER}\]\u"
  fi

  local PATH_PART="\[\${THEME_PATH}\]\w"

  local GIT_PART=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch
    branch=\$(git symbolic-ref --short HEAD 2>/dev/null \
           || git rev-parse --short HEAD 2>/dev/null)
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
      GIT_PART=" \[\${THEME_GIT}\] \${branch} \[\${THEME_OK}\]●"
    else
      GIT_PART=" \[\${THEME_GIT}\] \${branch} \[\${THEME_ERROR}\]●"
    fi
    GIT_PART+="\[\e[0m\]"
  fi

  local SYMBOL
  if [[ \$EXIT_CODE -ne 0 ]]; then
    SYMBOL="\[\${THEME_ERROR}\]❯"
  elif [[ \$EUID -eq 0 ]]; then
    SYMBOL="\[\${THEME_ROOT}\]#"
  else
    SYMBOL="\[\${THEME_OK}\]❯"
  fi

  PS1="\n\${VENV_PART}\${USER_PART}\[\e[0m\] \${PATH_PART}\[\e[0m\]\${GIT_PART}\n\${SYMBOL}\[\e[0m\] "
}

PROMPT_COMMAND=build_prompt

# ==============================
# 📦 NVM
# ==============================
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ]          && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
BASHRC_EOF

  ok "~/.bashrc configurado con tema ${THEME_NAME}"
}

# ── Configurar Zsh + Oh My Zsh ────────────────────────────────
_setup_zsh() {
  step "Zsh + Oh My Zsh + tema ${THEME_NAME}..."

  # Instalar zsh si no está
  if ! command -v zsh &>/dev/null; then
    echo "  Instalando Zsh..."
    run "sudo apt-get install -y zsh"
  else
    ok "$(zsh --version 2>/dev/null | head -1)"
  fi

  if [[ "$DRY_RUN" == true ]]; then
    dry_log "Instalar Oh My Zsh en ~/.oh-my-zsh"
    dry_log "Instalar plugin: zsh-autosuggestions"
    dry_log "Instalar plugin: zsh-syntax-highlighting"
    dry_log "Escribir ~/.zshrc con tema ${THEME_NAME}"
    dry_log "chsh -s \$(which zsh)"
    return 0
  fi

  # Instalar Oh My Zsh si no está
  if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
    echo "  Instalando Oh My Zsh..."
    RUNZSH=no CHSH=no \
      sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    ok "Oh My Zsh instalado"
  else
    skipped; ok "Oh My Zsh ya instalado"
  fi

  local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

  # Plugin: zsh-autosuggestions
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    echo "  Instalando zsh-autosuggestions..."
    git clone --depth=1 \
      https://github.com/zsh-users/zsh-autosuggestions \
      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    ok "zsh-autosuggestions instalado"
  else
    skipped; ok "zsh-autosuggestions ya instalado"
  fi

  # Plugin: zsh-syntax-highlighting
  if [[ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    echo "  Instalando zsh-syntax-highlighting..."
    git clone --depth=1 \
      https://github.com/zsh-users/zsh-syntax-highlighting \
      "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    ok "zsh-syntax-highlighting instalado"
  else
    skipped; ok "zsh-syntax-highlighting ya instalado"
  fi

  # Backup y escribir ~/.zshrc
  local ZSHRC="$HOME/.zshrc"
  local BACKUP="${ZSHRC}.backup.$(date +%Y%m%d_%H%M%S)"
  [[ -f "$ZSHRC" ]] && cp "$ZSHRC" "$BACKUP" && warn "Backup guardado: $BACKUP"

  # Los colores en THEME_* son strings como "\e[1;38;2;136;192;208m"
  # Para que Zsh los interprete como ESC real, los convertimos con printf
  # y los embebemos directamente en el .zshrc como bytes literales.
  local C_USER C_ROOT C_PATH C_GIT C_OK C_ERR C_VENV C_RESET
  C_USER=$(printf '%b' "$THEME_USER")
  C_ROOT=$(printf '%b' "$THEME_ROOT")
  C_PATH=$(printf '%b' "$THEME_PATH")
  C_GIT=$(printf '%b'  "$THEME_GIT")
  C_OK=$(printf '%b'   "$THEME_OK")
  C_ERR=$(printf '%b'  "$THEME_ERROR")
  C_VENV=$(printf '%b' "$THEME_VENV")
  C_RESET=$(printf '\e[0m')

  # Escribir el .zshrc usando printf para preservar los bytes ESC reales
  # Secciones sin color usan heredoc normal (más legible)
  # La sección del prompt usa printf con las variables expandidas

  # ── Parte 1: OMZ, basics (sin colores) ──
  cat > "$ZSHRC" << 'STATIC_EOF'
# ==============================
# 🧠 OH MY ZSH
# ==============================
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  z
)

source "$ZSH/oh-my-zsh.sh"

# ==============================
# 🧠 BASICS
# ==============================
HISTSIZE=5000
HISTFILESIZE=10000
HIST_STAMPS="yyyy-mm-dd"

setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt AUTO_CD
setopt CORRECT

export VIRTUAL_ENV_DISABLE_PROMPT=1

if [ -x /usr/bin/dircolors ]; then
  eval "$(dircolors -b)"
  alias ls='ls --color=auto'
  alias grep='grep --color=auto'
fi

[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

STATIC_EOF

  # ── Parte 2: variables del tema con bytes ESC reales ──
  # Se escriben con printf >> para que los ESC queden como bytes en el archivo
  printf '# ==============================\n' >> "$ZSHRC"
  printf '# 🎨 PROMPT — Tema: %s\n'  "$THEME_NAME" >> "$ZSHRC"
  printf '# ==============================\n' >> "$ZSHRC"
  printf 'autoload -Uz add-zsh-hook\n\n' >> "$ZSHRC"

  # Escribir cada variable con el byte ESC real embebido
  printf 'THEME_USER="%b"\n'  "$THEME_USER"  >> "$ZSHRC"
  printf 'THEME_ROOT="%b"\n'  "$THEME_ROOT"  >> "$ZSHRC"
  printf 'THEME_PATH="%b"\n'  "$THEME_PATH"  >> "$ZSHRC"
  printf 'THEME_GIT="%b"\n'   "$THEME_GIT"   >> "$ZSHRC"
  printf 'THEME_OK="%b"\n'    "$THEME_OK"    >> "$ZSHRC"
  printf 'THEME_ERROR="%b"\n' "$THEME_ERROR" >> "$ZSHRC"
  printf 'THEME_VENV="%b"\n'  "$THEME_VENV"  >> "$ZSHRC"
  printf '\n' >> "$ZSHRC"

  # ── Parte 3: función del prompt y NVM (sin colores) ──
  cat >> "$ZSHRC" << 'PROMPT_EOF'
# _c: envuelve un color en %{ %} para que Zsh no lo cuente como ancho visible
_c() { printf '%%{%s%%}' "$1"; }

_build_prompt() {
  local EXIT_CODE=$?

  # -- venv --
  local VENV_PART=""
  if [[ -n "${VIRTUAL_ENV:-}" ]]; then
    VENV_PART="$(_c "$THEME_VENV")(🐍 ${VIRTUAL_ENV:t})$(_c $'\e[0m') "
  fi

  # -- usuario --
  local USER_COLOR
  [[ $EUID -eq 0 ]] && USER_COLOR="$THEME_ROOT" || USER_COLOR="$THEME_USER"
  local USER_PART="$(_c "$USER_COLOR")%n$(_c $'\e[0m')"

  # -- directorio --
  local PATH_PART="$(_c "$THEME_PATH")%~$(_c $'\e[0m')"

  # -- git --
  local GIT_PART=""
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    local branch
    branch=$(git symbolic-ref --short HEAD 2>/dev/null \
          || git rev-parse --short HEAD 2>/dev/null)
    if git diff --quiet 2>/dev/null && git diff --cached --quiet 2>/dev/null; then
      GIT_PART=" $(_c "$THEME_GIT") ${branch} $(_c "$THEME_OK")●$(_c $'\e[0m')"
    else
      GIT_PART=" $(_c "$THEME_GIT") ${branch} $(_c "$THEME_ERROR")●$(_c $'\e[0m')"
    fi
  fi

  # -- símbolo final --
  local SYMBOL_COLOR
  if   [[ $EXIT_CODE -ne 0 ]]; then SYMBOL_COLOR="$THEME_ERROR"
  elif [[ $EUID -eq 0      ]]; then SYMBOL_COLOR="$THEME_ROOT"
  else                               SYMBOL_COLOR="$THEME_OK"
  fi
  local SYM; [[ $EUID -eq 0 ]] && SYM="#" || SYM="❯"
  local SYMBOL="$(_c "$SYMBOL_COLOR")${SYM}$(_c $'\e[0m')"

  PROMPT="
${VENV_PART}${USER_PART} ${PATH_PART}${GIT_PART}
${SYMBOL} "
}

add-zsh-hook precmd _build_prompt

# ==============================
# 📦 NVM
# ==============================
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]          && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
PROMPT_EOF

  # Setear Zsh como shell default
  echo "  Seteando Zsh como shell predeterminado..."
  run "chsh -s \$(which zsh)"
  ok "~/.zshrc configurado con tema ${THEME_NAME}"
  warn "Cerrá sesión y volvé a entrar para activar Zsh como shell default"
}

# ── Punto de entrada ──────────────────────────────────────────
module_shell() {
  _load_theme

  case "${SHELL_CHOICE:-bash}" in
    bash) _setup_bash ;;
    zsh)  _setup_zsh  ;;
    *)    error "Shell no reconocido: '${SHELL_CHOICE}'. Debe ser 'bash' o 'zsh'." ;;
  esac
}