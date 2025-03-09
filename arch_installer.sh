#!/bin/bash

# arch_installer.sh - Functional Arch Linux Installer
# This script provides a complete Arch Linux installation system with support for
# different bootloaders (GRUB, systemd-boot, rEFInd), secure boot, and TPM 2.0 configuration.
# Now includes advanced disk management features integrated from disk-menu.sh.

# ASCII Art Logo
ASCII_LOGO='\n                 █████╗ ██████╗  ██████╗██╗  ██╗\n                ██╔══██╗██╔══██╗██╔════╝██║  ██║\n                ███████║██████╔╝██║     ███████║\n                ██╔══██║██╔══██╗██║     ██╔══██║\n                ██║  ██║██║  ██║╚██████╗██║  ██║\n                ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝\n           ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗\n           ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗\n           ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝\n           ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗\n           ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║\n           ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝'

# ASCII Art Logo for Beginners Mode
BEGINNER_LOGO='\n     ██████╗ ███████╗ ██████╗ ██╗███╗   ██╗███╗   ██╗███████╗██████╗\n     ██╔══██╗██╔════╝██╔════╝ ██║████╗  ██║████╗  ██║██╔════╝██╔══██╗\n     ██████╔╝█████╗  ██║  ███╗██║██╔██╗ ██║██╔██╗ ██║█████╗  ██████╔╝\n     ██╔══██╗██╔══╝  ██║   ██║██║██║╚██╗██║██║╚██╗██║██╔══╝  ██╔══██╗\n     ██████╔╝███████╗╚██████╔╝██║██║ ╚████║██║ ╚████║███████╗██║  ██║\n     ╚═════╝ ╚══════╝ ╚═════╝ ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝\n                       GUIDED INSTALLATION MODE'

# Global variables for configuration
BOOTLOADER=""
SECURE_BOOT=false
TPM_ENABLED=false
TPM_PIN_ENABLED=false
UKI_ENABLED=false
AUDIO_SYSTEM="none"
USER_PASSWORD=""
SUDO_ENABLED=true
HOSTNAME_PASSWORD=""
UEFI_MODE=false
USERNAME=""
HELP_TEXT_ENABLED=false
BEGINNER_MODE=false
# Package and environment configuration
DE_SELECTION=""
PACKAGE_PROFILE="standard"
NETWORK_MANAGER="NetworkManager"
DEV_TOOLS=()
VIRTUALIZATION=""

# Configuration status indicators
DISK_CONFIGURED=false
HOSTNAME_CONFIGURED=false
USERNAME_CONFIGURED=false
TIMEZONE_CONFIGURED=false
FILESYSTEM_CONFIGURED=false
BOOTLOADER_CONFIGURED=false
SECUREBOOT_CONFIGURED=false
TPM_CONFIGURED=false
ENCRYPTION_CONFIGURED=false
UKI_CONFIGURED=false
AUDIO_CONFIGURED=false
DE_CONFIGURED=false
PACKAGE_CONFIGURED=false
NETWORK_CONFIGURED=false
DEV_TOOLS_CONFIGURED=false
VIRTUALIZATION_CONFIGURED=false

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Language settings
CURRENT_LANG="en"

# Translation arrays for English
declare -A LANG_EN
LANG_EN[welcome]="Welcome to Arch Linux Installer!"
LANG_EN[welcome_text]="This installer will guide you through the process of installing Arch Linux on your system with the following features:

• Multiple bootloader options (GRUB, systemd-boot, rEFInd)
• Disk encryption with LUKS
• Secure Boot and TPM support
• Advanced disk management
• Unified Kernel Images
• Audio system configuration (PulseAudio, PipeWire, None)

To navigate through the installer:
- Use the arrow keys to move between options
- Press ENTER to select an option
- Press ESC to go back or cancel

TIP FOR BEGINNERS: Choose 'Beginner Mode' from the main menu for step-by-step guidance!

Let's get started!"
LANG_EN[beginner_mode]="Beginner Mode"
LANG_EN[beginner_mode_desc]="Step-by-step guided installation"
LANG_EN[beginner_intro]="Welcome to Beginner Mode! This guided process will walk you through installing Arch Linux step-by-step with helpful explanations at each stage."
LANG_EN[beginner_step]="Step %d of %d"
LANG_EN[help_available]="Help is available for this option. Press F1 or select 'Show Help' for more information."
LANG_EN[progress_indicator]="Installation Progress: %d%%"
LANG_EN[help_text_disk]="The installation disk is where Arch Linux will be installed.\n\nThis disk will be partitioned to include:\n- An EFI partition for booting\n- A swap partition for virtual memory\n- A root partition for the system\n\nWARNING: All data on the selected disk will be erased!"
LANG_EN[help_text_hostname]="The hostname is the name of your computer on a network.\n\nIt should be a single word using only letters, numbers, and hyphens.\nExample hostnames: arch-laptop, mycomputer, arch-desktop"
LANG_EN[help_text_username]="Create a user account for daily use.\n\nYou should create a regular user account instead of using the root account for everyday tasks.\n\nThe username should be lowercase and can contain letters, numbers, and some symbols."
LANG_EN[help_text_timezone]="Select your local timezone to ensure the system clock is correct.\n\nFormat: Region/City\nExamples: America/New_York, Europe/London, Asia/Tokyo"
LANG_EN[help_text_filesystem]="The root filesystem determines how files are stored on your disk.\n\nRecommended options:\n- ext4: Most widely used, stable and reliable\n- btrfs: Modern filesystem with snapshots and advanced features\n- xfs: Good for large files and databases"
LANG_EN[help_text_bootloader]="The bootloader is the program that starts your operating system.\n\nRecommended options:\n- GRUB: Most compatible and well-tested\n- systemd-boot: Faster and simpler (UEFI only)\n- rEFInd: User-friendly graphical boot manager (UEFI only)"
LANG_EN[help_text_encryption]="Disk encryption protects your data if your computer is lost or stolen.\n\nYou'll need to enter a password each time you boot your computer.\n\nLUKS2 is recommended for most users."
LANG_EN[help_text_audio]="The audio system allows your computer to play sound.\n\nRecommended options:\n- PipeWire: Modern audio system with better compatibility and features\n- PulseAudio: Traditional audio system\n- None: No audio system (for servers or minimal installations)"
LANG_EN[help_text_desktop]="A desktop environment provides a graphical interface for your system.\n\nOptions include:\n- GNOME: Modern, feature-rich desktop environment\n- KDE Plasma: Customizable and feature-rich desktop\n- XFCE: Lightweight and stable desktop environment\n- Tiling window managers (i3, Sway): Minimal and keyboard-focused\n\nSelect 'None' for a command-line only system."
LANG_EN[help_text_package]="Package profiles determine how many applications are installed initially.\n\nOptions:\n- Minimal: Only essential programs and utilities\n- Standard: Common applications for everyday use\n- Full: Comprehensive set of software for most use cases"
LANG_EN[help_text_network]="Network configuration determines how your system connects to networks.\n\nOptions:\n- NetworkManager: User-friendly network management (recommended for desktops)\n- systemd-networkd: Lightweight network configuration (good for servers)\n- iwd: Simple wireless daemon (minimal systems)\n\nNetworkManager is recommended for most users."
LANG_EN[help_text_devtools]="Development tools provide programming languages and utilities.\n\nYou can select multiple options including:\n- Programming languages (Python, Rust, etc.)\n- Version control (Git)\n- IDEs and text editors\n- Build tools and compilers"
LANG_EN[help_text_virtualization]="Virtualization allows you to run other operating systems as virtual machines.\n\nOptions:\n- KVM/QEMU: Native Linux virtualization with excellent performance\n- VirtualBox: Cross-platform virtualization with a user-friendly interface\n- Docker: Container platform for application isolation\n\nSelect 'None' if you don't need virtualization."
LANG_EN[welcome_screen]="Welcome to Arch Linux Installer"
LANG_EN[uefi_mode]="UEFI mode detected."
LANG_EN[bios_mode]="Legacy BIOS mode detected."
LANG_EN[internet_ok]="Internet connection detected."
LANG_EN[no_internet]="No internet connection detected. Please connect to the internet and try again."
LANG_EN[disk_title]="Disk Selection"
LANG_EN[disk_prompt]="Select the disk to install Arch Linux:\n(Use arrow keys to navigate, space to select)"
LANG_EN[disk_details]="Selected disk details:"
LANG_EN[disk_warning]="WARNING: All data on this disk will be erased."
LANG_EN[disk_confirm]="WARNING: All data on %s will be erased. Continue?"
LANG_EN[hostname_title]="Hostname"
LANG_EN[hostname_prompt]="Enter hostname for the new system:"
LANG_EN[hostname_protect]="Do you want to set a password to protect the hostname?"
LANG_EN[hostname_pw_title]="Hostname Protection"
LANG_EN[hostname_pw_prompt]="Enter hostname protection password:"
LANG_EN[hostname_pw_confirm]="Confirm hostname protection password:"
LANG_EN[hostname_pw_empty]="No password entered. Hostname protection will not be enabled."
LANG_EN[hostname_pw_mismatch]="Passwords do not match. Hostname protection will not be enabled."
LANG_EN[username_title]="User Account Setup"
LANG_EN[username_text]="You will now configure a new user account for your Arch Linux system.\n\nThis includes:\n- Username\n- Password\n- Administrator (sudo) privileges"
LANG_EN[username_prompt]="Enter username for the new user:\n\nThis will be your login name."
LANG_EN[username_confirm]="Username set to: %s"
LANG_EN[password_title]="User Account Setup: Password"
LANG_EN[password_text]="Now you will set a password for user '%s'.\n\nLeave empty to use the default password 'password'."
LANG_EN[password_prompt]="Enter password for user %s:"
LANG_EN[password_confirm_title]="User Account Setup: Confirm Password"
LANG_EN[password_confirm_prompt]="Confirm password for user %s:"
LANG_EN[password_mismatch]="Passwords do not match.\n\nWould you like to try again or use the default password?"
LANG_EN[password_retry]="Try entering password again?"
LANG_EN[password_empty]="No password entered. Using default password 'password'."
LANG_EN[password_default]="Using default password 'password' for user %s."
LANG_EN[password_success]="Password set successfully for user %s."
LANG_EN[sudo_title]="User Account Setup: Administrator Privileges"
LANG_EN[sudo_prompt]="Would you like to grant administrator (sudo) privileges to user %s?\n\nWith sudo privileges, this user can:\n- Install and remove software\n- Modify system settings\n- Perform administrative tasks\n\nWithout sudo privileges, the user will have limited access."
LANG_EN[sudo_granted]="Administrator privileges granted to user %s."
LANG_EN[sudo_denied]="User %s will have standard (non-administrator) privileges."
LANG_EN[user_summary]="User account configuration summary:\n\nUsername: %s\nPassword: %s\nAdministrator Privileges: %s"
LANG_EN[timezone_title]="Timezone"
LANG_EN[timezone_prompt]="Enter timezone (e.g., America/New_York):"
LANG_EN[filesystem_title]="Filesystem Selection"
LANG_EN[filesystem_prompt]="Choose a root filesystem:"
LANG_EN[bootloader_title]="Bootloader Selection"
LANG_EN[bootloader_uefi]="Firmware Type: UEFI detected\n\nThe following bootloaders are compatible with your system:"
LANG_EN[bootloader_bios]="Firmware Type: Legacy BIOS (MBR) detected\n\nOnly GRUB bootloader is compatible with your system."
LANG_EN[audio_title]="Audio System Selection"
LANG_EN[audio_text]="Select the audio system you want to install:\n\n• None - No audio system will be installed\n• PulseAudio - Traditional audio server with good compatibility\n• PipeWire - Modern audio/video server with PulseAudio compatibility\n\nPipeWire is recommended for new installations as it provides better \nperformance and compatibility with modern applications."
LANG_EN[audio_prompt]="Choose your audio system:"
LANG_EN[audio_none]="No audio system will be installed."
LANG_EN[audio_pulse]="PulseAudio will be installed."
LANG_EN[audio_pipewire]="PipeWire with PulseAudio compatibility will be installed."
LANG_EN[audio_selected]="Audio system selected: %s"
LANG_EN[lang_title]="Language Selection"
LANG_EN[lang_prompt]="Select installer language:"
LANG_EN[main_menu_title]="Arch Linux Installer"
LANG_EN[select_option]="Choose an option:"
LANG_EN[select_disk]="Select Installation Disk"
LANG_EN[set_hostname]="Set Hostname"
LANG_EN[set_username]="Set Username"
LANG_EN[set_timezone]="Set Timezone"
LANG_EN[select_fs]="Select Filesystem"
LANG_EN[select_bootloader]="Select Bootloader"
LANG_EN[config_secureboot]="Configure Secure Boot"
LANG_EN[config_tpm]="Configure TPM"
LANG_EN[config_encryption]="Configure Encryption"
LANG_EN[config_uki]="Configure Unified Kernel Images"
LANG_EN[select_audio]="Select Audio System"
LANG_EN[select_language]="Select Language"
LANG_EN[advanced_disk]="Advanced Disk Management"
LANG_EN[show_summary]="Show Summary"
LANG_EN[select_desktop]="Select Desktop Environment"
LANG_EN[select_package]="Select Package Profile"
LANG_EN[config_network]="Configure Network"
LANG_EN[select_devtools]="Select Development Tools"
LANG_EN[config_virtualization]="Configure Virtualization"
LANG_EN[install_summary]="The system will be installed with the following configuration:\n\n- Disk: %s\n- Root Filesystem: %s\n- Hostname: %s\n- Hostname Protection: %s\n- Username: %s\n- User Password: %s\n- Sudo Privileges: %s\n- Timezone: %s\n- Bootloader: %s\n- Secure Boot: %s\n- TPM 2.0: %s\n- Disk Encryption: %s\n- Unified Kernel Images: %s\n- Audio System: %s\n- Desktop Environment: %s\n- Package Profile: %s\n- Network Manager: %s\n- Development Tools: %s\n- Virtualization: %s\n- Language: %s\n\nPress OK to continue or cancel to abort."
LANG_EN[error]="Error"
LANG_EN[success]="Success"
LANG_EN[warning]="Warning"
LANG_EN[confirm]="Confirm"
LANG_EN[yes]="Yes"
LANG_EN[no]="No"
LANG_EN[enabled]="Enabled"
LANG_EN[disabled]="Disabled"
LANG_EN[custom_set]="Custom (set)"
LANG_EN[default_pw]="Default ('password')"
LANG_EN[language_changed]="Language changed to"

# Translation arrays for Spanish
declare -A LANG_ES
declare -A LANG_FR
declare -A LANG_DE
declare -A LANG_ZH
declare -A LANG_JA
declare -A LANG_KO
declare -A LANG_RU
declare -A LANG_AR
declare -A LANG_PT
declare -A LANG_IT
declare -A LANG_HI
declare -A LANG_BN
declare -A LANG_TR
declare -A LANG_NL
declare -A LANG_PL
declare -A LANG_UK
declare -A LANG_VI
declare -A LANG_EL
declare -A LANG_HE
declare -A LANG_TH
declare -A LANG_CS
declare -A LANG_SV
declare -A LANG_FI
declare -A LANG_NO
declare -A LANG_DA
declare -A LANG_HU
declare -A LANG_RO
declare -A LANG_CA
declare -A LANG_EU
declare -A LANG_CY
declare -A LANG_EO
LANG_ES[welcome]="¡Bienvenido al Instalador de Arch Linux!"
LANG_ES[welcome_text]="Este instalador le guiará a través del proceso de instalación de Arch Linux en su sistema con las siguientes características:

• Múltiples opciones de gestor de arranque (GRUB, systemd-boot, rEFInd)
• Cifrado de disco con LUKS
• Soporte para Secure Boot y TPM
• Gestión avanzada de discos
• Imágenes de Kernel Unificadas
• Configuración del sistema de audio (PulseAudio, PipeWire, Ninguno)

Para navegar por el instalador:
- Use las teclas de flecha para moverse entre opciones
- Presione ENTER para seleccionar una opción
- Presione ESC para volver o cancelar

