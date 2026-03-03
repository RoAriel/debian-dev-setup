# Changelog

Todos los cambios notables de este proyecto se documentan acá.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/1.0.0/).
Versionado basado en [Semantic Versioning](https://semver.org/).

---

## [1.0.0] - 2026-03-02 — _Initial release_

### Arquitectura

- Proyecto armado en estructura modular: `lib/`, `modules/`, `themes/`
- `setup.sh` como orquestador puro: parsea flags, recolecta preferencias, llama módulos
- `lib/utils.sh` con helpers compartidos: `step()`, `ok()`, `warn()`, `error()`, `skipped()`, `run()`, `confirm()`, `require()`
- Guard de doble `source` en todos los archivos (`_X_LOADED`)
- Cada módulo exporta una función `module_X()` como punto de entrada

### Flags

- `--dry-run`: simula toda la instalación sin ejecutar ningún cambio real
- `--minimal`: omite VSCode, Brave y fuentes — útil para servidores o VMs
- `--help`: muestra uso y opciones disponibles

### Instalación de herramientas

- **base.sh**: apt, git, python3, pip, venv, build-essential, curl, wget, fontconfig
- **vscode.sh**: VSCode desde repo oficial de Microsoft — keyring en `/etc/apt/keyrings/` (Debian 12+)
- **brave.sh**: Brave Browser desde repo oficial
- **node.sh**: NVM con versión resuelta dinámicamente desde GitHub API + selector interactivo de versión de Node.js desde `nodejs.org/dist/index.json`
- **fonts.sh**: Cascadia Code desde GitHub Releases con metadato `.installed-version` para detección de actualizaciones

### Shell y prompt

- **modules/shell.sh**: bifurcación completa Bash / Zsh según elección del usuario
- **Bash**: `.bashrc` con `build_prompt()`, NVM, historial extendido, bash completion, globbing
- **Zsh**: `.zshrc` con Oh My Zsh, plugins `zsh-autosuggestions`, `zsh-syntax-highlighting`, `git`, `z` y prompt personalizado con `add-zsh-hook precmd`
- `chsh` automático al elegir Zsh
- Backup con timestamp de `.bashrc` / `.zshrc` antes de sobreescribir

### Temas de prompt

- **themes/nord.sh**: paleta Nord — azules fríos y verdes apagados
- **themes/dracula.sh**: paleta Dracula — púrpuras y verdes eléctricos
- **themes/gruvbox.sh**: paleta Gruvbox Dark — marrones cálidos y amarillos retro
- **themes/catppuccin.sh**: paleta Catppuccin Mocha — pasteles suaves
- Cada tema define 7 variables de color (`THEME_USER`, `THEME_ROOT`, `THEME_PATH`, `THEME_GIT`, `THEME_OK`, `THEME_ERROR`, `THEME_VENV`)
- Colores embebidos directamente en `.bashrc`/`.zshrc` generado — sin dependencias en tiempo de ejecución

### Configuración de Git

- Preguntas interactivas para `user.name` y `user.email`
- Detecta configuración existente y ofrece mantenerla o modificarla
- Configura automáticamente: `init.defaultBranch=main`, `core.autocrlf=input`, `pull.rebase=false`

### Validaciones

- Detecta sistema basado en `apt` (Debian/Ubuntu)
- Bloquea ejecución como root
- Verifica acceso sudo antes de continuar
- Detecta y exporta arquitectura del sistema (`amd64`, `arm64`, `armhf`)
- Confirmación final con resumen de opciones elegidas antes de ejecutar

---

## Cómo versionar

Al agregar cambios futuros, crear una nueva sección encima de esta siguiendo el formato:

```markdown
## [1.1.0] - YYYY-MM-DD

### Agregado

- ...

### Modificado

- ...

### Corregido

- ...
```

Tipos de cambio: `Agregado`, `Modificado`, `Corregido`, `Eliminado`, `Seguridad`.
