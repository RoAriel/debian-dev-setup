#!/usr/bin/env bash
# ============================================================
# themes/catppuccin.sh — Paleta Catppuccin (Mocha)
# https://github.com/catppuccin/catppuccin
#
# Pasteles suaves sobre fondo oscuro. Moderno y relajado.
# Variante: Mocha (la más oscura y popular para terminales)
# ============================================================

[[ -n "${_THEME_LOADED:-}" ]] && return 0
_THEME_LOADED=1

THEME_NAME="Catppuccin Mocha"

# ── Colores del prompt ────────────────────────────────────────
# Usuario normal       — #89DCEB  Sky
THEME_USER="\e[1;38;2;137;220;235m"

# Root / error         — #F38BA8  Red
THEME_ROOT="\e[1;38;2;243;139;168m"

# Directorio actual    — #89B4FA  Blue
THEME_PATH="\e[38;2;137;180;250m"

# Rama git             — #CBA6F7  Mauve (purple)
THEME_GIT="\e[38;2;203;166;247m"

# Rama limpia / OK     — #A6E3A1  Green
THEME_OK="\e[38;2;166;227;161m"

# Rama sucia / error   — #F38BA8  Red
THEME_ERROR="\e[1;38;2;243;139;168m"

# Entorno virtual      — #F9E2AF  Yellow
THEME_VENV="\e[1;38;2;249;226;175m"