¡Comencemos!"
LANG_ES[uefi_mode]="Modo UEFI detectado."
LANG_ES[bios_mode]="Modo BIOS Legacy detectado."
LANG_ES[internet_ok]="Conexión a Internet detectada."
LANG_ES[no_internet]="No se detectó conexión a Internet. Por favor, conéctese a Internet e inténtelo de nuevo."
LANG_ES[disk_title]="Selección de Disco"
LANG_ES[disk_prompt]="Seleccione el disco para instalar Arch Linux:\n(Use las teclas de flecha para navegar, espacio para seleccionar)"
LANG_ES[disk_details]="Detalles del disco seleccionado:"
LANG_ES[disk_warning]="ADVERTENCIA: Todos los datos en este disco serán borrados."
LANG_ES[disk_confirm]="ADVERTENCIA: Todos los datos en %s serán borrados. ¿Continuar?"
LANG_ES[hostname_title]="Nombre de Host"
LANG_ES[hostname_prompt]="Introduzca el nombre de host para el nuevo sistema:"
LANG_ES[hostname_protect]="¿Desea establecer una contraseña para proteger el nombre de host?"
LANG_ES[hostname_pw_title]="Protección del Nombre de Host"
LANG_ES[hostname_pw_prompt]="Introduzca la contraseña de protección del nombre de host:"
LANG_ES[hostname_pw_confirm]="Confirme la contraseña de protección del nombre de host:"
LANG_ES[hostname_pw_empty]="No se introdujo contraseña. La protección del nombre de host no se habilitará."
LANG_ES[hostname_pw_mismatch]="Las contraseñas no coinciden. La protección del nombre de host no se habilitará."
LANG_ES[username_title]="Configuración de Cuenta de Usuario"
LANG_ES[username_text]="Ahora configurará una nueva cuenta de usuario para su sistema Arch Linux.\n\nEsto incluye:\n- Nombre de usuario\n- Contraseña\n- Privilegios de administrador (sudo)"
LANG_ES[username_prompt]="Introduzca el nombre de usuario para el nuevo usuario:\n\nEste será su nombre de inicio de sesión."
LANG_ES[username_confirm]="Nombre de usuario establecido como: %s"
LANG_ES[password_title]="Configuración de Cuenta de Usuario: Contraseña"
LANG_ES[password_text]="Ahora establecerá una contraseña para el usuario '%s'.\n\nDéjela vacía para usar la contraseña predeterminada 'password'."
LANG_ES[password_prompt]="Introduzca la contraseña para el usuario %s:"
LANG_ES[password_confirm_title]="Configuración de Cuenta de Usuario: Confirmar Contraseña"
LANG_ES[password_confirm_prompt]="Confirme la contraseña para el usuario %s:"
LANG_ES[password_mismatch]="Las contraseñas no coinciden.\n\n¿Le gustaría intentarlo de nuevo o usar la contraseña predeterminada?"
LANG_ES[password_retry]="¿Intentar introducir la contraseña de nuevo?"
LANG_ES[password_empty]="No se introdujo contraseña. Usando la contraseña predeterminada 'password'."
LANG_ES[password_default]="Usando la contraseña predeterminada 'password' para el usuario %s."
LANG_ES[password_success]="Contraseña establecida correctamente para el usuario %s."
LANG_ES[sudo_prompt]="¿Desea otorgar privilegios de administrador (sudo) al usuario %s?\n\nCon privilegios sudo, este usuario puede:\n- Instalar y eliminar software\n- Modificar la configuración del sistema\n- Realizar tareas administrativas\n\nSin privilegios sudo, el usuario tendrá acceso limitado."
LANG_ES[sudo_prompt]="¿Desea otorgar privilegios de administrador (sudo) al usuario %s?\\n\\nCon privilegios sudo, este usuario puede:\\n- Instalar y eliminar software\\n- Modificar la configuración del sistema\\n- Realizar tareas administrativas\\n\\nSin privilegios sudo, el usuario tendrá acceso limitado."
LANG_ES[sudo_granted]="Privilegios de administrador otorgados al usuario %s."
LANG_ES[user_summary]="Resumen de configuración de la cuenta de usuario:\n\nNombre de usuario: %s\nContraseña: %s\nPrivilegios de administrador: %s"
LANG_ES[user_summary]="Resumen de configuración de la cuenta de usuario:\\n\\nNombre de usuario: %s\\nContraseña: %s\\nPrivilegios de administrador: %s"
LANG_ES[timezone_title]="Zona Horaria"
LANG_ES[timezone_prompt]="Introduzca la zona horaria (ej., America/Mexico_City):"
LANG_ES[filesystem_title]="Selección de Sistema de Archivos"
LANG_ES[filesystem_prompt]="Elija un sistema de archivos para la raíz:"
LANG_ES[bootloader_title]="Selección de Gestor de Arranque"
LANG_ES[bootloader_uefi]="Tipo de Firmware: UEFI detectado\n\nLos siguientes gestores de arranque son compatibles con su sistema:"
LANG_ES[bootloader_bios]="Tipo de Firmware: BIOS Legacy (MBR) detectado\n\nSolo el gestor de arranque GRUB es compatible con su sistema."
LANG_ES[audio_title]="Selección del Sistema de Audio"
LANG_ES[audio_text]="Seleccione el sistema de audio que desea instalar:\n\n• Ninguno - No se instalará ningún sistema de audio\n• PulseAudio - Servidor de audio tradicional con buena compatibilidad\n• PipeWire - Servidor de audio/video moderno con compatibilidad con PulseAudio\n\nSe recomienda PipeWire para nuevas instalaciones ya que proporciona mejor \nrendimiento y compatibilidad con aplicaciones modernas."
LANG_ES[audio_prompt]="Elija su sistema de audio:"
LANG_ES[audio_none]="No se instalará ningún sistema de audio."
LANG_ES[audio_pulse]="Se instalará PulseAudio."
LANG_ES[audio_pipewire]="Se instalará PipeWire con compatibilidad con PulseAudio."
LANG_ES[audio_selected]="Sistema de audio seleccionado: %s"
LANG_ES[lang_title]="Selección de Idioma"
LANG_ES[lang_prompt]="Seleccione el idioma del instalador:"
LANG_ES[main_menu_title]="Instalador de Arch Linux"
LANG_ES[select_option]="Elija una opción:"
LANG_ES[select_disk]="Seleccionar Disco de Instalación"
LANG_ES[set_hostname]="Establecer Nombre de Host"
LANG_ES[set_username]="Establecer Nombre de Usuario"
LANG_ES[set_timezone]="Establecer Zona Horaria"
LANG_ES[select_fs]="Seleccionar Sistema de Archivos"
LANG_ES[select_bootloader]="Seleccionar Gestor de Arranque"
LANG_ES[config_secureboot]="Configurar Arranque Seguro"
LANG_ES[config_tpm]="Configurar TPM"
LANG_ES[config_encryption]="Configurar Cifrado"
LANG_ES[config_uki]="Configurar Imágenes de Kernel Unificadas"
LANG_ES[select_audio]="Seleccionar Sistema de Audio"
LANG_ES[select_language]="Seleccionar Idioma"
LANG_ES[advanced_disk]="Gestión Avanzada de Discos"
LANG_ES[show_summary]="Mostrar Resumen"
LANG_ES[start_install]="Iniciar Instalación"
LANG_ES[exit]="Salir"

# Bold text
BOLD='\033[1m'
NOBOLD='\033[0m'
# Constants for advanced disk management
TEMP_DIR="/tmp/disk-menu"
BACKUP_DIR="/tmp/disk-backups"
# Default locale, will be updated when language is selected
LOCALE="en_US.UTF-8"
KEYBOARD="us"
ROOT_FILESYSTEM="ext4"
# Encryption settings
ENCRYPTION_ENABLED=false
ENCRYPTION_TYPE="luks2"
ENCRYPTION_PASSWORD=""
ENCRYPTION_KEYFILE_ENABLED=false
ENCRYPTION_KEYFILE_PATH="/crypto_keyfile.bin"
ENCRYPTION_CONFIGURED=false

# Define partition variables for LUKS
UNENCRYPTED_ROOT_PARTITION=""
LUKS_DEVICE_NAME="cryptroot"

# These color variables are already defined above
# Get status indicator for menu items
get_status_indicator() {
    local status=$1
    if [ "$status" = true ]; then
        echo "[+]"
    else
        echo "[ ]"
    fi
}
# Get text based on current language
get_text() {
    local key=$1
    if [ "$CURRENT_LANG" = "en" ]; then
        echo "${LANG_EN[$key]}"
    elif [ "$CURRENT_LANG" = "es" ]; then
        echo "${LANG_ES[$key]}"
    elif [ "$CURRENT_LANG" = "fr" ]; then
        echo "${LANG_FR[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "de" ]; then
        echo "${LANG_DE[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "zh" ]; then
        echo "${LANG_ZH[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ja" ]; then
        echo "${LANG_JA[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ko" ]; then
        echo "${LANG_KO[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ru" ]; then
        echo "${LANG_RU[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ar" ]; then
        echo "${LANG_AR[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "pt" ]; then
        echo "${LANG_PT[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "it" ]; then
        echo "${LANG_IT[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "hi" ]; then
        echo "${LANG_HI[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "bn" ]; then
        echo "${LANG_BN[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "tr" ]; then
        echo "${LANG_TR[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "nl" ]; then
        echo "${LANG_NL[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "pl" ]; then
        echo "${LANG_PL[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "uk" ]; then
        echo "${LANG_UK[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "vi" ]; then
        echo "${LANG_VI[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "el" ]; then
        echo "${LANG_EL[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "he" ]; then
        echo "${LANG_HE[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "th" ]; then
        echo "${LANG_TH[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "cs" ]; then
        echo "${LANG_CS[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "sv" ]; then
        echo "${LANG_SV[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "fi" ]; then
        echo "${LANG_FI[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "no" ]; then
        echo "${LANG_NO[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "da" ]; then
        echo "${LANG_DA[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "hu" ]; then
        echo "${LANG_HU[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ro" ]; then
        echo "${LANG_RO[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "ca" ]; then
        echo "${LANG_CA[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "eu" ]; then
        echo "${LANG_EU[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "cy" ]; then
        echo "${LANG_CY[$key]:-${LANG_EN[$key]}}"
    elif [ "$CURRENT_LANG" = "eo" ]; then
        echo "${LANG_EO[$key]:-${LANG_EN[$key]}}"
    else
        echo "${LANG_EN[$key]}" # Default to English if language not recognized
    fi
}

# Parse command line arguments
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --password)
                if [[ -n "$2" && "$2" != --* ]]; then
                    USER_PASSWORD="$2"
                    echo -e "${GREEN}Password set from command line${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Password is required${NC}"
                    exit 1
                fi
                ;;
            --hostname)
                if [[ -n "$2" && "$2" != --* ]]; then
                    HOSTNAME="$2"
                    HOSTNAME_CONFIGURED=true
                    echo -e "${GREEN}Hostname set to: $2${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Hostname is required${NC}"
                    exit 1
                fi
                ;;
            --bootloader)
                if [[ -n "$2" && "$2" != --* ]]; then
                    BOOTLOADER="$2"
                    BOOTLOADER_CONFIGURED=true
                    echo -e "${GREEN}Bootloader set to: $2${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Bootloader is required${NC}"
                    exit 1
                fi
                ;;
            --filesystem)
                if [[ -n "$2" && "$2" != --* ]]; then
                    ROOT_FILESYSTEM="$2"
                    FILESYSTEM_CONFIGURED=true
                    echo -e "${GREEN}Root filesystem set to: $2${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Filesystem is required${NC}"
                    exit 1
                fi
                ;;
            --audio)
                if [[ -n "$2" && "$2" != --* ]]; then
                    AUDIO_SYSTEM="$2"
                    AUDIO_CONFIGURED=true
                    echo -e "${GREEN}Audio system set to: $2${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Audio system is required${NC}"
                    exit 1
                fi
                ;;
            --disk)
                if [[ -n "$2" && "$2" != --* ]]; then
                    DISK_DEVICE="$2"
                    DISK_CONFIGURED=true
                    echo -e "${GREEN}Disk set to: $2${NC}"
                    shift 2
                else
                    echo -e "${RED}$(get_text "error"): Disk is required${NC}"
                    exit 1
                fi
                ;;
            *)
                echo -e "${YELLOW}Warning: Unknown parameter '$1'${NC}"
                shift
                ;;
        esac
    done
}

# Function to get language status indicator
get_lang_status() {
    local lang_code=$1
    local current_lang=$2
    if [ "$current_lang" = "$lang_code" ]; then
        echo "[*]"
    else
        echo "[ ]"
    fi
}

# Function to get locale from language code
get_locale_from_lang() {
    local lang_code=$1
    
    case "$lang_code" in
        "en") echo "en_US.UTF-8" ;;
        "es") echo "es_ES.UTF-8" ;;
        "fr") echo "fr_FR.UTF-8" ;;
        "de") echo "de_DE.UTF-8" ;;
        "ru") echo "ru_RU.UTF-8" ;;
        "zh") echo "zh_CN.UTF-8" ;;
        "ja") echo "ja_JP.UTF-8" ;;
        "ko") echo "ko_KR.UTF-8" ;;
        "ar") echo "ar_SA.UTF-8" ;;
        "pt") echo "pt_BR.UTF-8" ;;
        "it") echo "it_IT.UTF-8" ;;
        "hi") echo "hi_IN.UTF-8" ;;
        "bn") echo "bn_BD.UTF-8" ;;
        "tr") echo "tr_TR.UTF-8" ;;
        "nl") echo "nl_NL.UTF-8" ;;
        "pl") echo "pl_PL.UTF-8" ;;
        "uk") echo "uk_UA.UTF-8" ;;
        "vi") echo "vi_VN.UTF-8" ;;
        "el") echo "el_GR.UTF-8" ;;
        "he") echo "he_IL.UTF-8" ;;
        "th") echo "th_TH.UTF-8" ;;
        "cs") echo "cs_CZ.UTF-8" ;;
        "sv") echo "sv_SE.UTF-8" ;;
        "fi") echo "fi_FI.UTF-8" ;;
        "no") echo "nb_NO.UTF-8" ;;
        "da") echo "da_DK.UTF-8" ;;
        "hu") echo "hu_HU.UTF-8" ;;
        "ro") echo "ro_RO.UTF-8" ;;
        "ca") echo "ca_ES.UTF-8" ;;
        "eu") echo "eu_ES.UTF-8" ;;
        "cy") echo "cy_GB.UTF-8" ;;
        "eo") echo "eo.UTF-8" ;;
        *) echo "en_US.UTF-8" ;; # Default to English locale if no match
    esac
}

