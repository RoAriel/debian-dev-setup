#!/usr/bin/env bash
# ============================================================
# themes/nord.sh — Paleta Nord
# https://www.nordtheme.com
#
# Azules fríos del ártico, verdes apagados y rojos suaves.
# El tema original del proyecto.
# ============================================================

[[ -n "${_THEME_LOADED:-}" ]] && return 0
_THEME_LOADED=1

THEME_NAME="Nord"

# ── Colores del prompt ────────────────────────────────────────
# Usuario normal       — Nord8  #88C0D0  Frost cyan
THEME_USER="\e[1;38;2;136;192;208m"

# Root / error         — Nord11 #BF616A  Aurora red
THEME_ROOT="\e[1;38;2;191;97;106m"

# Directorio actual    — Nord8  #88C0D0  Frost cyan
THEME_PATH="\e[38;2;136;192;208m"

# Rama git             — Nord9  #81A1C1  Frost blue
THEME_GIT="\e[38;2;129;161;193m"

# Rama limpia / OK     — Nord14 #A3BE8C  Aurora green
THEME_OK="\e[38;2;163;190;140m"

# Rama sucia / error   — Nord11 #BF616A  Aurora red
THEME_ERROR="\e[1;38;2;191;97;106m"

# Entorno virtual      — Nord7  #8FBCBB  Frost teal
THEME_VENV="\e[1;38;2;143;188;187m"
