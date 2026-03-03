#!/usr/bin/env bash
# ============================================================
# themes/dracula.sh — Paleta Dracula
# https://draculatheme.com
#
# Púrpuras profundos, rosas vibrantes y verdes eléctricos.
# ============================================================

[[ -n "${_THEME_LOADED:-}" ]] && return 0
_THEME_LOADED=1

THEME_NAME="Dracula"

# ── Colores del prompt ────────────────────────────────────────
# Usuario normal       — #BD93F9  Purple
THEME_USER="\e[1;38;2;189;147;249m"

# Root / error         — #FF5555  Red
THEME_ROOT="\e[1;38;2;255;85;85m"

# Directorio actual    — #8BE9FD  Cyan
THEME_PATH="\e[38;2;139;233;253m"

# Rama git             — #6272A4  Comment (blue-grey)
THEME_GIT="\e[38;2;98;114;164m"

# Rama limpia / OK     — #50FA7B  Green
THEME_OK="\e[38;2;80;250;123m"

# Rama sucia / error   — #FF5555  Red
THEME_ERROR="\e[1;38;2;255;85;85m"

# Entorno virtual      — #F1FA8C  Yellow
THEME_VENV="\e[1;38;2;241;250;140m"