# Function to select language
select_language() {
    
    # Define all languages organized by region
    local MENU_ITEMS=(
        "h1" "[ EUROPEAN LANGUAGES ]"
        "en" "$(get_lang_status "en" "$CURRENT_LANG") English"
        "es" "$(get_lang_status "es" "$CURRENT_LANG") Español (Spanish)"
        "fr" "$(get_lang_status "fr" "$CURRENT_LANG") Français (French)"
        "de" "$(get_lang_status "de" "$CURRENT_LANG") Deutsch (German)"
        "ru" "$(get_lang_status "ru" "$CURRENT_LANG") Русский (Russian)"
        
        "h2" "[ ASIAN LANGUAGES ]"
        "zh" "$(get_lang_status "zh" "$CURRENT_LANG") 中文 (Chinese)"
        "ja" "$(get_lang_status "ja" "$CURRENT_LANG") 日本語 (Japanese)"
        "ko" "$(get_lang_status "ko" "$CURRENT_LANG") 한국어 (Korean)"
        
        "h3" "[ MIDDLE EASTERN LANGUAGES ]"
        "ar" "$(get_lang_status "ar" "$CURRENT_LANG") العربية (Arabic)"
    )
    
    local SELECTED_LANG=$(whiptail --title "$(get_text lang_title)" --notags --menu "$(get_text lang_prompt)" 25 78 15 \
        "${MENU_ITEMS[@]}" 3>&1 1>&2 2>&3)
    
    # Skip section headers if selected
    if [[ "$SELECTED_LANG" == h* ]]; then
        return 0
    fi
    
    if [ $? -eq 0 ] && [ -n "$SELECTED_LANG" ]; then
        # Only update if a valid language is selected (not a header)
        if [[ "$SELECTED_LANG" != h* ]]; then
            declare -g CURRENT_LANG="$SELECTED_LANG"
            
            # Update the LOCALE based on the selected language
            declare -g LOCALE=$(get_locale_from_lang "$SELECTED_LANG")
            
            # Find the language name for the confirmation message
            local lang_name=""
            for ((i=0; i<${#MENU_ITEMS[@]}; i+=2)); do
                if [[ "${MENU_ITEMS[i]}" == "$SELECTED_LANG" ]]; then
                    # Remove the status indicator from the display name
                    lang_name="${MENU_ITEMS[i+1]}"
                    lang_name="${lang_name:4}" # Remove the "[*] " or "[ ] " prefix
                    break
                fi
            done
            
            whiptail --title "$(get_text "success")" --msgbox "$(get_text "language_changed"): $lang_name\nSystem locale set to: $LOCALE" 10 78
        fi
        
        return 0
    fi
    
    return 1
}

# Show welcome screen
show_welcome_screen() {
    whiptail --title "$(get_text welcome)" --msgbox "\
$ASCII_LOGO

$(get_text welcome_text)
" 30 78
}

# Ensure script is run as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}$(get_text "error"): This script must be run as root${NC}"
        exit 1
    fi
}
# System preparation functions
check_uefi() {
    echo "Checking for UEFI mode..."
    if [ -d "/sys/firmware/efi/efivars" ]; then
        echo -e "${GREEN}$(get_text uefi_mode)${NC}"
        UEFI_MODE=true
        logger -t arch_installer "UEFI mode detected"
        return 0
    else
        echo -e "${YELLOW}$(get_text bios_mode)${NC}"
        logger -t arch_installer "Legacy BIOS mode detected"
        logger -t arch_installer "$(get_text "logger_bios")"
        return 1
    fi
}
check_internet() {
    echo "Checking internet connection..."
    if ping -c 1 archlinux.org &> /dev/null; then
        echo -e "${GREEN}$(get_text internet_ok)${NC}"
        return 0
    else
        echo -e "${RED}$(get_text no_internet)${NC}"
        exit 1
    fi
}

# Disk functions
list_disks() {
    echo "Available disks:"
    lsblk -d -p -n -l -o NAME,SIZE,MODEL | grep -E "^/dev/(sd|nvme|vd)"
}

select_disk() {
    # Create a log file to store debug information
    local LOG_FILE="/tmp/arch_installer_debug.log"
    
    # Log function to write to both stdout and log file
    log_debug() {
        echo "[DEBUG] [$(date "+%Y-%m-%d %H:%M:%S")] $1" | tee -a "$LOG_FILE"
    }
    
    log_debug "===== Starting select_disk() function ====="
    log_debug "Enabling bash debugging mode (set -x)"
    
    # Enable debugging mode
    set -x
    
    # Create a disk selection menu using whiptail
    log_debug "Getting list of available disk devices"
    local disk_devices=$(lsblk -d -p -n -l -o NAME,SIZE,MODEL | grep -E "^/dev/(sd|nvme|vd)")
    log_debug "Available disk devices found: \n$disk_devices"
    
    # Check if we found any disks
    if [ -z "$disk_devices" ]; then
        log_debug "No disk devices found!"
        set +x
        whiptail --title "Error" --msgbox "No disk devices were found. Please check your hardware and try again." 10 70
        log_debug "===== Exiting select_disk() function with error ====="
        return 1
    fi
    
    local menu_items=()
    local counter=1
    
    # Format the disk list for whiptail
    log_debug "Formatting disk list for whiptail menu"
    while IFS= read -r line; do
        local name=$(echo "$line" | awk '{print $1}')
        local size=$(echo "$line" | awk '{print $2}')
        local model=$(echo "$line" | cut -d' ' -f3-)
        log_debug "Adding disk to menu: $name ($size - $model)"
        # Set the first disk as ON by default, others as OFF
        if [ $counter -eq 1 ]; then
            menu_items+=("$name" "$size - $model" "ON")
        else
            menu_items+=("$name" "$size - $model" "OFF")
        fi
        ((counter++))
    done <<< "$disk_devices"
    
    log_debug "Total disk count: $counter"
    log_debug "Preparing to display whiptail disk selection menu"
    
    # Create a temporary file to store whiptail output
    local temp_file=$(mktemp)
    log_debug "Created temporary file for whiptail output: $temp_file"
    
    log_debug "Calling whiptail to display disk selection menu"
    log_debug "Menu items prepared: ${menu_items[*]}"
    log_debug "Total disk count for menu: $(( counter - 1 ))"
    
    
    # Execute whiptail and direct output to the temporary file
    # Use stdout (1>) instead of stderr (2>) to capture whiptail's output
    whiptail --title "$(get_text disk_title)" --notags --radiolist \
    "$(get_text disk_prompt)" 20 78 $(( counter - 1 )) \
    "${menu_items[@]}" 3>&1 1>"$temp_file" 2>&3
    
    local whiptail_status=$?
    log_debug "Whiptail command returned with status: $whiptail_status"
    
    # Read the selected disk from the temporary file
    if [ $whiptail_status -eq 0 ]; then
        DISK_DEVICE=$(cat "$temp_file")
        log_debug "Read selection from temporary file: '${DISK_DEVICE:-none}'"
        
        # Trim any whitespace that might be present in the captured output
        DISK_DEVICE=$(echo "$DISK_DEVICE" | xargs)
        log_debug "Disk device after trimming: '${DISK_DEVICE:-none}'"
    else
        DISK_DEVICE=""
        log_debug "Whiptail exited with non-zero status, setting DISK_DEVICE to empty string"
    fi
    
    # Clean up the temporary file
    rm -f "$temp_file"
    log_debug "Removed temporary file: $temp_file"
    
    if [ $whiptail_status -ne 0 ] || [ -z "$DISK_DEVICE" ]; then
        log_debug "Disk selection canceled or no disk selected, returning error"
        set +x
        log_debug "Disabling bash debugging mode (set +x)"
        log_debug "===== Exiting select_disk() function with error ====="
        return 1
    fi
    
    # Show disk details
    log_debug "Getting detailed information for selected disk: $DISK_DEVICE"
    local disk_details=$(lsblk -p -o NAME,SIZE,TYPE,MOUNTPOINT "$DISK_DEVICE")
    log_debug "Disk details: \n$disk_details"
    
    log_debug "Displaying disk details in whiptail dialog"
    whiptail --title "$(get_text disk_title)" --msgbox "$(get_text disk_details)\n\n$disk_details\n\n$(get_text disk_warning)" 16 70
    
    # Confirm disk selection
    log_debug "Asking for confirmation to use disk: $DISK_DEVICE"
    whiptail --title "$(get_text confirm)" --yesno "$(printf "$(get_text disk_confirm)" "$DISK_DEVICE")" 8 70
    local confirm_status=$?
    
    log_debug "Confirmation dialog returned status: $confirm_status"
    if [ $confirm_status -ne 0 ]; then
        log_debug "User declined to use disk, returning error"
        set +x
        log_debug "Disabling bash debugging mode (set +x)"
        log_debug "===== Exiting select_disk() function with error ====="
        return 1
    fi
    
    log_debug "Disk selection confirmed, setting DISK_CONFIGURED=true"
    DISK_CONFIGURED=true
    
    # Disable debugging mode
    set +x
    log_debug "Disabling bash debugging mode (set +x)"
    log_debug "===== Exiting select_disk() function successfully ====="
    return 0
}
# Function to display progress during disk operations
disk_operation_progress() {
    echo -e "${BLUE}$1${NC}"
    # If a percentage is provided, update the progress gauge
    if [ -n "$2" ]; then
        echo $2
    fi
}

partition_disk() {
    echo "Partitioning disk: $DISK_DEVICE"
    
    # Create progress dialog for partitioning
    {
        disk_operation_progress "$(get_text "wiping_disk_signatures")" 10
        # Wipe existing signatures
        wipefs -a $DISK_DEVICE
        
        disk_operation_progress "$(get_text "creating_partition_table")" 20
        # Create GPT partition table
        parted -s $DISK_DEVICE mklabel gpt
        
        disk_operation_progress "$(get_text "creating_efi_partition")" 30
        # Create boot partition (550MB)
        parted -s $DISK_DEVICE mkpart "EFI system partition" fat32 1MiB 551MiB
        parted -s $DISK_DEVICE set 1 esp on
        sleep 1
        
        disk_operation_progress "$(get_text "calculating_swap_size")" 40
        # Create swap partition (size based on available RAM)
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local swap_size=$((mem_total / 1000)) # Convert KB to MB
        
        # If less than 8GB RAM, make swap equal to RAM size, otherwise 8GB
        if [ $swap_size -gt 8000 ]; then
            swap_size=8000
        fi
        
        disk_operation_progress "$(get_text "creating_swap_partition" "${swap_size}")" 50
        parted -s $DISK_DEVICE mkpart "swap" linux-swap 551MiB "$((551 + $swap_size))MiB"
        sleep 1
        
        disk_operation_progress "$(get_text "creating_root_partition")" 60
        # Create root partition (remainder of disk)
        parted -s $DISK_DEVICE mkpart "root" $ROOT_FILESYSTEM "$((551 + $swap_size))MiB" 100%
        
        disk_operation_progress "$(get_text "waiting_for_partition_detection")" 70
        # Wait for partition detection
        sleep 2
        
        disk_operation_progress "$(get_text "setting_up_partition_variables")" 80
        # Set variables for partitions
        if [[ $DISK_DEVICE == *"nvme"* ]]; then
            # NVMe drives use 'p' prefix for partitions
            EFI_PARTITION="${DISK_DEVICE}p1"
            SWAP_PARTITION="${DISK_DEVICE}p2"
            ROOT_PARTITION="${DISK_DEVICE}p3"
        else
            # SATA/IDE drives use numeric suffixes
            EFI_PARTITION="${DISK_DEVICE}1"
            SWAP_PARTITION="${DISK_DEVICE}2"
            ROOT_PARTITION="${DISK_DEVICE}3"
        fi
        disk_operation_progress "$(get_text "finalizing_partitioning")" 90
        # If encryption is enabled, create a separate /boot
        
        echo -e "${GREEN}Partitioning completed successfully.${NC}"
    } | whiptail --gauge "Partitioning disk..." 10 70 0
    
    return 0
}

get_encryption_password() {
    echo "Setting up encryption password..."
    
    # Get password through whiptail
    ENCRYPTION_PASSWORD=$(whiptail --passwordbox "Enter encryption password:" 8 60 --title "Disk Encryption" 3>&1 1>&2 2>&3)
    
    if [ -z "$ENCRYPTION_PASSWORD" ]; then
        whiptail --title "Error" --msgbox "No password entered. Encryption cannot continue without a password." 8 60
        return 1
    fi
    
    # Confirm password
    PASSWORD_CONFIRM=$(whiptail --passwordbox "Confirm encryption password:" 8 60 --title "Disk Encryption" 3>&1 1>&2 2>&3)
    
    if [ "$ENCRYPTION_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
        whiptail --title "Error" --msgbox "Passwords do not match. Please try again." 8 60
        get_encryption_password
    fi
    
    return 0
}

setup_encryption() {
    echo "Setting up LUKS encryption..."
    
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        # Install required packages for encryption
        pacman -S --needed --noconfirm cryptsetup
        
        # Get password for LUKS encryption if not already set
        if [ -z "$ENCRYPTION_PASSWORD" ]; then
            get_encryption_password
        fi
        
        echo -e "${BLUE}Creating encrypted LUKS container...${NC}"
        # Format with LUKS1 or LUKS2 depending on user selection
        if [ "$ENCRYPTION_TYPE" = "luks1" ]; then
            echo -e "$ENCRYPTION_PASSWORD" | cryptsetup luksFormat --type luks1 --cipher aes-xts-plain64 --key-size 256 --hash sha256 $UNENCRYPTED_ROOT_PARTITION -
        else
            echo -e "$ENCRYPTION_PASSWORD" | cryptsetup luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 256 --hash sha256 $UNENCRYPTED_ROOT_PARTITION -
        fi
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to format LUKS container.${NC}"
            exit 1
        fi
        
        echo -e "${BLUE}Opening LUKS container...${NC}"
        echo -e "$ENCRYPTION_PASSWORD" | cryptsetup open $UNENCRYPTED_ROOT_PARTITION $LUKS_DEVICE_NAME -
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error: Failed to open LUKS container.${NC}"
            exit 1
        fi
        
        # Create encryption keyfile if enabled
        if [ "$ENCRYPTION_KEYFILE_ENABLED" = true ]; then
            echo -e "${BLUE}Creating encryption keyfile...${NC}"
            mkdir -p /tmp/keyfile
            dd bs=512 count=4 if=/dev/urandom of=/tmp/keyfile/keyfile.bin
            chmod 600 /tmp/keyfile/keyfile.bin
            
            echo -e "${BLUE}Adding keyfile to LUKS...${NC}"
            echo -e "$ENCRYPTION_PASSWORD" | cryptsetup luksAddKey $UNENCRYPTED_ROOT_PARTITION /tmp/keyfile/keyfile.bin -
        fi
        
        echo -e "${GREEN}LUKS encryption set up successfully.${NC}"
    fi
    
    return 0
}

format_partitions() {
    echo "Formatting partitions..."
    
    # Format EFI System Partition as FAT32
    echo -e "${BLUE}Formatting EFI partition...${NC}"
    mkfs.fat -F32 $EFI_PARTITION
    
    # Format swap partition
    echo -e "${BLUE}Formatting swap partition...${NC}"
    mkswap $SWAP_PARTITION
    swapon $SWAP_PARTITION
    
    # Format root partition
    echo -e "${BLUE}Formatting root partition...${NC}"
    
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        if [ "$ENCRYPTION_CONFIGURED" != true ]; then
            # Setup encryption for the root partition
            setup_encryption
            ENCRYPTION_CONFIGURED=true
        fi
        
        # Format the encrypted device
        if [ "$ROOT_FILESYSTEM" = "ext4" ]; then
            mkfs.ext4 $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "btrfs" ]; then
            mkfs.btrfs $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "xfs" ]; then
            mkfs.xfs $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "f2fs" ]; then
            mkfs.f2fs $ROOT_PARTITION
        fi
    else
        # Format unencrypted partition
        if [ "$ROOT_FILESYSTEM" = "ext4" ]; then
            mkfs.ext4 $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "btrfs" ]; then
            mkfs.btrfs $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "xfs" ]; then
            mkfs.xfs $ROOT_PARTITION
        elif [ "$ROOT_FILESYSTEM" = "f2fs" ]; then
            mkfs.f2fs $ROOT_PARTITION
        fi
    fi
    
    echo -e "${GREEN}Partitions formatted successfully.${NC}"
    return 0
}

mount_partitions() {
    echo "Mounting partitions..."
    
    # Mount root partition to /mnt
    echo -e "${BLUE}Mounting root partition to /mnt...${NC}"
    mount $ROOT_PARTITION /mnt
    
    # Create boot/EFI directory
    echo -e "${BLUE}Creating and mounting EFI partition...${NC}"
    mkdir -p /mnt/boot/efi
    mount $EFI_PARTITION /mnt/boot/efi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Partitions mounted successfully.${NC}"
        return 0
    else
        echo -e "${RED}Error mounting partitions.${NC}"
        return 1
    fi
}

# Installation functions
install_base_system() {
    echo "Installing base Arch Linux system..."
    
    # Install essential packages
    echo -e "${BLUE}Running pacstrap to install base packages...${NC}"
    pacstrap /mnt base base-devel linux linux-firmware
    
    # Install packages based on selected package profile
    echo -e "${BLUE}Installing packages based on selected profile: $PACKAGE_PROFILE...${NC}"
    
    # Minimal packages always installed (networking, text editor, etc.)
    arch-chroot /mnt pacman -S --noconfirm networkmanager sudo nano vim dhcpcd
    
    # Install additional packages based on profile
    if [ "$PACKAGE_PROFILE" = "standard" ] || [ "$PACKAGE_PROFILE" = "full" ]; then
        echo -e "${BLUE}Installing standard packages...${NC}"
        arch-chroot /mnt pacman -S --noconfirm wget curl zip unzip git htop man-db man-pages
    fi
    
    if [ "$PACKAGE_PROFILE" = "full" ]; then
        echo -e "${BLUE}Installing full profile additional packages...${NC}"
        arch-chroot /mnt pacman -S --noconfirm gcc make cmake gdb valgrind rsync
    fi
    
    # Install desktop environment if selected
    if [ "$DE_CONFIGURED" = true ] && [ "$DE_SELECTION" != "none" ]; then
        echo -e "${BLUE}Installing desktop environment: $DE_SELECTION...${NC}"
        case "$DE_SELECTION" in
            "gnome")
                arch-chroot /mnt pacman -S --noconfirm gnome gnome-terminal gdm
                arch-chroot /mnt systemctl enable gdm.service
                ;;
            "kde")
                arch-chroot /mnt pacman -S --noconfirm plasma plasma-wayland-session kde-applications sddm
                arch-chroot /mnt systemctl enable sddm.service
                ;;
            "xfce")
                arch-chroot /mnt pacman -S --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter
                arch-chroot /mnt systemctl enable lightdm.service
                ;;
            "mate")
                arch-chroot /mnt pacman -S --noconfirm mate mate-extra lightdm lightdm-gtk-greeter
                arch-chroot /mnt systemctl enable lightdm.service
                ;;
            "cinnamon")
                arch-chroot /mnt pacman -S --noconfirm cinnamon lightdm lightdm-gtk-greeter
                arch-chroot /mnt systemctl enable lightdm.service
                ;;
            "lxde")
                arch-chroot /mnt pacman -S --noconfirm lxde lxdm
                arch-chroot /mnt systemctl enable lxdm.service
                ;;
            "lxqt")
                arch-chroot /mnt pacman -S --noconfirm lxqt sddm
                arch-chroot /mnt systemctl enable sddm.service
                ;;
            "i3")
                arch-chroot /mnt pacman -S --noconfirm i3 i3status i3lock dmenu xorg lightdm lightdm-gtk-greeter
                arch-chroot /mnt systemctl enable lightdm.service
                ;;
            "sway")
                arch-chroot /mnt pacman -S --noconfirm sway swaylock swayidle foot bemenu-wayland
                ;;
            "awesome")
                arch-chroot /mnt pacman -S --noconfirm awesome xorg lightdm lightdm-gtk-greeter
                arch-chroot /mnt systemctl enable lightdm.service
                ;;
            "dwm")
                arch-chroot /mnt pacman -S --noconfirm libx11 libxft libxinerama xorg-server xorg-xinit make gcc
                # DWM needs to be compiled from source
                arch-chroot /mnt bash -c "cd /tmp && git clone https://git.suckless.org/dwm && cd dwm && make clean install"
                ;;
        esac
        
        # Install X.Org if not using Wayland-based DE
        if [ "$DE_SELECTION" != "sway" ]; then
            echo -e "${BLUE}Installing X.Org display server...${NC}"
            arch-chroot /mnt pacman -S --noconfirm xorg xorg-xinit xorg-server
        fi
    fi
    
    # Install network management packages
    if [ "$NETWORK_CONFIGURED" = true ]; then
        echo -e "${BLUE}Installing network management: $NETWORK_MANAGER...${NC}"
        case "$NETWORK_MANAGER" in
            "NetworkManager")
                arch-chroot /mnt pacman -S --noconfirm networkmanager network-manager-applet
                arch-chroot /mnt systemctl enable NetworkManager.service
                ;;
            "systemd-networkd")
                # systemd-networkd comes with base install
                arch-chroot /mnt systemctl enable systemd-networkd.service
                arch-chroot /mnt systemctl enable systemd-resolved.service
                ;;
            "iwd")
                arch-chroot /mnt pacman -S --noconfirm iwd
                arch-chroot /mnt systemctl enable iwd.service
                ;;
            "netctl")
                arch-chroot /mnt pacman -S --noconfirm netctl dialog wpa_supplicant
                ;;
        esac
    else
        # Default to NetworkManager if nothing selected
        echo -e "${BLUE}Installing default network manager (NetworkManager)...${NC}"
        arch-chroot /mnt pacman -S --noconfirm networkmanager network-manager-applet
        arch-chroot /mnt systemctl enable NetworkManager.service
    fi
    
    # Install development tools
    if [ "$DEV_TOOLS_CONFIGURED" = true ] && [ ${#DEV_TOOLS[@]} -gt 0 ]; then
        echo -e "${BLUE}Installing selected development tools...${NC}"
        for tool in ${DEV_TOOLS[@]}; do
            case "$tool" in
                "base-devel")
                    # Already installed by default
                    ;;
                "git")
                    arch-chroot /mnt pacman -S --noconfirm git
                    ;;
                "python")
                    arch-chroot /mnt pacman -S --noconfirm python python-pip python-setuptools
                    ;;
                "nodejs")
                    arch-chroot /mnt pacman -S --noconfirm nodejs npm
                    ;;
                "rust")
                    arch-chroot /mnt pacman -S --noconfirm rust rust-analyzer cargo
                    ;;
                "go")
                    arch-chroot /mnt pacman -S --noconfirm go
                    ;;
                "java")
                    arch-chroot /mnt pacman -S --noconfirm jdk-openjdk openjdk-doc
                    ;;
                "php")
                    arch-chroot /mnt pacman -S --noconfirm php php-fpm
                    ;;
                "ruby")
                    arch-chroot /mnt pacman -S --noconfirm ruby
                    ;;
                "vscode")
                    arch-chroot /mnt pacman -S --noconfirm code
                    ;;
                "vim")
                    arch-chroot /mnt pacman -S --noconfirm vim
                    ;;
                "docker")
                    arch-chroot /mnt pacman -S --noconfirm docker
                    arch-chroot /mnt systemctl enable docker.service
                    ;;
                "databases")
                    arch-chroot /mnt pacman -S --noconfirm mariadb postgresql sqlite
                    ;;
            esac
        done
    fi
    
    # Install virtualization tools
    if [ "$VIRTUALIZATION_CONFIGURED" = true ] && [ "$VIRTUALIZATION" != "none" ]; then
        echo -e "${BLUE}Installing virtualization support: $VIRTUALIZATION...${NC}"
        case "$VIRTUALIZATION" in
            "kvm")
                arch-chroot /mnt pacman -S --noconfirm qemu libvirt virt-manager ebtables dnsmasq bridge-utils
                arch-chroot /mnt systemctl enable libvirtd.service
                # Add current user to libvirt group
                if [ -n "$USERNAME" ]; then
                    arch-chroot /mnt usermod -aG libvirt "$USERNAME"
                fi
                ;;
            "virtualbox")
                arch-chroot /mnt pacman -S --noconfirm virtualbox virtualbox-host-dkms
                # Add current user to vboxusers group
                if [ -n "$USERNAME" ]; then
                    arch-chroot /mnt usermod -aG vboxusers "$USERNAME"
                fi
                ;;
            "docker")
                arch-chroot /mnt pacman -S --noconfirm docker docker-compose
                arch-chroot /mnt systemctl enable docker.service
                # Add current user to docker group
                if [ -n "$USERNAME" ]; then
                    arch-chroot /mnt usermod -aG docker "$USERNAME"
                fi
                ;;
            "lxc")
                arch-chroot /mnt pacman -S --noconfirm lxc lxcfs
                arch-chroot /mnt systemctl enable lxc.service
                ;;
        esac
    fi
    
    # Install audio system
    if [ "$AUDIO_CONFIGURED" = true ]; then
        echo -e "${BLUE}Installing audio system: $AUDIO_SYSTEM...${NC}"
        case "$AUDIO_SYSTEM" in
            "pulseaudio")
                arch-chroot /mnt pacman -S --noconfirm pulseaudio pulseaudio-alsa alsa-utils pavucontrol
                ;;
            "pipewire")
                arch-chroot /mnt pacman -S --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber alsa-utils pavucontrol
                ;;
            "none")
                echo -e "${YELLOW}No audio system selected${NC}"
                ;;
        esac
    fi
    
    # Generate fstab
    echo -e "${BLUE}Generating fstab...${NC}"
    genfstab -U /mnt >> /mnt/etc/fstab
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Base system installed successfully.${NC}"
        return 0
    else
        echo -e "${RED}Error installing base system.${NC}"
        return 1
    fi
}

