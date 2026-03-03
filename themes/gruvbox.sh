#!/usr/bin/env bash
# ============================================================
# themes/gruvbox.sh — Paleta Gruvbox (Dark)
# https://github.com/morhetz/gruvbox
#
# Marrones cálidos, amarillos retro y naranjas terrosos.
# ============================================================

[[ -n "${_THEME_LOADED:-}" ]] && return 0
_THEME_LOADED=1

THEME_NAME="Gruvbox"

# ── Colores del prompt ────────────────────────────────────────
# Usuario normal       — #83A598  Aqua
THEME_USER="\e[1;38;2;131;165;152m"

# Root / error         — #FB4934  Red bright
THEME_ROOT="\e[1;38;2;251;73;52m"

# Directorio actual    — #83A598  Aqua
THEME_PATH="\e[38;2;131;165;152m"

# Rama git             — #458588  Blue
THEME_GIT="\e[38;2;69;133;136m"

# Rama limpia / OK     — #B8BB26  Yellow-green
THEME_OK="\e[38;2;184;187;38m"

# Rama sucia / error   — #FB4934  Red bright
THEME_ERROR="\e[1;38;2;251;73;52m"

# Entorno virtual      — #FABD2F  Yellow
THEME_VENV="\e[1;38;2;250;189;47m"
