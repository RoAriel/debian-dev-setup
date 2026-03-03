# 🚀 debian-dev-setup

Script modular de configuración automática de entorno de desarrollo para **Debian / Ubuntu**.
Instalá todo lo necesario en una máquina nueva con un solo comando, eligiendo tu shell y tu tema de colores.

---

## ¿Qué instala?

| Herramienta        | Descripción                                                                 |
| ------------------ | --------------------------------------------------------------------------- |
| **Git**            | Control de versiones + configuración de `user.name` y `user.email`          |
| **Python 3**       | Lenguaje + pip + venv                                                       |
| **VSCode**         | Editor de código (repo oficial de Microsoft)                                |
| **Brave Browser**  | Navegador (repo oficial de Brave)                                           |
| **NVM + Node.js**  | Gestor de versiones de Node — elegís la versión desde un menú interactivo   |
| **Cascadia Code**  | Fuente tipográfica para terminal y editor, con detección de actualizaciones |
| **Shell + Prompt** | Bash tuneado **o** Zsh + Oh My Zsh, con el tema de colores que elijas       |

---

## Requisitos

- Debian 12+ o Ubuntu 22.04+
- Arquitecturas soportadas: `amd64`, `arm64`, `armhf`
- Usuario normal con acceso `sudo` — **no ejecutar como root**
- Conexión a internet

---

## Instalación

```bash
# Clonar el repositorio
git clone https://github.com/RoAriel/debian-dev-setup.git
cd debian-dev-setup

# Dar permisos y ejecutar
chmod +x setup.sh
./setup.sh
```

O sin clonar, directamente desde GitHub:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/RoAriel/debian-dev-setup/main/setup.sh)
```

> ⚠️ Siempre revisá el contenido de un script antes de ejecutarlo con `curl | bash`.

---

## Flags disponibles

| Flag        | Descripción                                                                            |
| ----------- | -------------------------------------------------------------------------------------- |
| `--dry-run` | Simula toda la instalación sin ejecutar ningún cambio real                             |
| `--minimal` | Instala solo herramientas base: Git, Python, NVM + Node. Omite VSCode, Brave y fuentes |
| `--help`    | Muestra la ayuda                                                                       |

```bash
# Ejemplos
./setup.sh --dry-run
./setup.sh --minimal
./setup.sh --minimal --dry-run
```

---

## Shells disponibles

Al ejecutar el script se te pregunta qué shell querés configurar:

### Bash (tuneado)

- Prompt personalizado con colores, info de git y venv activo
- Historial extendido, bash completion, globbing recursivo
- Sin dependencias externas

### Zsh + Oh My Zsh

- Todo lo de Bash, más:
- **zsh-autosuggestions** — sugiere comandos completos mientras escribís (basado en historial)
- **zsh-syntax-highlighting** — colorea el comando en tiempo real (verde = válido, rojo = no existe)
- Plugin **git** — aliases cortos: `gst`, `gco`, `glog`, etc.
- Plugin **z** — navegación de directorios por frecuencia de uso
- Autocompletado inteligente de argumentos, flags y ramas de git

> Podés cambiar de shell en cualquier momento volviendo a ejecutar `./setup.sh`.

---

## Temas de prompt

| Tema                 | Estilo                                                 |
| -------------------- | ------------------------------------------------------ |
| **Nord**             | Azules fríos del ártico, verdes apagados. El clásico   |
| **Dracula**          | Púrpuras profundos, rosas vibrantes, verdes eléctricos |
| **Gruvbox**          | Marrones cálidos, amarillos retro, naranjas terrosos   |
| **Catppuccin Mocha** | Pasteles suaves sobre fondo oscuro. Moderno y relajado |

El prompt resultante tiene este formato en ambos shells:

```
(🐍 mi-venv)  usuario  ~/proyectos/app   main ●
❯
```

- 🐍 Solo aparece si hay un virtualenv activo
- `●` verde → directorio git limpio
- `●` rojo → hay cambios sin commitear (working tree o staging)
- `❯` rojo → el último comando terminó con error
- `#` rojo → sesión de root

---

## Estructura del proyecto

```
debian-dev-setup/
├── setup.sh              # Orquestador: flags, preguntas, coordinación
├── lib/
│   └── utils.sh          # Helpers compartidos: logging, run(), confirm()
├── modules/
│   ├── base.sh           # apt, git, python, build-essential
│   ├── vscode.sh         # Visual Studio Code
│   ├── brave.sh          # Brave Browser
│   ├── node.sh           # NVM + selector interactivo de versión
│   ├── fonts.sh          # Cascadia Code con detección de updates
│   └── shell.sh          # Bash o Zsh+OMZ con tema aplicado
├── themes/
│   ├── nord.sh           # Paleta Nord
│   ├── dracula.sh        # Paleta Dracula
│   ├── gruvbox.sh        # Paleta Gruvbox
│   └── catppuccin.sh     # Paleta Catppuccin Mocha
├── README.md
├── CHANGELOG.md
└── .gitignore
```

---

## Comportamiento idempotente

El script puede ejecutarse múltiples veces sin romper nada:

| Situación                                 | Comportamiento                                                                    |
| ----------------------------------------- | --------------------------------------------------------------------------------- |
| Herramienta ya instalada                  | La omite y muestra la versión actual                                              |
| Node ya instalado                         | Muestra el menú igual — podés instalar versiones adicionales o cambiar el default |
| Cascadia Code al día                      | Lo omite                                                                          |
| Nueva versión de Cascadia Code disponible | Pregunta si querés actualizar                                                     |
| `~/.bashrc` o `~/.zshrc` existente        | Genera backup con timestamp antes de sobreescribir                                |
| Git ya configurado                        | Muestra los valores actuales y pregunta si querés cambiarlos                      |

---

## Primer push al repo

```bash
cd debian-dev-setup
git init
git add .
git commit -m "feat: initial release v1.0.0"
git branch -M main
git remote add origin https://github.com/RoAriel/debian-dev-setup.git
git push -u origin main
```

---

## Agregar un nuevo programa

Cada herramienta es un módulo independiente en `modules/`. Para agregar una nueva:

1. Crear `modules/mi-herramienta.sh` siguiendo el patrón de cualquier módulo existente
2. Agregar `source "$SETUP_DIR/modules/mi-herramienta.sh"` en `setup.sh`
3. Llamar `module_mi_herramienta` en la sección de ejecución de `setup.sh`
4. Si es una herramienta GUI, respetá el flag `$MINIMAL` para omitirla en modo servidor

---

## Roadmap

- [ ] Extensiones de VSCode configurables
- [ ] Selector de tema para el prompt con preview de colores
- [ ] Flag `--update` para actualizar todas las herramientas instaladas
- [ ] Soporte para Fedora / Arch (reemplazar módulo `base.sh`)
- [ ] Tests automatizados con Docker

---

## Licencia

MIT — hacé lo que quieras con esto.