configure_system() {
    echo "Configuring system settings..."
    
    # Set hostname
    echo -e "${BLUE}Setting hostname to $HOSTNAME...${NC}"
    echo "$HOSTNAME" > /mnt/etc/hostname
    
    # Configure hosts file
    # Configure hosts file
    cat > /mnt/etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    $HOSTNAME
EOF
    # Only set up hostname protection if a password was created
    if [ -n "$HOSTNAME_PASSWORD" ]; then
        echo -e "${BLUE}Setting up hostname protection...${NC}"
        # Install required packages for hostname protection
        arch-chroot /mnt pacman -S --noconfirm systemd-container
        
        # Create a script to handle hostname protection
        cat > /mnt/etc/systemd/system/hostname-protection.service <<EOF
[Unit]
Description=Hostname Protection Service
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/bash /usr/local/bin/protect-hostname.sh
Restart=on-failure
User=root
PrivateDevices=true
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

        # Create the protection script with improved security
        cat > /mnt/usr/local/bin/protect-hostname.sh <<EOF
#!/bin/bash
# This script monitors and protects the system hostname

# Set strict permissions on this script
chmod 700 "\$0"

# Function to securely verify and restore hostname
verify_hostname() {
    # Read hostname from a secure location
    current_hostname=\$(cat /etc/hostname 2>/dev/null)
    
    # Sanitize input to prevent any command injection
    current_hostname=\$(echo "\$current_hostname" | tr -cd '[:alnum:].-')
    
    if [ "\$current_hostname" != "$HOSTNAME" ]; then
        # Use temp file and atomic move to prevent race conditions
        echo "$HOSTNAME" > /etc/hostname.tmp
        chown root:root /etc/hostname.tmp
        chmod 644 /etc/hostname.tmp
        mv -f /etc/hostname.tmp /etc/hostname
        
        # Use full path to hostnamectl for security
        /usr/bin/hostnamectl set-hostname "$HOSTNAME"
        /usr/bin/logger -p auth.warn "Attempt to change hostname detected and reverted"
        
        # Verify hostname was correctly set
        verify_hostname=\$(cat /etc/hostname 2>/dev/null)
        if [ "\$verify_hostname" != "$HOSTNAME" ]; then
            /usr/bin/logger -p auth.crit "Failed to secure hostname"
            # Notify administrators about the security issue
            echo "CRITICAL: Hostname protection failed!" | /usr/bin/mail -s "Hostname Protection Failure" root
        fi
    fi
}

# Main monitoring loop
while true; do
    verify_hostname
    sleep 60
done
EOF
        
        # Make the script executable
        chmod 700 /mnt/usr/local/bin/protect-hostname.sh
        chown root:root /mnt/usr/local/bin/protect-hostname.sh
        
        # Enable the service
        arch-chroot /mnt systemctl enable hostname-protection.service
        
        # Set up hostname password authentication
        cat > /mnt/etc/pam.d/hostname-auth <<EOF
auth required pam_unix.so
account required pam_unix.so
EOF
        
        # Store the password hash securely using a better method
        echo -e "${BLUE}Setting hostname password...${NC}"
        arch-chroot /mnt useradd -r -s /sbin/nologin _hostname_protection
        arch-chroot /mnt sh -c "echo '_hostname_protection:$HOSTNAME_PASSWORD' | chpasswd"
    fi
    
    # Set timezone
    echo -e "${BLUE}Setting timezone to $TIMEZONE...${NC}"
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
    arch-chroot /mnt hwclock --systohc
    
    # Set locale
    echo -e "${BLUE}Configuring locale to $LOCALE...${NC}"
    # First uncomment all UTF-8 locales that might be needed
    sed -i "s/^#\(.*\.UTF-8\)/\1/" /mnt/etc/locale.gen
    # Then generate locales
    arch-chroot /mnt locale-gen
    # Set the chosen locale as the system default
    echo "LANG=$LOCALE" > /mnt/etc/locale.conf
    # Set other locale settings
    echo "LC_ADDRESS=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_IDENTIFICATION=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_MEASUREMENT=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_MONETARY=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_NAME=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_NUMERIC=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_PAPER=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_TELEPHONE=$LOCALE" >> /mnt/etc/locale.conf
    echo "LC_TIME=$LOCALE" >> /mnt/etc/locale.conf
    
    # Set keyboard layout
    echo -e "${BLUE}Setting keyboard layout to $KEYBOARD...${NC}"
    echo "KEYMAP=$KEYBOARD" > /mnt/etc/vconsole.conf
    
    # Enable network services
    echo -e "${BLUE}Enabling network services...${NC}"
    arch-chroot /mnt systemctl enable NetworkManager
    
    return 0
}

create_user() {
    echo "Creating user $USERNAME..."
    
    # Create user with or without sudo privileges
    echo -e "${BLUE}Creating user $USERNAME...${NC}"
    if [ "$SUDO_ENABLED" = true ]; then
        arch-chroot /mnt useradd -m -G wheel -s /bin/bash $USERNAME
    else
        arch-chroot /mnt useradd -m -s /bin/bash $USERNAME
    fi
    
    # Set root password
    echo -e "${BLUE}Setting root password...${NC}"
    echo "root:password" | arch-chroot /mnt chpasswd
    
    # Set user password (custom or default)
    echo -e "${BLUE}Setting password for $USERNAME...${NC}"
    if [ -n "$USER_PASSWORD" ]; then
        echo "$USERNAME:$USER_PASSWORD" | arch-chroot /mnt chpasswd
    else
        echo "$USERNAME:password" | arch-chroot /mnt chpasswd
    fi
    
    # Configure sudo access if enabled
    if [ "$SUDO_ENABLED" = true ]; then
        echo -e "${BLUE}Configuring sudo access...${NC}"
        echo "%wheel ALL=(ALL) ALL" > /mnt/etc/sudoers.d/wheel
        echo -e "${GREEN}User $USERNAME created with sudo privileges.${NC}"
    else
        echo -e "${GREEN}User $USERNAME created without sudo privileges.${NC}"
    fi
    
    return 0
}

# Audio system selection function
select_audio_system() {
    # Show header explaining audio systems
    whiptail --title "$(get_text audio_title)" --msgbox "$(get_text audio_text)" 14 70

    AUDIO_SYSTEM=$(whiptail --title "$(get_text audio_title)" --notags --radiolist \
    "$(get_text audio_prompt)" 12 70 3 \
    "none" "$(get_text audio_none)" ON \
    "pulseaudio" "$(get_text audio_pulse)" OFF \
    "pipewire" "$(get_text audio_pipewire)" OFF \
    3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        # Show confirmation of selection
        local selection_text="$(get_text audio_none)"
        
        if [ "$AUDIO_SYSTEM" = "pulseaudio" ]; then
            selection_text="$(get_text audio_pulse)"
        elif [ "$AUDIO_SYSTEM" = "pipewire" ]; then
            selection_text="$(get_text audio_pipewire)"
        else
            selection_text="$(get_text audio_none)"
        fi
        
        whiptail --title "$(get_text audio_title)" --msgbox "$(printf "$(get_text audio_selected)" "$selection_text")" 8 70
        
        whiptail --title "Audio System Selection" --msgbox "Audio system selected: $selection_text" 8 70
    fi
    
    return 0
}
# UKI configuration function
configure_uki_option() {
    whiptail --title "Unified Kernel Images" --notags --yesno "Enable Unified Kernel Images (UKI)?\n\nUKIs combine the kernel, initramfs, and command line into a single EFI executable.\nThis can simplify boot management and enhance security." 12 70 3>&1 1>&2 2>&3
    if [ $? -eq 0 ]; then
        UKI_ENABLED=true
        echo -e "${GREEN}Unified Kernel Images enabled.${NC}"
    else
        UKI_ENABLED=false
        echo -e "${YELLOW}Unified Kernel Images not enabled.${NC}"
    fi
    return 0
}

# Desktop Environment selection function
select_desktop_environment() {
    local de_options=(
        "none" "No Desktop Environment (CLI only)" ON
        "gnome" "GNOME - Modern, feature-rich desktop environment" OFF
        "kde" "KDE Plasma - Customizable and feature-rich desktop" OFF
        "xfce" "XFCE - Lightweight and stable desktop environment" OFF
        "mate" "MATE - Traditional desktop environment" OFF
        "cinnamon" "Cinnamon - Elegant and comfortable desktop" OFF
        "lxde" "LXDE - Extremely lightweight desktop environment" OFF
        "lxqt" "LXQt - Lightweight Qt desktop environment" OFF
        "i3" "i3 - Tiling window manager with minimal resources" OFF
        "sway" "Sway - Wayland compositor based on i3's layout" OFF
        "awesome" "Awesome - Dynamic window manager with Lua scripts" OFF
        "dwm" "DWM - Dynamic Window Manager, minimal and fast" OFF
    )
    
    DE_SELECTION=$(whiptail --title "Desktop Environment Selection" --notags --radiolist \
    "Choose a desktop environment or window manager to install:\n\nNote: You can install additional environments later." 24 78 12 \
    "${de_options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        DE_CONFIGURED=true
        
        local de_name=""
        case "$DE_SELECTION" in
            "none") de_name="No Desktop Environment (CLI only)" ;;
            "gnome") de_name="GNOME Desktop" ;;
            "kde") de_name="KDE Plasma Desktop" ;;
            "xfce") de_name="XFCE Desktop" ;;
            "mate") de_name="MATE Desktop" ;;
            "cinnamon") de_name="Cinnamon Desktop" ;;
            "lxde") de_name="LXDE Desktop" ;;
            "lxqt") de_name="LXQt Desktop" ;;
            "i3") de_name="i3 Window Manager" ;;
            "sway") de_name="Sway Compositor" ;;
            "awesome") de_name="Awesome Window Manager" ;;
            "dwm") de_name="DWM Window Manager" ;;
        esac
        
        whiptail --title "Desktop Environment Selection" --msgbox "You have selected: $de_name\n\nThis will be installed during system setup." 10 70
        return 0
    fi
    return 1
}

# Package profile selection function
select_package_profile() {
    local profile_options=(
        "minimal" "Basic system with essential packages only" OFF
        "standard" "Balanced selection of common packages" ON
        "full" "Comprehensive set of packages for most use cases" OFF
    )
    
    local descriptions=(
        "Minimal:\n • Base system, kernel, and boot utilities\n • Networking utilities\n • Basic command-line tools\n • No GUI applications"
        "Standard:\n • Everything in minimal\n • Common utilities (zip, unzip, wget, etc.)\n • Basic multimedia support\n • Development tools\n • Common GUI applications (if DE selected)"
        "Full:\n • Everything in standard\n • Extended multimedia tools\n • Full office suite\n • Image editing and creative applications\n • Additional development tools\n • Various utility applications"
    )
    
    PACKAGE_PROFILE=$(whiptail --title "Package Selection" --notags --radiolist \
    "Choose a package profile for your installation:" 16 78 3 \
    "${profile_options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        PACKAGE_CONFIGURED=true
        
        local profile_index=0
        case "$PACKAGE_PROFILE" in
            "minimal") profile_index=0 ;;
            "standard") profile_index=1 ;;
            "full") profile_index=2 ;;
        esac
        
        whiptail --title "Package Profile" --msgbox "You have selected: ${PACKAGE_PROFILE^} profile\n\n${descriptions[$profile_index]}" 16 70
        return 0
    fi
    return 1
}

# Network configuration function
configure_network() {
    local network_options=(
        "NetworkManager" "User-friendly network management (recommended)" ON
        "systemd-networkd" "Lightweight, systemd-based network management" OFF
        "iwd" "Internet Wireless Daemon, minimal wireless networking" OFF
        "netctl" "Simple network configuration tool" OFF
    )
    
    local descriptions=(
        "NetworkManager:\n • User-friendly network management\n • GUI tools available\n • Automatic connection handling\n • VPN support\n • Mobile broadband support"
        "systemd-networkd:\n • Lightweight network management\n • Integrated with systemd\n • Configuration through files\n • Suitable for servers and minimal installations"
        "iwd:\n • Minimal wireless networking daemon\n • Low memory footprint\n • Fast connection establishment\n • Can be used standalone or with NetworkManager"
        "netctl:\n • Simple command line tool\n • Profile-based configuration\n • Manual connection management\n • Suitable for advanced users"
    )
    
    NETWORK_MANAGER=$(whiptail --title "Network Configuration" --notags --radiolist \
    "Choose a network management solution:" 16 78 4 \
    "${network_options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        NETWORK_CONFIGURED=true
        
        local nm_index=0
        case "$NETWORK_MANAGER" in
            "NetworkManager") nm_index=0 ;;
            "systemd-networkd") nm_index=1 ;;
            "iwd") nm_index=2 ;;
            "netctl") nm_index=3 ;;
        esac
        
        whiptail --title "Network Configuration" --msgbox "You have selected: $NETWORK_MANAGER\n\n${descriptions[$nm_index]}" 16 70
        return 0
    fi
    return 1
}

# Development tools selection function
select_development_tools() {
    local dev_options=(
        "base-devel" "Essential development packages (compiler, make, etc.)" ON
        "git" "Version control system" ON
        "python" "Python programming language and utilities" OFF
        "nodejs" "JavaScript runtime environment" OFF
        "rust" "Rust programming language" OFF
        "go" "Go programming language" OFF
        "java" "OpenJDK Java development kit" OFF
        "php" "PHP scripting language" OFF
        "ruby" "Ruby programming language" OFF
        "vscode" "Visual Studio Code editor" OFF
        "vim" "Advanced text editor" OFF
        "docker" "Container platform" OFF
        "databases" "Common database systems (MySQL, PostgreSQL, SQLite)" OFF
    )
    
    # Use checklist to allow multiple selections
    DEV_TOOLS=$(whiptail --title "Development Environment" --notags --checklist \
    "Select development tools to install (use SPACE to select):" 20 78 13 \
    "${dev_options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        DEV_TOOLS_CONFIGURED=true
        
        if [ -z "$DEV_TOOLS" ]; then
            whiptail --title "Development Environment" --msgbox "No development tools selected." 8 70
        else
            # Format the selected tools for display
            local formatted_tools=""
            for tool in $(echo "$DEV_TOOLS" | tr -d '"' | tr ' ' '\n'); do
                formatted_tools="$formatted_tools\n • $tool"
            done
            
            whiptail --title "Development Environment" --msgbox "Selected development tools:$formatted_tools" 16 70
        fi
        return 0
    fi
    return 1
}

# Virtualization configuration function
configure_virtualization() {
    local virt_options=(
        "none" "No virtualization support" ON
        "kvm" "KVM/QEMU full virtualization" OFF
        "virtualbox" "Oracle VirtualBox" OFF
        "docker" "Docker container platform" OFF
        "lxc" "LXC Linux containers" OFF
    )
    
    local descriptions=(
        "No virtualization support will be installed."
        "KVM/QEMU:\n • Hardware-accelerated virtualization\n • Native Linux virtualization solution\n • Excellent performance\n • Includes libvirt and virt-manager"
        "VirtualBox:\n • Cross-platform virtualization\n • User-friendly interface\n • Good for desktop use\n • Slightly lower performance than KVM"
        "Docker:\n • Container platform\n • Lightweight application isolation\n • Excellent for development and deployment\n • Not full virtualization"
        "LXC:\n • Linux container system\n • System-level containerization\n • Lower overhead than full VMs\n • Good for service isolation"
    )
    
    VIRTUALIZATION=$(whiptail --title "Virtualization Options" --notags --radiolist \
    "Choose virtualization technology to install:" 16 78 5 \
    "${virt_options[@]}" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        VIRTUALIZATION_CONFIGURED=true
        
        local virt_index=0
        case "$VIRTUALIZATION" in
            "none") virt_index=0 ;;
            "kvm") virt_index=1 ;;
            "virtualbox") virt_index=2 ;;
            "docker") virt_index=3 ;;
            "lxc") virt_index=4 ;;
        esac
        
        whiptail --title "Virtualization Options" --msgbox "You have selected: ${VIRTUALIZATION^}\n\n${descriptions[$virt_index]}" 16 70
        return 0
    fi
    return 1
}

# Bootloader functions
install_grub() {
    echo "Installing GRUB bootloader..."
    
    # Install GRUB packages
    echo -e "${BLUE}Installing GRUB packages...${NC}"
    arch-chroot /mnt pacman -S --noconfirm grub efibootmgr os-prober
    
    # If secure boot is enabled, install required packages
    if [ "$SECURE_BOOT" = true ]; then
        echo -e "${BLUE}Installing packages for Secure Boot support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm sbsigntools
    fi
    
    # If TPM is enabled, install tpm2-tools
    if [ "$TPM_ENABLED" = true ]; then
        echo -e "${BLUE}Installing packages for TPM 2.0 support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm tpm2-tools
    fi
    
    # Install GRUB to EFI partition
    # Install GRUB to EFI partition
    echo -e "${BLUE}Installing GRUB for UEFI...${NC}"
    
    # Configure UKI if enabled
    if [ "$UKI_ENABLED" = true ]; then
        echo -e "${BLUE}Configuring for Unified Kernel Images...${NC}"
        # Install required packages for UKI
        arch-chroot /mnt pacman -S --noconfirm binutils
        
        # Create directory for UKI
        mkdir -p /mnt/boot/efi/EFI/Linux
    fi
    
    arch-chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
    # Add support for LUKS encryption if enabled
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        echo -e "${BLUE}Configuring GRUB for LUKS encryption...${NC}"
        # Install required package for encryption
        arch-chroot /mnt pacman -S --noconfirm lvm2
        
        # Modify GRUB configuration for encryption
        sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="cryptdevice=UUID='"$(blkid -s UUID -o value $UNENCRYPTED_ROOT_PARTITION)"':'"$LUKS_DEVICE_NAME"' root=\/dev\/mapper\/'"$LUKS_DEVICE_NAME"'"/' /mnt/etc/default/grub
        
        # Enable crypto modules in GRUB
        sed -i 's/#GRUB_ENABLE_CRYPTODISK=y/GRUB_ENABLE_CRYPTODISK=y/' /mnt/etc/default/grub
    fi
    
    # Generate GRUB configuration
    echo -e "${BLUE}Generating GRUB configuration...${NC}"
    arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    
    echo -e "${GREEN}GRUB installed successfully.${NC}"
    return 0
}

install_systemd_boot() {
    echo "Installing systemd-boot..."
    
    # systemd-boot is included with systemd, so we don't need to install it separately
    echo -e "${BLUE}Installing systemd-boot...${NC}"
    arch-chroot /mnt bootctl --path=/boot/efi install
    
    # Create loader configuration
    echo -e "${BLUE}Creating loader configuration...${NC}"
    mkdir -p /mnt/boot/efi/loader/entries
    
    # Create default loader config
    cat > /mnt/boot/efi/loader/loader.conf <<EOF
default arch.conf
timeout 3
editor 0
EOF
    
    # Determine the root partition UUID
    # Determine the root partition UUID
    ROOT_UUID=$(blkid -s UUID -o value $ROOT_PARTITION)
    
    # Create arch entry with encryption support if enabled
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        # Get UUID of the encrypted partition
        CRYPT_UUID=$(blkid -s UUID -o value $UNENCRYPTED_ROOT_PARTITION)
        
        # Create entry with encryption parameters
        cat > /mnt/boot/efi/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options cryptdevice=UUID=$CRYPT_UUID:$LUKS_DEVICE_NAME root=/dev/mapper/$LUKS_DEVICE_NAME rw
EOF
    else
        # Create standard entry without encryption
        cat > /mnt/boot/efi/loader/entries/arch.conf <<EOF
title Arch Linux
linux /vmlinuz-linux
initrd /initramfs-linux.img
options root=UUID=$ROOT_UUID rw
EOF
    fi
    # If secure boot is enabled, install required packages
    if [ "$SECURE_BOOT" = true ]; then
        echo -e "${BLUE}Installing packages for Secure Boot support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm sbsigntools
    fi
    
    # If TPM is enabled, install tpm2-tools
    if [ "$TPM_ENABLED" = true ]; then
        echo -e "${BLUE}Installing packages for TPM 2.0 support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm tpm2-tools
    fi
    
    # Copy kernel and initramfs to ESP
    echo -e "${BLUE}Copying kernel and initramfs to ESP...${NC}"
    mkdir -p /mnt/boot/efi
    
    # Handle UKI if enabled
    if [ "$UKI_ENABLED" = true ]; then
        echo -e "${BLUE}Creating Unified Kernel Images...${NC}"
        # Install required packages
        arch-chroot /mnt pacman -S --noconfirm binutils
        
        # Create directory for UKI
        mkdir -p /mnt/boot/efi/EFI/Linux
        
        # Create a script to generate UKI
        cat > /mnt/usr/local/bin/generate-uki.sh <<EOF
#!/bin/bash
# Script to generate Unified Kernel Images

# Get the root UUID
ROOT_UUID=\$(blkid -s UUID -o value $(readlink -f /dev/disk/by-label/ROOT || echo "/dev/sda3"))

# Create UKI directory if it doesn't exist
mkdir -p /boot/efi/EFI/Linux

# Create UKI
objcopy \\
  --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \\
  --add-section .cmdline=<(echo "root=UUID=\$ROOT_UUID rw quiet") --change-section-vma .cmdline=0x30000 \\
  --add-section .linux="/boot/vmlinuz-linux" --change-section-vma .linux=0x40000 \\
  --add-section .initrd="/boot/initramfs-linux.img" --change-section-vma .initrd=0x3000000 \\
  /usr/lib/systemd/boot/efi/linuxx64.efi.stub \\
  /boot/efi/EFI/Linux/ArchLinux-linux.efi

# Also create a fallback UKI
objcopy \\
  --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \\
  --add-section .cmdline=<(echo "root=UUID=\$ROOT_UUID rw quiet") --change-section-vma .cmdline=0x30000 \\
  --add-section .linux="/boot/vmlinuz-linux" --change-section-vma .linux=0x40000 \\
  --add-section .initrd="/boot/initramfs-linux-fallback.img" --change-section-vma .initrd=0x3000000 \\
  /usr/lib/systemd/boot/efi/linuxx64.efi.stub \\
  /boot/efi/EFI/Linux/ArchLinux-linux-fallback.efi

echo "Unified Kernel Images generated successfully"
EOF
        
        # Make the script executable
        chmod +x /mnt/usr/local/bin/generate-uki.sh
        
        # Create a systemd service to update UKI on kernel updates
        cat > /mnt/etc/systemd/system/generate-uki.service <<EOF
[Unit]
Description=Generate Unified Kernel Images
After=initrd-generation.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/generate-uki.sh

[Install]
WantedBy=multi-user.target
EOF

        # Create a pacman hook for kernel updates
        mkdir -p /mnt/etc/pacman.d/hooks
        cat > /mnt/etc/pacman.d/hooks/95-generate-uki.hook <<EOF
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = linux
Target = linux-lts
Target = linux-zen
Target = linux-hardened

[Action]
Description = Generating Unified Kernel Images...
When = PostTransaction
Exec = /usr/local/bin/generate-uki.sh
Depends = binutils
EOF

        # Run the script once to generate initial UKIs
        arch-chroot /mnt /usr/local/bin/generate-uki.sh
        
        # Enable the service
        arch-chroot /mnt systemctl enable generate-uki.service
        
        echo -e "${GREEN}Unified Kernel Images configured.${NC}"
    else
        # Standard copy without UKI
        cp /mnt/boot/vmlinuz-linux /mnt/boot/efi/
        cp /mnt/boot/initramfs-linux.img /mnt/boot/efi/
    fi
    
    echo -e "${GREEN}systemd-boot installed successfully.${NC}"
    return 0
}

install_systemd_boot_efistub() {
    
    # Install necessary packages
    echo -e "${BLUE}Installing required packages...${NC}"
    arch-chroot /mnt pacman -S --noconfirm efibootmgr
    
    # Install systemd-boot (minimal bootloader)
    echo -e "${BLUE}Installing systemd-boot...${NC}"
    arch-chroot /mnt bootctl --path=/boot/efi install
    
    # Create basic loader configuration
    echo -e "${BLUE}Creating basic loader configuration...${NC}"
    mkdir -p /mnt/boot/efi/loader
    
    # Create minimal loader config (only as fallback)
    cat > /mnt/boot/efi/loader/loader.conf <<EOF
timeout 3
# This loader config is only used as fallback
# Primary boot method is via direct EFISTUB entries in EFI
EOF
    
    # Determine the root partition UUID
    ROOT_UUID=$(blkid -s UUID -o value $ROOT_PARTITION)
    # Determine kernel parameters
    KERNEL_PARAMS="root=UUID=$ROOT_UUID rw quiet"
    
    # For encrypted systems, modify kernel parameters
    # For encrypted systems, modify kernel parameters
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        # Get UUID of the encrypted partition
        # Get UUID of the encrypted partition
        CRYPT_UUID=$(blkid -s UUID -o value $UNENCRYPTED_ROOT_PARTITION)
        KERNEL_PARAMS="cryptdevice=UUID=$CRYPT_UUID:$LUKS_DEVICE_NAME root=/dev/mapper/$LUKS_DEVICE_NAME rw quiet"
    fi
    
    # If secure boot is enabled, install required packages
    if [ "$SECURE_BOOT" = true ]; then
        echo -e "${BLUE}Installing packages for Secure Boot support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm sbsigntools
    fi
    
    # If TPM is enabled, install tpm2-tools
    if [ "$TPM_ENABLED" = true ]; then
        echo -e "${BLUE}Installing packages for TPM 2.0 support...${NC}"
        arch-chroot /mnt pacman -S --noconfirm tpm2-tools
        
        # Modify kernel parameters for TPM if needed
        KERNEL_PARAMS="$KERNEL_PARAMS tpm_tis.force=1 tpm_tis.interrupts=0"
    fi
    
    # Install the EFISTUB boot entries
    echo -e "${BLUE}Installing EFISTUB entries in EFI boot manager...${NC}"
    
    # Create the EFI boot entries for the main kernel
    echo -e "${BLUE}Creating EFI boot entry for Linux kernel...${NC}"
    arch-chroot /mnt efibootmgr --create --disk $DISK_DEVICE --part 1 \
        --label "Arch Linux" \
        --loader /vmlinuz-linux \
        --unicode "initrd=\\initramfs-linux.img $KERNEL_PARAMS"
    # Create fallback entry
    echo -e "${BLUE}Creating EFI boot entry for fallback initramfs...${NC}"
    arch-chroot /mnt efibootmgr --create --disk $DISK_DEVICE --part 1 \
        --label "Arch Linux (fallback)" \
        --loader /vmlinuz-linux \
        --unicode "initrd=\\initramfs-linux-fallback.img $KERNEL_PARAMS"
    
    # Handle UKI if enabled
    if [ "$UKI_ENABLED" = true ]; then
        echo -e "${BLUE}Setting up Unified Kernel Images...${NC}"
        # Install required packages
        arch-chroot /mnt pacman -S --noconfirm binutils
        
        # Create directory for UKI
        mkdir -p /mnt/boot/efi/EFI/Linux
        
        # Create a script to generate UKI
        cat > /mnt/usr/local/bin/generate-uki.sh <<EOF
#!/bin/bash
# Script to generate Unified Kernel Images for EFISTUB

# Get the root UUID
ROOT_UUID=\$(blkid -s UUID -o value $(readlink -f /dev/disk/by-label/ROOT || echo "/dev/sda3"))

# Create UKI directory if it doesn't exist
mkdir -p /boot/efi/EFI/Linux

# Define kernel parameters
KERNEL_PARAMS="$KERNEL_PARAMS"

# Create UKI
objcopy \
  --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \
  --add-section .cmdline=<(echo "\$KERNEL_PARAMS") --change-section-vma .cmdline=0x30000 \
  --add-section .linux="/boot/vmlinuz-linux" --change-section-vma .linux=0x40000 \
  --add-section .initrd="/boot/initramfs-linux.img" --change-section-vma .initrd=0x3000000 \
  /usr/lib/systemd/boot/efi/linuxx64.efi.stub \
  /boot/efi/EFI/Linux/ArchLinux-linux.efi

# Also create a fallback UKI
objcopy \
  --add-section .osrel="/usr/lib/os-release" --change-section-vma .osrel=0x20000 \\
  --add-section .cmdline=<(echo "\$KERNEL_PARAMS") --change-section-vma .cmdline=0x30000 \\
  --add-section .linux="/boot/vmlinuz-linux" --change-section-vma .linux=0x40000 \\
  --add-section .initrd="/boot/initramfs-linux-fallback.img" --change-section-vma .initrd=0x3000000 \\
  /usr/lib/systemd/boot/efi/linuxx64.efi.stub \\
  /boot/efi/EFI/Linux/ArchLinux-linux-fallback.efi

# Create EFI boot entries for the UKI files
efibootmgr --create --disk $DISK_DEVICE --part 1 \\
    --label "Arch Linux (UKI)" \\
    --loader /EFI/Linux/ArchLinux-linux.efi

efibootmgr --create --disk $DISK_DEVICE --part 1 \\
    --label "Arch Linux (UKI fallback)" \\
    --loader /EFI/Linux/ArchLinux-linux-fallback.efi

echo "Unified Kernel Images generated successfully"
EOF
        
        # Make the script executable
        chmod +x /mnt/usr/local/bin/generate-uki.sh
        
        # Create a systemd service to update UKI on kernel updates
        cat > /mnt/etc/systemd/system/generate-uki.service <<EOF
[Unit]
Description=Generate Unified Kernel Images for EFISTUB
After=initrd-generation.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/generate-uki.sh

[Install]
WantedBy=multi-user.target
EOF
        
        # Create a pacman hook for kernel updates
        mkdir -p /mnt/etc/pacman.d/hooks
        cat > /mnt/etc/pacman.d/hooks/95-generate-uki.hook <<EOF
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = linux
Target = linux-lts
Target = linux-zen
Target = linux-hardened

[Action]
Description = Generating Unified Kernel Images for EFISTUB...
When = PostTransaction
Exec = /usr/local/bin/generate-uki.sh
Depends = binutils
EOF
        
        # Run the script once to generate initial UKIs
        arch-chroot /mnt /usr/local/bin/generate-uki.sh
        
        # Enable the service
        arch-chroot /mnt systemctl enable generate-uki.service
        
        echo -e "${GREEN}Unified Kernel Images configured for EFISTUB.${NC}"
    else
        # Basic EFISTUB setup without UKI
        echo -e "${BLUE}Setting up direct kernel boot files...${NC}"
        
        # Copy kernel and initramfs to /boot/efi
        cp /mnt/boot/vmlinuz-linux /mnt/boot/efi/
        cp /mnt/boot/initramfs-linux.img /mnt/boot/efi/
        cp /mnt/boot/initramfs-linux-fallback.img /mnt/boot/efi/
        
        # Create a pacman hook to automatically copy kernels to ESP
        mkdir -p /mnt/etc/pacman.d/hooks
        cat > /mnt/etc/pacman.d/hooks/95-copy-kernel.hook <<EOF
[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = linux
Target = linux-lts
Target = linux-zen
Target = linux-hardened

[Action]
Description = Copying kernel to ESP for EFISTUB boot...
When = PostTransaction
Exec = /usr/bin/cp /boot/vmlinuz-linux /boot/efi/vmlinuz-linux && /usr/bin/cp /boot/initramfs-linux.img /boot/efi/initramfs-linux.img && /usr/bin/cp /boot/initramfs-linux-fallback.img /boot/efi/initramfs-linux-fallback.img
EOF
    fi
    
    echo -e "${GREEN}systemd-boot with EFISTUB kernel booting installed successfully.${NC}"
    echo -e "${YELLOW}Note: The system will boot directly to the kernel using EFISTUB.${NC}"
    echo -e "${YELLOW}systemd-boot is installed as a fallback boot option only.${NC}"
    return 0
}

install_refind() {
    echo "Installing rEFInd..."
    
    # Ask user if they want to enable touchscreen support
    local REFIND_TOUCH_ENABLED=false
    whiptail --title "rEFInd Touchscreen Support" --yesno "Would you like to enable touchscreen support for rEFInd?\n\nThis will configure rEFInd to work with touchscreens, allowing:\n- Touch to select boot options\n- Swipe gestures for navigation\n- On-screen keyboard support for password entry" 14 70
    if [ $? -eq 0 ]; then
        REFIND_TOUCH_ENABLED=true
        echo -e "${BLUE}Touchscreen support will be enabled for rEFInd.${NC}"
    else
        echo -e "${YELLOW}Touchscreen support will not be enabled for rEFInd.${NC}"
    fi
    
    # Install rEFInd package
    echo -e "${BLUE}Installing rEFInd packages...${NC}"
    arch-chroot /mnt pacman -S --noconfirm refind
    
    # Install rEFInd to ESP
    echo -e "${BLUE}Installing rEFInd to ESP...${NC}"
    arch-chroot /mnt refind-install
    
    # Determine the root partition UUID
    ROOT_UUID=$(blkid -s UUID -o value $ROOT_PARTITION)
    
    # Add kernel options to refind_linux.conf with encryption support if enabled
    echo -e "${BLUE}Configuring refind_linux.conf...${NC}"
    
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        # Get UUID of the encrypted partition
        CRYPT_UUID=$(blkid -s UUID -o value $UNENCRYPTED_ROOT_PARTITION)
        
        # Create config with encryption parameters
        cat > /mnt/boot/refind_linux.conf <<EOF
"Boot with standard options" "cryptdevice=UUID=$CRYPT_UUID:$LUKS_DEVICE_NAME root=/dev/mapper/$LUKS_DEVICE_NAME rw quiet"
"Boot with fallback initramfs" "cryptdevice=UUID=$CRYPT_UUID:$LUKS_DEVICE_NAME root=/dev/mapper/$LUKS_DEVICE_NAME rw quiet initrd=/boot/initramfs-linux-fallback.img"
"Boot with minimal options" "cryptdevice=UUID=$CRYPT_UUID:$LUKS_DEVICE_NAME root=/dev/mapper/$LUKS_DEVICE_NAME rw"
EOF
    else
        # Create standard config without encryption
        cat > /mnt/boot/refind_linux.conf <<EOF
"Boot with standard options" "root=UUID=$ROOT_UUID rw quiet"
"Boot with fallback initramfs" "root=UUID=$ROOT_UUID rw quiet initrd=/boot/initramfs-linux-fallback.img"
"Boot with minimal options" "root=UUID=$ROOT_UUID rw"
EOF
    fi
    
    # Configure touchscreen support if enabled
    if [ "$REFIND_TOUCH_ENABLED" = true ]; then
        echo -e "${BLUE}Configuring touchscreen support for rEFInd...${NC}"
        
        # Add or modify touchscreen settings in refind.conf
        # First check if the file exists
        local REFIND_CONF="/mnt/boot/efi/EFI/refind/refind.conf"
        if [ ! -f "$REFIND_CONF" ]; then
            REFIND_CONF="/mnt/boot/efi/EFI/BOOT/refind.conf"
        fi
        
        if [ -f "$REFIND_CONF" ]; then
            # Add touchscreen configuration to refind.conf
            cat >> "$REFIND_CONF" <<EOF

# Touchscreen support configuration
# These settings enable and configure touchscreen input for rEFInd
# Touchscreen support allows users to interact with the boot menu using touch gestures

# Enable touch input
enable_touch

# Touch-related settings
touch_size 64                    # Size of touch targets in pixels (larger values make touch targets bigger)
touch_deadzone 16                # Deadzone for touch input (prevents accidental activation)

# Advanced touch options
mouse_size 16                    # Size of touch pointer indicator
mouse_speed 4                    # Speed of touch pointer movement
use_touch_interface large        # Use larger interface elements optimized for touch screens
EOF

            echo -e "${GREEN}Touchscreen support configured successfully.${NC}"
        else
            echo -e "${RED}Error: Could not find refind.conf to configure touchscreen support.${NC}"
        fi
    else
        # Even if touchscreen is not enabled, add commented instructions for future reference
        local REFIND_CONF="/mnt/boot/efi/EFI/refind/refind.conf"
        if [ ! -f "$REFIND_CONF" ]; then
            REFIND_CONF="/mnt/boot/efi/EFI/BOOT/refind.conf"
        fi
        
        if [ -f "$REFIND_CONF" ]; then
            cat >> "$REFIND_CONF" <<EOF

# Touchscreen support is currently disabled
# To enable touchscreen support in the future, uncomment and adjust the following settings:
#
# enable_touch
# touch_size 64
# touch_deadzone 16
# mouse_size 16
# mouse_speed 4
# use_touch_interface large
EOF
        fi
    fi
    
    echo -e "${GREEN}rEFInd installed successfully.${NC}"
    return 0
}

# Secure Boot and TPM functions
configure_secure_boot() {
    echo "Configuring Secure Boot..."
    
    # Install required packages if not installed already
    echo -e "${BLUE}Installing packages for Secure Boot...${NC}"
    arch-chroot /mnt pacman -S --noconfirm efitools sbsigntools
    
    # Create Secure Boot keys directory
    echo -e "${BLUE}Creating Secure Boot keys...${NC}"
    mkdir -p /mnt/etc/secureboot/keys
    
    # Generate keys
    echo -e "${BLUE}Generating Secure Boot keys...${NC}"
    arch-chroot /mnt bash -c "cd /etc/secureboot/keys && \
        openssl req -newkey rsa:2048 -nodes -keyout PK.key -new -x509 -sha256 -days 3650 -subj '/CN=Platform Key/' -out PK.crt && \
        openssl req -newkey rsa:2048 -nodes -keyout KEK.key -new -x509 -sha256 -days 3650 -subj '/CN=Key Exchange Key/' -out KEK.crt && \
        openssl req -newkey rsa:2048 -nodes -keyout DB.key -new -x509 -sha256 -days 3650 -subj '/CN=Signature Database key/' -out DB.crt"
    
    # Create signed EFI variables
    echo -e "${BLUE}Creating signed EFI variables...${NC}"
    arch-chroot /mnt bash -c "cd /etc/secureboot/keys && \
        cert-to-efi-sig-list -g \"$(uuidgen)\" PK.crt PK.esl && \
        cert-to-efi-sig-list -g \"$(uuidgen)\" KEK.crt KEK.esl && \
        cert-to-efi-sig-list -g \"$(uuidgen)\" DB.crt DB.esl && \
        sign-efi-sig-list -k PK.key -c PK.crt PK PK.esl PK.auth && \
        sign-efi-sig-list -k PK.key -c PK.crt KEK KEK.esl KEK.auth && \
        sign-efi-sig-list -k KEK.key -c KEK.crt db DB.esl DB.auth"
    
    # Sign bootloader
    if [ "$BOOTLOADER" = "grub" ]; then
        echo -e "${BLUE}Signing GRUB for Secure Boot...${NC}"
        arch-chroot /mnt bash -c "sbsign --key /etc/secureboot/keys/DB.key --cert /etc/secureboot/keys/DB.crt --output /boot/efi/EFI/GRUB/grubx64.efi /boot/efi/EFI/GRUB/grubx64.efi.unsigned"
    elif [ "$BOOTLOADER" = "systemd-boot" ]; then
        echo -e "${BLUE}Signing systemd-boot for Secure Boot...${NC}"
        # Sign systemd-boot and kernel
        arch-chroot /mnt bash -c "sbsign --key /etc/secureboot/keys/DB.key --cert /etc/secureboot/keys/DB.crt --output /boot/efi/EFI/systemd/systemd-bootx64.efi /boot/efi/EFI/systemd/systemd-bootx64.efi.unsigned"
    elif [ "$BOOTLOADER" = "refind" ]; then
        echo -e "${BLUE}Signing rEFInd for Secure Boot...${NC}"
        arch-chroot /mnt bash -c "sbsign --key /etc/secureboot/keys/DB.key --cert /etc/secureboot/keys/DB.crt --output /boot/efi/EFI/refind/refind_x64.efi /boot/efi/EFI/refind/refind_x64.efi.unsigned"
    fi
    
    echo -e "${GREEN}Secure Boot configuration complete.${NC}"
    echo -e "${YELLOW}You will need to enroll the Secure Boot keys in your UEFI setup after rebooting.${NC}"
    echo -e "${YELLOW}Copy the keys from /etc/secureboot/keys to a USB drive before rebooting.${NC}"
    
    return 0
}

configure_tpm() {
    echo "Configuring TPM 2.0..."
    
    # Install required packages
    echo -e "${BLUE}Installing TPM 2.0 packages...${NC}"
    arch-chroot /mnt pacman -S --noconfirm tpm2-tools tpm2-abrmd
    
    # Enable TPM services
    echo -e "${BLUE}Enabling TPM services...${NC}"
    arch-chroot /mnt systemctl enable tpm2-abrmd.service
    
    # Configure kernel parameters for TPM
    echo -e "${BLUE}Configuring kernel parameters for TPM...${NC}"
    
    # Update bootloader configuration for TPM
    if [ "$BOOTLOADER" = "grub" ]; then
        # Add TPM parameters to GRUB
        echo -e "${BLUE}Updating GRUB configuration for TPM...${NC}"
        sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& tpm_tis.force=1 tpm_tis.interrupts=0/' /mnt/etc/default/grub
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    elif [ "$BOOTLOADER" = "systemd-boot" ]; then
        # Add TPM parameters to systemd-boot
        echo -e "${BLUE}Updating systemd-boot entries for TPM...${NC}"
        sed -i 's/options .*/& tpm_tis.force=1 tpm_tis.interrupts=0/' /mnt/boot/efi/loader/entries/arch.conf
    elif [ "$BOOTLOADER" = "refind" ]; then
        # Add TPM parameters to rEFInd
        echo -e "${BLUE}Updating rEFInd configuration for TPM...${NC}"
        sed -i 's/"Boot with standard options".*/"Boot with standard options" "root=UUID=$ROOT_UUID rw tpm_tis.force=1 tpm_tis.interrupts=0"/' /mnt/boot/refind_linux.conf
    fi
    
    # If TPM PIN is enabled, configure it
    if [ "$TPM_PIN_ENABLED" = true ]; then
        echo -e "${BLUE}Configuring TPM PIN...${NC}"
        # This would require additional configuration specific to the bootloader
        echo -e "${YELLOW}TPM PIN configuration not fully implemented.${NC}"
    fi
    
    echo -e "${GREEN}TPM 2.0 configuration complete.${NC}"
    return 0
}

# User input functions
get_hostname() {
    HOSTNAME=$(whiptail --inputbox "$(get_text hostname_prompt)" 8 60 "archlinux" --title "$(get_text hostname_title)" 3>&1 1>&2 2>&3)
    
    # Ask if the user wants to set a hostname password
    if [ $? -eq 0 ]; then
        whiptail --title "$(get_text hostname_title)" --yesno "$(get_text hostname_protect)" 8 70 3>&1 1>&2 2>&3
        if [ $? -eq 0 ]; then
            HOSTNAME_PASSWORD=$(whiptail --passwordbox "$(get_text hostname_pw_prompt)" 8 60 --title "$(get_text hostname_pw_title)" 3>&1 1>&2 2>&3)
            
            if [ -z "$HOSTNAME_PASSWORD" ]; then
                whiptail --title "$(get_text warning)" --msgbox "$(get_text hostname_pw_empty)" 8 60
                HOSTNAME_PASSWORD=""
            else
                # Confirm password
                PASSWORD_CONFIRM=$(whiptail --passwordbox "$(get_text hostname_pw_confirm)" 8 60 --title "$(get_text hostname_pw_title)" 3>&1 1>&2 2>&3)
                
                if [ "$HOSTNAME_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                    whiptail --title "$(get_text error)" --msgbox "$(get_text hostname_pw_mismatch)" 8 60
                    HOSTNAME_PASSWORD=""
                fi
            fi
        fi
    fi
    
    return $?
}

get_username() {
    # If username is already configured from command line, just return success
    if [ "$USERNAME_CONFIGURED" = true ] && [ -n "$USERNAME" ]; then
        # If we have username but not password, ask only for password
        if [ -z "$USER_PASSWORD" ]; then
            # Ask for user password with clear instructions
            whiptail --title "User Account Setup: Password" --msgbox "Now you will set a password for user '$USERNAME'.\n\nLeave empty to use the default password 'password'." 10 70
            
            USER_PASSWORD=$(whiptail --passwordbox "Enter password for user $USERNAME:" 10 70 --title "User Account Setup: Password" 3>&1 1>&2 2>&3)
            
            if [ -n "$USER_PASSWORD" ]; then
                # Confirm password with better error handling
                PASSWORD_CONFIRM=$(whiptail --passwordbox "Confirm password for user $USERNAME:" 10 70 --title "User Account Setup: Confirm Password" 3>&1 1>&2 2>&3)
                
                if [ "$USER_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                    whiptail --title "User Account Setup: Error" --msgbox "Passwords do not match.\n\nWould you like to try again or use the default password?" 10 60
                    
                    # Ask if user wants to try again
                    if whiptail --title "User Account Setup: Password" --yesno "Try entering password again?" 8 60 3>&1 1>&2 2>&3; then
                        # Try again
                        USER_PASSWORD=$(whiptail --passwordbox "Enter password for user $USERNAME:" 10 70 --title "User Account Setup: Password" 3>&1 1>&2 2>&3)
                        
                        if [ -n "$USER_PASSWORD" ]; then
                            PASSWORD_CONFIRM=$(whiptail --passwordbox "Confirm password for user $USERNAME:" 10 70 --title "User Account Setup: Confirm Password" 3>&1 1>&2 2>&3)
                            
                            if [ "$USER_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                                whiptail --title "User Account Setup: Error" --msgbox "Passwords still do not match. Using default password 'password'." 8 60
                                USER_PASSWORD=""
                            else
                                whiptail --title "User Account Setup: Success" --msgbox "Password set successfully for user $USERNAME." 8 60
                            fi
                        else
                            whiptail --title "User Account Setup: Note" --msgbox "No password entered. Using default password 'password'." 8 60
                            USER_PASSWORD=""
                        fi
                    else
                        # Use default password
                        whiptail --title "User Account Setup: Note" --msgbox "Using default password 'password' for user $USERNAME." 8 60
                        USER_PASSWORD=""
                    fi
                else
                    # Passwords match
                    whiptail --title "User Account Setup: Success" --msgbox "Password set successfully for user $USERNAME." 8 60
                fi
            else
                # No password entered, using default
                whiptail --title "User Account Setup: Note" --msgbox "No password entered. Using default password 'password' for user $USERNAME." 8 60
            fi
        fi
        
        # Ask about sudo privileges if not already handled by command line
        whiptail --title "User Account Setup: Administrator Privileges" --yesno "Would you like to grant administrator (sudo) privileges to user $USERNAME?\n\nWith sudo privileges, this user can:\n- Install and remove software\n- Modify system settings\n- Perform administrative tasks\n\nWithout sudo privileges, the user will have limited access." 16 70 3>&1 1>&2 2>&3
        
        if [ $? -eq 0 ]; then
            SUDO_ENABLED=true
            whiptail --title "User Account Setup: Administrator Privileges" --msgbox "Administrator privileges granted to user $USERNAME." 8 70
        else
            SUDO_ENABLED=false
            whiptail --title "User Account Setup: Administrator Privileges" --msgbox "User $USERNAME will have standard (non-administrator) privileges." 8 70
        fi
        
        # Final summary of user configuration
        local SUDO_STATUS="No"
        if [ "$SUDO_ENABLED" = true ]; then
            SUDO_STATUS="Yes"
        fi
        
        local PASSWORD_STATUS="Default ('password')"
        if [ -n "$USER_PASSWORD" ]; then
            PASSWORD_STATUS="Custom (set)"
        fi
        
        whiptail --title "User Account Setup: Summary" --msgbox "User account configuration summary:\n\nUsername: $USERNAME\nPassword: $PASSWORD_STATUS\nAdministrator Privileges: $SUDO_STATUS" 12 70
        
        return 0
    fi

    # Clear section title
    whiptail --title "$(get_text username_title)" --msgbox "$(get_text username_text)" 12 70

    # Get username
    USERNAME=$(whiptail --inputbox "$(get_text username_prompt)" 10 60 "archuser" --title "$(get_text username_title)" 3>&1 1>&2 2>&3)
    
    if [ $? -eq 0 ]; then
        # Show username confirmation
        whiptail --title "User Account Setup: Username" --msgbox "Username set to: $USERNAME" 8 60

        # Ask for user password with clear instructions
        whiptail --title "User Account Setup: Password" --msgbox "Now you will set a password for user '$USERNAME'.\n\nLeave empty to use the default password 'password'." 10 70
        
        USER_PASSWORD=$(whiptail --passwordbox "Enter password for user $USERNAME:" 10 70 --title "User Account Setup: Password" 3>&1 1>&2 2>&3)
        
        if [ -n "$USER_PASSWORD" ]; then
            # Confirm password with better error handling
            PASSWORD_CONFIRM=$(whiptail --passwordbox "Confirm password for user $USERNAME:" 10 70 --title "User Account Setup: Confirm Password" 3>&1 1>&2 2>&3)
            
            if [ "$USER_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                whiptail --title "User Account Setup: Error" --msgbox "Passwords do not match.\n\nWould you like to try again or use the default password?" 10 60
                
                # Ask if user wants to try again
                if whiptail --title "User Account Setup: Password" --yesno "Try entering password again?" 8 60 3>&1 1>&2 2>&3; then
                    # Try again
                    USER_PASSWORD=$(whiptail --passwordbox "Enter password for user $USERNAME:" 10 70 --title "User Account Setup: Password" 3>&1 1>&2 2>&3)
                    
                    if [ -n "$USER_PASSWORD" ]; then
                        PASSWORD_CONFIRM=$(whiptail --passwordbox "Confirm password for user $USERNAME:" 10 70 --title "User Account Setup: Confirm Password" 3>&1 1>&2 2>&3)
                        
                        if [ "$USER_PASSWORD" != "$PASSWORD_CONFIRM" ]; then
                            whiptail --title "User Account Setup: Error" --msgbox "Passwords still do not match. Using default password 'password'." 8 60
                            USER_PASSWORD=""
                        else
                            whiptail --title "User Account Setup: Success" --msgbox "Password set successfully for user $USERNAME." 8 60
                        fi
                    else
                        whiptail --title "User Account Setup: Note" --msgbox "No password entered. Using default password 'password'." 8 60
                        USER_PASSWORD=""
                    fi
                else
                    # Use default password
                    whiptail --title "User Account Setup: Note" --msgbox "Using default password 'password' for user $USERNAME." 8 60
                    USER_PASSWORD=""
                fi
            else
                # Passwords match
                whiptail --title "User Account Setup: Success" --msgbox "Password set successfully for user $USERNAME." 8 60
            fi
        else
            # No password entered, using default
            whiptail --title "User Account Setup: Note" --msgbox "No password entered. Using default password 'password' for user $USERNAME." 8 60
        fi
        
        # Ask about sudo privileges with more detailed explanation
        whiptail --title "User Account Setup: Administrator Privileges" --yesno "Would you like to grant administrator (sudo) privileges to user $USERNAME?\n\nWith sudo privileges, this user can:\n- Install and remove software\n- Modify system settings\n- Perform administrative tasks\n\nWithout sudo privileges, the user will have limited access." 16 70 3>&1 1>&2 2>&3
        
        if [ $? -eq 0 ]; then
            SUDO_ENABLED=true
            whiptail --title "User Account Setup: Administrator Privileges" --msgbox "Administrator privileges granted to user $USERNAME." 8 70
        else
            SUDO_ENABLED=false
            whiptail --title "User Account Setup: Administrator Privileges" --msgbox "User $USERNAME will have standard (non-administrator) privileges." 8 70
        fi
        
        # Final summary of user configuration
        local SUDO_STATUS="No"
        if [ "$SUDO_ENABLED" = true ]; then
            SUDO_STATUS="Yes"
        fi
        
        local PASSWORD_STATUS="Default ('password')"
        if [ -n "$USER_PASSWORD" ]; then
            PASSWORD_STATUS="Custom (set)"
        fi
        
        whiptail --title "User Account Setup: Summary" --msgbox "User account configuration summary:\n\nUsername: $USERNAME\nPassword: $PASSWORD_STATUS\nAdministrator Privileges: $SUDO_STATUS" 12 70
    fi
    
    return $?
}
get_timezone() {
    TIMEZONE=$(whiptail --inputbox "$(get_text timezone_prompt)" 8 60 "UTC" --title "$(get_text timezone_title)" 3>&1 1>&2 2>&3)
    return $?
}

# Menu functions
select_filesystem() {
    ROOT_FILESYSTEM=$(whiptail --title "$(get_text filesystem_title)" --notags --radiolist \
    "$(get_text filesystem_prompt)" 15 60 4 \
    "ext4" "Extended file system version 4" ON \
    "btrfs" "B-tree file system" OFF \
    "xfs" "XFS high-performance journaling filesystem" OFF \
    "f2fs" "Flash-Friendly File System" OFF 3>&1 1>&2 2>&3)
    
    return $?
}

select_bootloader() {
    # Create a firmware type message to show at the top of the dialog
    local firmware_type_msg
    if [ "$UEFI_MODE" = true ]; then
        firmware_type_msg="Firmware Type: UEFI detected\n\nThe following bootloaders are compatible with your system:"
        
        # In UEFI mode, show all bootloader options
        BOOTLOADER=$(whiptail --title "Bootloader Selection" --notags --radiolist \
        "$firmware_type_msg" 18 70 4 \
        "grub" "GRUB - Universal bootloader with many features" ON \
        "systemd-boot" "systemd-boot - Simple UEFI boot manager" OFF \
        "refind" "rEFInd - Graphical UEFI boot manager" OFF \
        "systemd-boot-efistub" "systemd-boot with direct EFISTUB kernel booting" OFF \
        3>&1 1>&2 2>&3)
    else
        firmware_type_msg='Firmware Type: Legacy BIOS (MBR) detected\n\nOnly GRUB bootloader is compatible with your system.'
        
        # In BIOS mode, only GRUB is available
        BOOTLOADER=$(whiptail --title "Bootloader Selection" --notags --radiolist \
        "$firmware_type_msg" 14 70 1 \
        "grub" "GRUB - Universal bootloader with many features" ON \
        3>&1 1>&2 2>&3)
        
        # If user cancels, we'll still default to GRUB for MBR systems
        if [ $? -ne 0 ]; then
            BOOTLOADER="grub"
        fi
    fi
    
    return $?
}

configure_secure_boot_option() {
    whiptail --title "Secure Boot" --yesno "Enable Secure Boot support?" 8 60 3>&1 1>&2 2>&3
    if [ $? -eq 0 ]; then
        SECURE_BOOT=true
    else
        SECURE_BOOT=false
    fi
    return 0
}

configure_tpm_option() {
    whiptail --title "TPM 2.0" --yesno "Enable TPM 2.0 support?" 8 60 3>&1 1>&2 2>&3
    if [ $? -eq 0 ]; then
        TPM_ENABLED=true
        
        # Ask about PIN protection
        whiptail --title "TPM 2.0 PIN" --yesno "Enable PIN protection for TPM 2.0?" 8 60 3>&1 1>&2 2>&3
        if [ $? -eq 0 ]; then
            TPM_PIN_ENABLED=true
            
            # Get the PIN from the user
            TPM_PIN=$(whiptail --passwordbox "Enter a PIN for TPM 2.0 (numbers only):" 8 60 --title "TPM 2.0 PIN" 3>&1 1>&2 2>&3)
            
            if [ -z "$TPM_PIN" ]; then
                whiptail --title "Warning" --msgbox "No PIN entered. Using TPM 2.0 without PIN protection." 8 60
                TPM_PIN_ENABLED=false
            else
                # Confirm PIN
                PIN_CONFIRM=$(whiptail --passwordbox "Confirm TPM 2.0 PIN:" 8 60 --title "TPM 2.0 PIN Confirmation" 3>&1 1>&2 2>&3)
                
                if [ "$TPM_PIN" != "$PIN_CONFIRM" ]; then
                    whiptail --title "Error" --msgbox "PINs do not match. Using TPM 2.0 without PIN protection." 8 60
                    TPM_PIN_ENABLED=false
                fi
            fi
        else
            TPM_PIN_ENABLED=false
        fi
    else
        TPM_ENABLED=false
        TPM_PIN_ENABLED=false
    fi
    return 0
}

configure_encryption_option() {
    whiptail --title "Disk Encryption" --yesno "Enable LUKS disk encryption?\n\nThis will encrypt the root partition for additional security." 10 60 3>&1 1>&2 2>&3
    if [ $? -eq 0 ]; then
        ENCRYPTION_ENABLED=true
        
        # Select LUKS version
        ENCRYPTION_TYPE=$(whiptail --title "Encryption Type" --notags --radiolist \
        "Choose LUKS encryption version:" 10 60 2 \
        "luks1" "LUKS version 1 (more compatible)" OFF \
        "luks2" "LUKS version 2 (more secure, newer)" ON \
        3>&1 1>&2 2>&3)
        
        # Ask about keyfile for auto-mounting
        whiptail --title "Encryption Keyfile" --yesno "Create a keyfile for auto-mounting the encrypted partition?\n\nWARNING: This reduces security by storing a key on the boot partition!" 12 70 3>&1 1>&2 2>&3
        if [ $? -eq 0 ]; then
            ENCRYPTION_KEYFILE_ENABLED=true
        else
            ENCRYPTION_KEYFILE_ENABLED=false
        fi
        
        # Get encryption password
        get_encryption_password
    else
        ENCRYPTION_ENABLED=false
    fi
    return 0
}
show_summary() {
    TPM_SUMMARY="Disabled"
    if [ "$TPM_ENABLED" = true ]; then
        TPM_SUMMARY="Enabled"
        if [ "$TPM_PIN_ENABLED" = true ]; then
            TPM_SUMMARY="Enabled with PIN protection"
        fi
    fi
    
    # Get UKI summary
    UKI_SUMMARY="Disabled"
    if [ "$UKI_ENABLED" = true ]; then
        UKI_SUMMARY="Enabled"
    fi
    
    # Get audio system summary
    AUDIO_SUMMARY="None"
    if [ "$AUDIO_SYSTEM" = "pipewire" ]; then
        AUDIO_SUMMARY="PipeWire + PulseAudio compatibility"
    elif [ "$AUDIO_SYSTEM" = "pulseaudio" ]; then
        AUDIO_SUMMARY="PulseAudio only"
    fi
    
    # Get encryption summary
    ENCRYPTION_SUMMARY="Disabled"
    if [ "$ENCRYPTION_ENABLED" = true ]; then
        ENCRYPTION_SUMMARY='Enabled ('\"$ENCRYPTION_TYPE\"')'
        if [ "$ENCRYPTION_KEYFILE_ENABLED" = true ]; then
            ENCRYPTION_SUMMARY="$ENCRYPTION_SUMMARY with keyfile"
        fi
    fi
    
    # Get desktop environment summary
    DE_SUMMARY="None (CLI only)"
    if [ -n "$DE_SELECTION" ] && [ "$DE_SELECTION" != "none" ]; then
        case "$DE_SELECTION" in
            "gnome") DE_SUMMARY="GNOME Desktop" ;;
            "kde") DE_SUMMARY="KDE Plasma Desktop" ;;
            "xfce") DE_SUMMARY="XFCE Desktop" ;;
            "mate") DE_SUMMARY="MATE Desktop" ;;
            "cinnamon") DE_SUMMARY="Cinnamon Desktop" ;;
            "lxde") DE_SUMMARY="LXDE Desktop" ;;
            "lxqt") DE_SUMMARY="LXQt Desktop" ;;
            "i3") DE_SUMMARY="i3 Window Manager" ;;
            "sway") DE_SUMMARY="Sway Compositor" ;;
            "awesome") DE_SUMMARY="Awesome Window Manager" ;;
            "dwm") DE_SUMMARY="DWM Window Manager" ;;
            *) DE_SUMMARY="Custom: $DE_SELECTION" ;;
        esac
    fi
    
    # Get package profile summary
    PACKAGE_SUMMARY="Standard"
    if [ -n "$PACKAGE_PROFILE" ]; then
        PACKAGE_SUMMARY="${PACKAGE_PROFILE^}"
    fi
    
    # Get network manager summary
    NETWORK_SUMMARY="NetworkManager"
    if [ -n "$NETWORK_MANAGER" ]; then
        NETWORK_SUMMARY="$NETWORK_MANAGER"
    fi
    
    # Get development tools summary
    DEV_TOOLS_SUMMARY="None"
    if [ ${#DEV_TOOLS[@]} -gt 0 ]; then
        DEV_TOOLS_SUMMARY="Selected (${#DEV_TOOLS[@]} tools)"
    fi
    
    # Get virtualization summary
    VIRTUALIZATION_SUMMARY="None"
    if [ -n "$VIRTUALIZATION" ] && [ "$VIRTUALIZATION" != "none" ]; then
        VIRTUALIZATION_SUMMARY="${VIRTUALIZATION^}"
    fi
    
    # Get user privileges summary
    SUDO_SUMMARY="Yes"
    if [ "$SUDO_ENABLED" != true ]; then
        SUDO_SUMMARY="No"
    fi
    
    # Get password summaries
    USER_PASSWORD_SUMMARY='Default ('\"'\"'password'\"'\"')'
    if [ -n "$USER_PASSWORD" ]; then
        USER_PASSWORD_SUMMARY='Custom (set)'
    fi
    
    HOSTNAME_PASSWORD_SUMMARY='Disabled'
    if [ -n "$HOSTNAME_PASSWORD" ]; then
        HOSTNAME_PASSWORD_SUMMARY='Enabled'
    fi
    
    whiptail --title "Installation Summary" --msgbox "\
The system will be installed with the following configuration:

- Disk: $DISK_DEVICE
- Root Filesystem: $ROOT_FILESYSTEM
- Hostname: $HOSTNAME
- Hostname Protection: $HOSTNAME_PASSWORD_SUMMARY
- Username: $USERNAME
- User Password: $USER_PASSWORD_SUMMARY
- Sudo Privileges: $SUDO_SUMMARY
- Timezone: $TIMEZONE
- Bootloader: $BOOTLOADER
- Secure Boot: $([ "$SECURE_BOOT" = true ] && echo "Enabled" || echo "Disabled")
- TPM 2.0: $TPM_SUMMARY
- Disk Encryption: $ENCRYPTION_SUMMARY
- Unified Kernel Images: $UKI_SUMMARY
- Audio System: $AUDIO_SUMMARY
- Desktop Environment: $DE_SUMMARY
- Package Profile: $PACKAGE_SUMMARY
- Network Manager: $NETWORK_SUMMARY
- Development Tools: $DEV_TOOLS_SUMMARY
- Virtualization: $VIRTUALIZATION_SUMMARY
- Language: $CURRENT_LANG
- System Locale: $LOCALE

Press OK to continue or cancel to abort." 30 70 3>&1 1>&2 2>&3
    
    return $?
}

# The check_uefi function is now defined at the beginning of the script

# Function to display help text for menu options
show_help_text() {
    local option="$1"
    local title="Help: $option"
    local help_text=""
    
    case "$option" in
        "disk")
            help_text="$(get_text help_text_disk)"
            ;;
        "hostname")
            help_text="$(get_text help_text_hostname)"
            ;;
        "username")
            help_text="$(get_text help_text_username)"
            ;;
        "timezone")
            help_text="$(get_text help_text_timezone)"
            ;;
        "filesystem")
            help_text="$(get_text help_text_filesystem)"
            ;;
        "bootloader")
            help_text="$(get_text help_text_bootloader)"
            ;;
        "encryption")
            help_text="$(get_text help_text_encryption)"
            ;;
        "audio")
            help_text="$(get_text help_text_audio)"
            ;;
        "desktop")
            help_text="$(get_text help_text_desktop)"
            ;;
        "package")
            help_text="$(get_text help_text_package)"
            ;;
        "network")
            help_text="$(get_text help_text_network)"
            ;;
        "devtools")
            help_text="$(get_text help_text_devtools)"
            ;;
        "virtualization")
            help_text="$(get_text help_text_virtualization)"
            ;;
        *)
            help_text="No help available for this option."
            ;;
    esac
    
    whiptail --title "$title" --msgbox "$help_text" 16 70
}

# Function to activate and run beginner mode
run_beginner_mode() {
    # Show beginner mode welcome screen
    whiptail --title "$(get_text beginner_mode)" --msgbox "$BEGINNER_LOGO\n\n$(get_text beginner_intro)" 20 78
    
    # Define the total number of installation steps
    local total_steps=8
    local current_step=1
    
    # Step 1: Disk selection
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 1: Disk Selection\n\n$(get_text help_text_disk)" 16 70
    if ! select_disk; then
        whiptail --title "Warning" --msgbox "Disk selection was canceled. Returning to main menu." 8 70
        return 1
    fi
    ((current_step++))
    
    # Step 2: Hostname
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 2: Set Hostname\n\n$(get_text help_text_hostname)" 16 70
    if ! get_hostname; then
        whiptail --title "Warning" --msgbox "Hostname setup was canceled. Returning to main menu." 8 70
        return 1
    fi
    HOSTNAME_CONFIGURED=true
    ((current_step++))
    
    # Step 3: Username and password
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 3: User Account Setup\n\n$(get_text help_text_username)" 16 70
    if ! get_username; then
        whiptail --title "Warning" --msgbox "User account setup was canceled. Returning to main menu." 8 70
        return 1
    fi
    USERNAME_CONFIGURED=true
    ((current_step++))
    
    # Step 4: Timezone
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 4: Set Timezone\n\n$(get_text help_text_timezone)" 16 70
    if ! get_timezone; then
        whiptail --title "Warning" --msgbox "Timezone setup was canceled. Returning to main menu." 8 70
        return 1
    fi
    TIMEZONE_CONFIGURED=true
    ((current_step++))
    
    # Step 5: Filesystem
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 5: Select Filesystem\n\n$(get_text help_text_filesystem)" 16 70
    if ! select_filesystem; then
        whiptail --title "Warning" --msgbox "Filesystem selection was canceled. Returning to main menu." 8 70
        return 1
    fi
    FILESYSTEM_CONFIGURED=true
    ((current_step++))
    
    # Step 6: Bootloader
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 6: Select Bootloader\n\n$(get_text help_text_bootloader)" 16 70
    if ! select_bootloader; then
        whiptail --title "Warning" --msgbox "Bootloader selection was canceled. Returning to main menu." 8 70
        return 1
    fi
    BOOTLOADER_CONFIGURED=true
    ((current_step++))
    
    # Step 7: Audio System
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 7: Select Audio System\n\n$(get_text help_text_audio)" 16 70
    if ! select_audio_system; then
        whiptail --title "Warning" --msgbox "Audio system selection was canceled. Returning to main menu." 8 70
        return 1
    fi
    AUDIO_CONFIGURED=true
    ((current_step++))
    
    # Step 8: Installation Summary
    whiptail --title "$(printf "$(get_text beginner_step)" $current_step $total_steps)" --msgbox "Step 8: Review Installation Summary\n\nPlease review your installation settings before proceeding with the installation." 12 70
    if ! show_summary; then
        whiptail --title "Warning" --msgbox "Summary view was canceled. Returning to main menu." 8 70
        return 1
    fi
    
    # Confirm installation
    if whiptail --title "Start Installation" --yesno "All steps completed! Would you like to start the installation now?" 10 70; then
        start_installation
    else
        whiptail --title "Installation Paused" --msgbox "Installation was not started. You can review or modify settings from the main menu.\n\nWhen ready, select 'Start Installation' from the main menu." 12 70
    fi
    
    return 0
}

main_menu() {
    while true; do
        # Get status indicators for all configurable items
        local disk_status=$(get_status_indicator "$DISK_CONFIGURED")
        local hostname_status=$(get_status_indicator "$HOSTNAME_CONFIGURED")
        local username_status=$(get_status_indicator "$USERNAME_CONFIGURED")
        local timezone_status=$(get_status_indicator "$TIMEZONE_CONFIGURED")
        local filesystem_status=$(get_status_indicator "$FILESYSTEM_CONFIGURED")
        local bootloader_status=$(get_status_indicator "$BOOTLOADER_CONFIGURED")
        local secureboot_status=$(get_status_indicator "$SECUREBOOT_CONFIGURED")
        local tpm_status=$(get_status_indicator "$TPM_CONFIGURED")
        local encryption_status=$(get_status_indicator "$ENCRYPTION_CONFIGURED")
        local uki_status=$(get_status_indicator "$UKI_CONFIGURED")
        local audio_status=$(get_status_indicator "$AUDIO_CONFIGURED")
        local de_status=$(get_status_indicator "$DE_CONFIGURED")
        local package_status=$(get_status_indicator "$PACKAGE_CONFIGURED")
        local network_status=$(get_status_indicator "$NETWORK_CONFIGURED")
        local devtools_status=$(get_status_indicator "$DEV_TOOLS_CONFIGURED")
        local virtualization_status=$(get_status_indicator "$VIRTUALIZATION_CONFIGURED")
        
        # Help indicator for menu options if help text is enabled
        local help_indicator=""
        if [ "$HELP_TEXT_ENABLED" = true ]; then
            help_indicator=" \U0001F4DA"
        fi
        
        # Set beginner mode indicator
        local beginner_mode_indicator=""
        local beginner_mode_text="$(get_text beginner_mode)"
        if [ "$BEGINNER_MODE" = true ]; then
            beginner_mode_indicator="[*]"
            beginner_mode_text="Disable Beginner Mode"
        else
            beginner_mode_indicator="[ ]"
            beginner_mode_text="Enable Beginner Mode"
        fi
        
        # Set help text toggle indicator
        local help_toggle_indicator=""
        if [ "$HELP_TEXT_ENABLED" = true ]; then
            help_toggle_indicator="[*]"
        else
            help_toggle_indicator="[ ]"
        fi

        CHOICE=$(whiptail --title "$(get_text main_menu_title)" --notags --menu "$(get_text select_option)" 32 90 22 \
        "0" "${beginner_mode_indicator} ${beginner_mode_text}${help_indicator}" \
        "1" "${disk_status} $(get_text select_disk)${help_indicator}" \
        "2" "${hostname_status} $(get_text set_hostname)${help_indicator}" \
        "3" "${username_status} $(get_text set_username)${help_indicator}" \
        "4" "${timezone_status} $(get_text set_timezone)${help_indicator}" \
        "5" "${filesystem_status} $(get_text select_fs)${help_indicator}" \
        "11" "${audio_status} $(get_text select_audio)${help_indicator}" \
        "12" "$(get_text select_language)" \
        "h1" "[ SYSTEM OPTIONS ]" \
        "20" "${de_status} $(get_text select_desktop)${help_indicator}" \
        "21" "${package_status} $(get_text select_package)${help_indicator}" \
        "22" "${network_status} $(get_text config_network)${help_indicator}" \
        "h2" "[ BOOT OPTIONS ]" \
        "6" "${bootloader_status} $(get_text select_bootloader)${help_indicator}" \
        "7" "${secureboot_status} $(get_text config_secureboot)${help_indicator}" \
        "8" "${tpm_status} $(get_text config_tpm)${help_indicator}" \
        "9" "${encryption_status} $(get_text config_encryption)${help_indicator}" \
        "10" "${uki_status} $(get_text config_uki)${help_indicator}" \
        "h3" "[ DEVELOPMENT OPTIONS ]" \
        "23" "${devtools_status} $(get_text select_devtools)${help_indicator}" \
        "24" "${virtualization_status} $(get_text config_virtualization)${help_indicator}" \
        "h4" "[ ADVANCED OPTIONS ]" \
        "13" "$(get_text advanced_disk)" \
        "14" "$(get_text show_summary)" \
        "15" "⚡ ${BOLD}$(get_text start_install)${NOBOLD}" \
        "16" "${help_toggle_indicator} Toggle Help Text" \
        "17" "Exit" \
        3>&1 1>&2 2>&3)
        
        if [ $? -ne 0 ]; then
            # User pressed Cancel or Esc
            exit 0
        fi

    case "$CHOICE" in
            h1|h2|h3|h4)
                # Section headers - do nothing
                ;;
            0)
                # Beginner Mode Toggle
                if [ "$BEGINNER_MODE" = true ]; then
                    # If beginner mode is on, toggle it off
                    BEGINNER_MODE=false
                    whiptail --title "Beginner Mode" --msgbox "Beginner Mode has been disabled." 8 70
                else
                    # If beginner mode is off, toggle it on and run beginner mode
                    BEGINNER_MODE=true
                    run_beginner_mode
                fi
                ;;
            1)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for disk selection
                    show_help_text "disk"
                fi
                select_disk
                ;;
            2)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for hostname
                    show_help_text "hostname"
                fi
                get_hostname
                HOSTNAME_CONFIGURED=true
                ;;
            3)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for username
                    show_help_text "username"
                fi
                get_username
                USERNAME_CONFIGURED=true
                ;;
            4)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for timezone
                    show_help_text "timezone"
                fi
                get_timezone
                TIMEZONE_CONFIGURED=true
                ;;
            5)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for filesystem
                    show_help_text "filesystem"
                fi
                select_filesystem
                FILESYSTEM_CONFIGURED=true
                ;;
            6)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for bootloader
                    show_help_text "bootloader"
                fi
                select_bootloader
                BOOTLOADER_CONFIGURED=true
                ;;
            7)
                configure_secure_boot_option
                SECUREBOOT_CONFIGURED=true
                ;;
            8)
                configure_tpm_option
                TPM_CONFIGURED=true
                ;;
            9)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for encryption
                    show_help_text "encryption"
                fi
                configure_encryption_option
                ENCRYPTION_CONFIGURED=true
                ;;
            10)
                configure_uki_option
                UKI_CONFIGURED=true
                ;;
            11)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for audio
                    show_help_text "audio"
                fi
                select_audio_system
                AUDIO_CONFIGURED=true
                ;;
            12)
                select_language
                ;;
            13)
                advanced_disk_management
                ;;
            14)
                show_summary
                ;;
            15)
                start_installation
                ;;
            16)
                # Toggle help text
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    HELP_TEXT_ENABLED=false
                    whiptail --title "Help Text" --msgbox "Help text has been disabled.\n\nYou will no longer see explanations for menu options." 10 60
                else
                    HELP_TEXT_ENABLED=true
                    whiptail --title "Help Text" --msgbox "Help text has been enabled.\n\nYou will now see explanations for available options when selecting menu items." 10 60
                fi
                ;;
            20)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for desktop environment
                    show_help_text "desktop"
                fi
                select_desktop_environment
                ;;
            21)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for package profile
                    show_help_text "package" 
                fi
                select_package_profile
                ;;
            22)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for network configuration
                    show_help_text "network"
                fi
                configure_network
                ;;
            23)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for development tools
                    show_help_text "devtools"
                fi
                select_development_tools
                ;;
            24)
                if [ "$HELP_TEXT_ENABLED" = true ]; then
                    # Show help text for virtualization
                    show_help_text "virtualization"
                fi
                configure_virtualization
                ;;
            17)
                exit 0
                ;;
        esac
    done
}

start_installation() {
    # Check if all required fields are set
    if [ -z "$DISK_DEVICE" ] || [ -z "$HOSTNAME" ] || [ -z "$USERNAME" ] || [ -z "$BOOTLOADER" ]; then
        whiptail --title "Error" --msgbox "Please complete all required configuration items before starting installation." 8 78
        return 1
    fi
    
    # Prepare summary for confirmation
    local de_info="None (CLI only)"
    if [ -n "$DE_SELECTION" ] && [ "$DE_SELECTION" != "none" ]; then
        de_info="$DE_SELECTION"
    fi
    
    local package_info="Standard"
    if [ -n "$PACKAGE_PROFILE" ]; then
        package_info="${PACKAGE_PROFILE^}"
    fi
    
    local network_info="NetworkManager"
    if [ -n "$NETWORK_MANAGER" ]; then
        network_info="$NETWORK_MANAGER"
    fi
    
    local dev_tools_info="None"
    if [ -n "$DEV_TOOLS" ] && [ "$DEV_TOOLS" != "" ]; then
        dev_tools_info="Selected"
    fi
    
    local virt_info="None"
    if [ -n "$VIRTUALIZATION" ] && [ "$VIRTUALIZATION" != "none" ]; then
        virt_info="${VIRTUALIZATION^}"
    fi
    
    # Confirm installation with detailed configuration
    whiptail --title "Confirm Installation" --yesno "Are you sure you want to start the installation?\n\nThis will erase all data on $DISK_DEVICE.\n\nConfiguration Summary:\n- Hostname: $HOSTNAME\n- Username: $USERNAME\n- Desktop Environment: $de_info\n- Package Profile: $package_info\n- Network Manager: $network_info\n- Development Tools: $dev_tools_info\n- Virtualization: $virt_info\n- Bootloader: $BOOTLOADER\n- Filesystem: $FILESYSTEM" 20 78
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    # Start installation process
    {
        echo 10; sleep 1
        partition_disk
        echo 20; sleep 1
        format_partitions
        echo 30; sleep 1
        mount_partitions
        echo 40; sleep 1
        install_base_system
        echo 60; sleep 1
        configure_system
        echo 70; sleep 1
        create_user
        echo 80; sleep 1
        
        # Install selected bootloader
        case $BOOTLOADER in
            grub)
                install_grub
                ;;
            systemd-boot)
                install_systemd_boot
                ;;
            refind)
                install_refind
                ;;
            systemd-boot-efistub)
                install_systemd_boot_efistub
                ;;
        esac
        
        echo 90; sleep 1
        
        # Configure Secure Boot if enabled
        if [ "$SECURE_BOOT" = true ]; then
            configure_secure_boot
        fi
        
        # Configure TPM if enabled
        if [ "$TPM_ENABLED" = true ]; then
            configure_tpm
        fi
        
        echo 100; sleep 1
    } | whiptail --gauge "Installing Arch Linux..." 10 70 0
    
    # Show completion message
    whiptail --title "Installation Complete" --msgbox "Arch Linux has been successfully installed on $DISK_DEVICE.\n\nThe system will now reboot into your new installation." 12 70
    
    # Unmount partitions and reboot
    echo -e "${BLUE}Unmounting partitions...${NC}"
    umount -R /mnt
    swapoff -a

    echo -e "${GREEN}Installation complete!${NC}"
    echo -e "${BLUE}The system will now reboot.${NC}"

    # Ask user to press a key before rebooting
    read -p "Press Enter to reboot..." dummy
    reboot
    
    return 0
}

# Advanced Disk Management functions from disk-menu.sh 
# (with "adv_" prefix to avoid conflicts)

# Function to show error messages
adv_show_error() {
    whiptail --title "Error" --msgbox "$1" 8 78
}

# Function to show success messages
adv_show_success() {
    whiptail --title "Success" --msgbox "$1" 8 78
}

# Function to confirm actions
adv_confirm_action() {
    whiptail --title "Confirm" --yesno "$1" 8 78
    return $?
}

# Function to get a list of available disks
adv_get_disks() {
    # Get disk information and format it for whiptail menu
    lsblk -dp -o NAME,SIZE,MODEL | grep -v loop | grep "^/" | awk '{print $1 " " $2 " " substr($0, index($0,$3))}'
}

# Function to get detailed disk information
adv_get_detailed_disk_info() {
    local disk="$1"
    
    echo "Detailed information for disk: $disk\n"
    echo "================================================================="
    
    # General disk information
    echo "${CYAN}Disk Model:${NC}"
    lsblk -d -o MODEL "$disk" | tail -n 1
    
    echo "\n${CYAN}Disk Size:${NC}"
    lsblk -d -o SIZE "$disk" | tail -n 1
    
    echo -e "\n${CYAN}Disk Type:${NC}"
    disk_info=$(lsblk -d -o TRAN,ROTA "$disk" | tail -n 1)
    tran=$(echo "$disk_info" | awk '{print $1}')
    rota=$(echo "$disk_info" | awk '{print $2}')
    
    if [ -z "$tran" ]; then
        tran="Unknown"
    fi
    
    if [ "$rota" = "1" ]; then
        rotastr="\(HDD\)"
    else
        rotastr="\(SSD\)"
    fi
    
    echo "$tran $rotastr"
    
    # Partition information
    echo "\n${CYAN}Partition Table Type:${NC}"
    parted -s "$disk" print | grep "Partition Table" | cut -d: -f2 | tr -d ' '
    
    echo "\n${CYAN}Partition Layout:${NC}"
    lsblk -p "$disk" -o NAME,SIZE,FSTYPE,LABEL,MOUNTPOINT,UUID | sed 's/^/  /'
    
    # SMART information if available
    if command -v smartctl &> /dev/null; then
        echo "\n${CYAN}SMART Health Status:${NC}"
        smartctl -H "$disk" 2>/dev/null | grep "overall-health" || echo "  SMART not available for this device"
    fi
    
    # Check if disk has RAID
    if command -v mdadm &> /dev/null; then
        echo "\n${CYAN}RAID Information:${NC}"
        mdadm --detail --scan | grep "$disk" || echo "  Not part of a RAID array"
    fi
    
    # Check for encrypted partitions
    echo "\n${CYAN}LUKS Encrypted Partitions:${NC}"
    lsblk -p "$disk" -o NAME,FSTYPE | grep "crypto_LUKS" || echo "  No encrypted partitions found"
    
    echo "================================================================="
}

# Function to get a list of partitions for a disk
adv_get_partitions() {
    local disk="$1"
    lsblk -p "$disk" -o NAME | grep -v "^$disk$" || echo ""
}

# Function to create disk selection menu
adv_select_disk() {
    local disks=$(adv_get_disks)
    local disk_count=$(echo "$disks" | wc -l)
    
    if [[ $disk_count -eq 0 ]]; then
        whiptail --title "Error" --msgbox "No disks found!" 8 78
        return 1
    fi
    
    # Prepare the menu items for whiptail
    local menu_items=()
    local i=1
    
    while read -r line; do
        local disk_name=$(echo "$line" | awk '{print $1}')
        local disk_size=$(echo "$line" | awk '{print $2}')
        local disk_model=$(echo "$line" | awk '{print substr($0, index($0,$3))}')
        menu_items+=("$disk_name" "$disk_size - $disk_model")
        ((i++))
    done < <(echo "$disks")
    
    # Display the menu and get user selection
    local selected_disk=$(whiptail --title "Disk Selection" --menu "Select a disk:" 20 78 $disk_count "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "$selected_disk"
}

# Function to view partitions of a selected disk
adv_view_partitions() {
    local disk=$1
    
    local partitions=$(lsblk -p "$disk" -o NAME,SIZE,FSTYPE,TYPE,MOUNTPOINT,LABEL,UUID)
    
    whiptail --title "Partitions of $disk" --scrolltext --msgbox "$partitions" 20 78
}

# Function to display detailed disk information
adv_view_detailed_disk_info() {
    local disk=$1
    
    local disk_info=$(adv_get_detailed_disk_info "$disk")
    
    whiptail --title "Detailed Information for $disk" --scrolltext --msgbox "$disk_info" 24 80
}

# Function to create a new partition
adv_create_partition() {
    local disk=$1
    
    # Confirm before proceeding
    whiptail --title "Confirm" --yesno "This will launch cfdisk to create partitions on $disk. Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        cfdisk "$disk"
        whiptail --title "Success" --msgbox "Partition creation process completed." 8 78
    fi
}

# Function to delete a partition
adv_delete_partition() {
    local disk=$1
    
    # Get a list of partitions for the selected disk
    local partitions=$(lsblk -p "$disk" -o NAME | grep -v "$disk$")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition to Delete" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm deletion
    whiptail --title "Confirm Deletion" --yesno "WARNING: This will delete the partition $selected_partition and all data on it! Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        # Check if mounted
        local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
        
        if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
            whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
            return
        fi
        
        # Delete partition
        if fdisk "$disk" << EOF
d
$(echo "$selected_partition" | sed "s|$disk||" | tr -d 'p')
w
EOF
        then
            whiptail --title "Success" --msgbox "Partition $selected_partition deleted successfully." 8 78
            # Refresh partition table
            partprobe "$disk"
        else
            whiptail --title "Error" --msgbox "Failed to delete partition $selected_partition." 8 78
        fi
    fi
}

# Function to format a partition
adv_format_partition() {
    local disk=$1
    
    # Get a list of partitions for the selected disk
    local partitions=$(lsblk -p "$disk" -o NAME | grep -v "$disk$")
    
    if [[ -z "$partitions" ]]; then
        whiptail --title "Error" --msgbox "No partitions found on $disk!" 8 78
        return
    fi
    
    # Prepare menu items
    local menu_items=()
    local i=1
    
    while read -r partition; do
        local part_info=$(lsblk -p "$partition" -o SIZE,FSTYPE,MOUNTPOINT,LABEL | tail -n 1)
        menu_items+=("$partition" "$part_info")
        ((i++))
    done < <(echo "$partitions")
    
    # Display menu and get user selection
    local selected_partition=$(whiptail --title "Select Partition to Format" --menu "Select a partition:" 20 78 $i "${menu_items[@]}" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Select filesystem type
    local fs_type=$(whiptail --title "Select Filesystem Type" --notags --menu "Select a filesystem type:" 15 78 6 \
        "ext4" "Extended Filesystem 4" \
        "ext3" "Extended Filesystem 3" \
        "ext2" "Extended Filesystem 2" \
        "btrfs" "B-Tree Filesystem" \
        "xfs" "XFS Filesystem" \
        "f2fs" "Flash-Friendly Filesystem" 3>&1 1>&2 2>&3)
    
    # Return if user cancels
    if [[ $? -ne 0 ]]; then
        return
    fi
    
    # Confirm format
    whiptail --title "Confirm Format" --yesno "WARNING: This will format $selected_partition with $fs_type filesystem and erase ALL data on it! Continue?" 8 78
    
    if [[ $? -eq 0 ]]; then
        # Check if mounted
        local mount_point=$(lsblk -p "$selected_partition" -o MOUNTPOINT | tail -n 1 | tr -d '[:space:]')
        
        if [[ ! -z "$mount_point" && "$mount_point" != "MOUNTPOINT" ]]; then
            whiptail --title "Error" --msgbox "The partition $selected_partition is mounted at $mount_point. Unmount it first." 8 78
            return
        fi
        
        # Format partition based on selected filesystem type
        case "$fs_type" in
            ext4)
                if mkfs.ext4 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext4." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext4." 8 78
                fi
                ;;
            ext3)
                if mkfs.ext3 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext3." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext3." 8 78
                fi
                ;;
            ext2)
                if mkfs.ext2 "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as ext2." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as ext2." 8 78
                fi
                ;;
            btrfs)
                if mkfs.btrfs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as btrfs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as btrfs." 8 78
                fi
                ;;
            xfs)
                if mkfs.xfs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as xfs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as xfs." 8 78
                fi
                ;;
            f2fs)
                if mkfs.f2fs "$selected_partition"; then
                    whiptail --title "Success" --msgbox "Partition $selected_partition formatted as f2fs." 8 78
                else
                    whiptail --title "Error" --msgbox "Failed to format $selected_partition as f2fs." 8 78
                fi
                ;; 
esac
fi
}

# Display welcome screen and perform initial checks
# Parse command line arguments first
parse_args "$@"

# Check root privileges first
check_root

# Show welcome screen before anything else
show_welcome_screen

# Check system requirements
check_uefi
check_internet

# Start the main menu
# Function to handle Advanced Disk Management submenu
advanced_disk_management() {
    while true; do
        local disk=""
        
        # Create submenu for disk management
        local CHOICE=$(whiptail --title "Advanced Disk Management" --notags --menu "Choose an option:" 18 78 8 \
            "1" "View available disks" \
            "2" "View disk partitions" \
            "3" "View detailed disk information" \
            "4" "Create partitions" \
            "5" "Format partitions" \
            "6" "Delete partitions" \
            "0" "Return to main menu" \
            3>&1 1>&2 2>&3)
        
        # Handle user cancellation
        if [ $? -ne 0 ]; then
            return
        fi
        
        case $CHOICE in
            1)
                # View available disks
                local disk_list=$(adv_get_disks)
                whiptail --title "Available Disks" --scrolltext --msgbox "$disk_list" 20 78
                ;;
            2)
                # View disk partitions - first select a disk
                disk=$(adv_select_disk)
                if [ $? -eq 0 ] && [ -n "$disk" ]; then
                    adv_view_partitions "$disk"
                fi
                ;;
            3)
                # View detailed disk information - first select a disk
                disk=$(adv_select_disk)
                if [ $? -eq 0 ] && [ -n "$disk" ]; then
                    adv_view_detailed_disk_info "$disk"
                fi
                ;;
            4)
                # Create partitions - first select a disk
                disk=$(adv_select_disk)
                if [ $? -eq 0 ] && [ -n "$disk" ]; then
                    adv_create_partition "$disk"
                fi
                ;;
            5)
                # Format partitions - first select a disk
                disk=$(adv_select_disk)
                if [ $? -eq 0 ] && [ -n "$disk" ]; then
                    adv_format_partition "$disk"
                fi
                ;;
            6)
                # Delete partitions - first select a disk
                disk=$(adv_select_disk)
                if [ $? -eq 0 ] && [ -n "$disk" ]; then
                    adv_delete_partition "$disk"
                fi
                ;;
            0)
                # Return to main menu
                return
                ;;
        esac
    done
}

main_menu

exit 0


