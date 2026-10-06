#!/usr/bin/env bash
# ==============================================================================
# 🧭 USENET-KOMPASS INSTALLER
# Der umfassende deutsche Leitfaden für automatisierte Usenet-Downloads,
# Medienserver und Heimkino mit Docker Compose.
# Repository: https://github.com/KAiSER086/Usenet-Kompass
# ==============================================================================

set -euo pipefail

# --- CLI Argumente parsen ---
DRY_RUN=false
NON_INTERACTIVE=false
CLI_DOWNLOADER=""
CLI_VPN=""
CLI_VPN_PROVIDER=""
CLI_WG_KEY=""
CLI_WG_IP=""
CLI_OVPN_USER=""
CLI_OVPN_PASS=""
CLI_VPN_COUNTRIES=""
CLI_SUBNET=""
CLI_TAILSCALE=""
CLI_DIR=""
CLI_SKIP_START=false
CLI_SKIP_LINK=false
CLI_SKIP_GUIDE=false

PORT_SABNZBD="8080"
PORT_NZBGET="6789"
PORT_PROWLARR="9696"
PORT_SONARR="8989"
PORT_RADARR="7878"
PORT_JELLYFIN="8096"
PORT_SEERR="5055"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --dry-run|--test|-t)
            DRY_RUN=true
            shift
            ;;
        -y|--yes|--non-interactive)
            NON_INTERACTIVE=true
            shift
            ;;
        --downloader=?*)
            CLI_DOWNLOADER="${1#*=}"
            shift
            ;;
        --downloader)
            CLI_DOWNLOADER="${2:-}"
            shift 2
            ;;
        --vpn=?*)
            CLI_VPN="${1#*=}"
            shift
            ;;
        --vpn)
            CLI_VPN="${2:-}"
            shift 2
            ;;
        --vpn-provider=?*)
            CLI_VPN_PROVIDER="${1#*=}"
            shift
            ;;
        --vpn-provider)
            CLI_VPN_PROVIDER="${2:-}"
            shift 2
            ;;
        --wireguard-key=?*)
            CLI_WG_KEY="${1#*=}"
            shift
            ;;
        --wireguard-key)
            CLI_WG_KEY="${2:-}"
            shift 2
            ;;
        --wireguard-ip=?*)
            CLI_WG_IP="${1#*=}"
            shift
            ;;
        --wireguard-ip)
            CLI_WG_IP="${2:-}"
            shift 2
            ;;
        --openvpn-user=?*)
            CLI_OVPN_USER="${1#*=}"
            shift
            ;;
        --openvpn-user)
            CLI_OVPN_USER="${2:-}"
            shift 2
            ;;
        --openvpn-pass=?*)
            CLI_OVPN_PASS="${1#*=}"
            shift
            ;;
        --openvpn-pass)
            CLI_OVPN_PASS="${2:-}"
            shift 2
            ;;
        --vpn-countries=?*)
            CLI_VPN_COUNTRIES="${1#*=}"
            shift
            ;;
        --vpn-countries)
            CLI_VPN_COUNTRIES="${2:-}"
            shift 2
            ;;
        --subnet=?*)
            CLI_SUBNET="${1#*=}"
            shift
            ;;
        --subnet)
            CLI_SUBNET="${2:-}"
            shift 2
            ;;
        --tailscale=?*)
            val="${1#*=}"
            if [[ "$val" =~ ^(false|0|no)$ ]]; then
                CLI_TAILSCALE=false
            else
                CLI_TAILSCALE=true
            fi
            shift
            ;;
        --tailscale)
            if [ -n "${2:-}" ] && [[ "$2" =~ ^(true|false|1|0|yes|no)$ ]]; then
                if [[ "$2" =~ ^(false|0|no)$ ]]; then
                    CLI_TAILSCALE=false
                else
                    CLI_TAILSCALE=true
                fi
                shift 2
            else
                CLI_TAILSCALE=true
                shift
            fi
            ;;
        --no-tailscale|--without-tailscale)
            CLI_TAILSCALE=false
            shift
            ;;
        --dir=?*)
            CLI_DIR="${1#*=}"
            shift
            ;;
        --dir)
            CLI_DIR="${2:-}"
            shift 2
            ;;
        --skip-start)
            CLI_SKIP_START=true
            shift
            ;;
        --skip-link)
            CLI_SKIP_LINK=true
            shift
            ;;
        --skip-guide)
            CLI_SKIP_GUIDE=true
            shift
            ;;
        --help|-h)
            echo "Verwendung: bash install.sh [OPTIONEN]"
            echo "Optionen:"
            echo "  --dry-run, --test, -t          Führt Syntaxprüfungen und Template-Generierung ohne Container-Start durch."
            echo "  -y, --yes, --non-interactive   Führt die Installation ohne interaktive Prompts mit Standardwerten aus."
            echo "  --downloader <sabnzbd|nzbget>  Wählt den Downloader (SABnzbd oder NZBGet)."
            echo "  --vpn <none|wireguard|openvpn> Netzwerkmodus (Direkt ohne VPN, oder Gluetun mit WireGuard/OpenVPN)."
            echo "  --vpn-provider <mullvad|...>   VPN-Provider (mullvad, protonvpn, surfshark, ivpn, custom)."
            echo "  --wireguard-key <key>          WireGuard Private Key für Gluetun."
            echo "  --wireguard-ip <ip>            Zugewiesene WireGuard-IP (z. B. 10.64.0.1/32)."
            echo "  --openvpn-user <user>          OpenVPN Benutzername."
            echo "  --openvpn-pass <pass>          OpenVPN Passwort."
            echo "  --vpn-countries <countries>    VPN Server-Länder (z. B. 'Netherlands,Germany')."
            echo "  --subnet <cidr>                Lokales Subnetz für Gluetun Firewall Bypass (z. B. 192.168.178.0/24)."
            echo "  --tailscale / --no-tailscale   Tailscale Fernzugriff aktivieren bzw. deaktivieren."
            echo "  --dir <pfad>                   Installationsverzeichnis festlegen."
            echo "  --skip-start                   Erstellt Konfigurationen, startet aber die Docker-Container nicht."
            echo "  --skip-link                    Überspringt das automatische Verknüpfen der Apps (link-apps.sh)."
            echo "  --skip-guide                   Überspringt den abschließenden Frontend-Assistenten."
            echo "  --help, -h                     Zeigt diesen Hilfetext an."
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Benutzereingaben sicherstellen – unterstützt Pipes, Terminals und non-interactive Modus:
read_input() {
    if [ "$DRY_RUN" = true ] || [ "$NON_INTERACTIVE" = true ]; then
        return 0
    elif [ ! -t 0 ]; then
        read -r "$@" || true
    elif (exec < /dev/tty) 2>/dev/null; then
        read -r "$@" < /dev/tty || true
    else
        read -r "$@" || true
    fi
}

read_secret() {
    if [ "$DRY_RUN" = true ] || [ "$NON_INTERACTIVE" = true ]; then
        return 0
    elif [ ! -t 0 ]; then
        read -r -s "$@" || true
    elif (exec < /dev/tty) 2>/dev/null; then
        read -r -s "$@" < /dev/tty || true
    else
        read -r -s "$@" || true
    fi
}

# --- Root- und Sudo-Erkennung ---
SUDO=""
if [ "$DRY_RUN" = true ]; then
    SUDO=""
elif [ "$(id -u)" -ne 0 ]; then
    if command -v sudo &>/dev/null; then
        SUDO="sudo"
    else
        echo -e "\033[0;31mFehler: Dieses Skript benötigt Root-Rechte oder 'sudo'. Bitte als root ausführen oder sudo installieren.\033[0m"
        exit 1
    fi
fi

ORIGINAL_DIR="$(pwd)"

# --- Farben & UI-Elemente ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear 2>/dev/null || true

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "          🧭  W I L L K O M M E N   B E I M                      "
echo "               U S E N E T - K O M P A S S                      "
echo "=================================================================="
echo -e "${NC}"
echo -e "Der automatisierte Docker-Compose Stack für Raspberry Pi 5 & Linux."
echo ""

# ------------------------------------------------------------------------------
# 1.0 VORAUSSETZUNGEN & CHECKLISTE
# ------------------------------------------------------------------------------
echo -e "${YELLOW}${BOLD}⚠️  WICHTIGER HINWEIS VORAB:${NC}"
echo -e "Bevor die Installation startet, stelle bitte sicher, dass du folgende"
echo -e "Zugänge bereitliegen hast:\n"
echo -e "  ${BOLD}1. Einen Usenet-Provider Account${NC} (z. B. Eweka, NewsgroupDirect, etc.)"
echo -e "  ${BOLD}2. Mindestens einen Usenet-Indexer${NC} mit API-Key (z. B. Treasure-Maps, NZBGeek)"
echo -e "  ${BOLD}3. (Optional):${NC} VPN-Account mit WireGuard/OpenVPN (z. B. Mullvad, ProtonVPN)"
echo -e "     ${CYAN}Hinweis:${NC} Der Stack kann auch komplett ${GREEN}ohne VPN${NC} mit direkter SSL/TLS-Verschlüsselung (Port 563) betrieben werden.\n"

if [ "$NON_INTERACTIVE" = true ]; then
    READY_CHOICE="J"
else
    read_input -p "Möchtest du mit der Einrichtung fortfahren? [J/n]: " READY_CHOICE
    READY_CHOICE=${READY_CHOICE:-J}
fi

if [[ ! "$READY_CHOICE" =~ ^[jJyY]$ ]]; then
    echo -e "\n${RED}Installation abgebrochen.${NC}"
    echo "Besorge dir zuerst deine Zugänge und starte den Installer danach erneut."
    echo "Tipps zu Providern und Indexern findest du im Guide: https://github.com/KAiSER086/Usenet-Kompass"
    exit 0
fi

echo -e "\n${GREEN}✓ Super! Lass uns das System einrichten.${NC}\n"

# ------------------------------------------------------------------------------
# 2.0 SYSTEM- & DOCKER-PRÜFUNG
# ------------------------------------------------------------------------------
echo -e "${CYAN}▶ Prüfe Systemvoraussetzungen...${NC}"

# Betriebssystem / Distribution ermitteln
DISTRO_NAME="Linux"
if [ -f /etc/os-release ]; then
    DISTRO_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
fi
[ -z "$DISTRO_NAME" ] && DISTRO_NAME="$(uname -s) ($(uname -m))"

echo -e "${GREEN}✓ Betriebssystem erkannt: ${BOLD}${DISTRO_NAME}${NC}"

# curl sicherstellen (essentiell für get.docker.com & API-Links)
if ! command -v curl &>/dev/null; then
    echo -e "${CYAN}curl ist noch nicht installiert. Installiere curl...${NC}"
    if command -v apt-get &>/dev/null; then
        $SUDO apt-get update -qq && $SUDO apt-get install -y curl ca-certificates || true
    elif command -v pacman &>/dev/null; then
        $SUDO pacman -Sy --noconfirm --overwrite "*" curl ca-certificates || true
    elif command -v dnf &>/dev/null; then
        $SUDO dnf install -y curl ca-certificates || true
    elif command -v zypper &>/dev/null; then
        $SUDO zypper --non-interactive install curl ca-certificates || true
    elif command -v apk &>/dev/null; then
        $SUDO apk add --no-cache curl ca-certificates || true
    fi
fi

# Docker & Compose prüfen
if ! command -v docker &> /dev/null; then
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}[DRY-RUN] Docker ist noch nicht installiert (wird im Testmodus simuliert).${NC}"
    else
        echo -e "${YELLOW}Docker ist noch nicht installiert.${NC}"
        read_input -p "Möchtest du Docker jetzt automatisch offiziell installieren lassen? [J/n]: " INSTALL_DOCKER
        INSTALL_DOCKER=${INSTALL_DOCKER:-J}
        if [[ "$INSTALL_DOCKER" =~ ^[jJyY]$ ]]; then
            echo -e "${CYAN}Installiere Docker für ${DISTRO_NAME}...${NC}"
            if command -v pacman &> /dev/null; then
                echo -e "${CYAN}Arch Linux Familie erkannt: Installiere Docker via pacman...${NC}"
                $SUDO pacman -Sy --noconfirm --overwrite "*" docker docker-compose glibc libseccomp || true
            elif command -v zypper &> /dev/null; then
                echo -e "${CYAN}openSUSE Familie erkannt: Installiere Docker via zypper...${NC}"
                $SUDO zypper --non-interactive install docker docker-compose docker-compose-switch 2>/dev/null || $SUDO zypper --non-interactive install docker docker-compose || true
            elif command -v apk &> /dev/null; then
                echo -e "${CYAN}Alpine Linux erkannt: Installiere Docker via apk...${NC}"
                $SUDO apk add --no-cache docker docker-cli-compose || true
            else
                echo -e "${CYAN}Installiere Docker via offiziellem Docker-Installationsskript...${NC}"
                curl -fsSL https://get.docker.com | sh
            fi
            TARGET_USER="${SUDO_USER:-${USER:-}}"
            if [ -n "$TARGET_USER" ] && [ "$TARGET_USER" != "root" ]; then
                $SUDO usermod -aG docker "$TARGET_USER" 2>/dev/null || true
            fi
            if command -v systemctl &>/dev/null; then
                $SUDO systemctl enable --now docker 2>/dev/null || $SUDO systemctl start docker 2>/dev/null || true
            elif command -v rc-service &>/dev/null; then
                $SUDO rc-service docker start 2>/dev/null || true
                $SUDO rc-update add docker default 2>/dev/null || true
            fi
            echo -e "${GREEN}✓ Docker erfolgreich installiert!${NC}"
        else
            echo -e "${RED}Docker ist erforderlich. Bitte installiere Docker manuell und starte den Installer erneut.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${GREEN}✓ Docker ist vorhanden.${NC}"
fi

# Stelle sicher, dass der Docker-Daemon aktiv ist (im Produktivmodus)
if [ "$DRY_RUN" = false ]; then
    if ! docker ps &>/dev/null && ! $SUDO docker ps &>/dev/null; then
        if command -v systemctl &>/dev/null; then
            $SUDO systemctl enable --now docker 2>/dev/null || $SUDO systemctl start docker 2>/dev/null || true
        elif command -v rc-service &>/dev/null; then
            $SUDO rc-service docker start 2>/dev/null || true
        fi
    fi

    # VPN- & TUN-Kernelmodule laden, falls nicht aktiv (z. B. minimales openSUSE Leap / Debian)
    $SUDO modprobe tun 2>/dev/null || true
    $SUDO modprobe wireguard 2>/dev/null || true
fi

# python3 für automatisierte API-Verknüpfungen (link-apps.sh) sicherstellen
if [ "$DRY_RUN" = false ] && ! command -v python3 &>/dev/null; then
    echo -e "${CYAN}python3 wird für Automatisierungsskripte benötigt. Installiere python3...${NC}"
    if command -v pacman &>/dev/null; then $SUDO pacman -S --noconfirm --overwrite "*" python || true;
    elif command -v zypper &>/dev/null; then $SUDO zypper --non-interactive install python3 || true;
    elif command -v apk &>/dev/null; then $SUDO apk add --no-cache python3 || true;
    elif command -v dnf &>/dev/null; then $SUDO dnf install -y python3 || true;
    elif command -v apt-get &>/dev/null; then $SUDO apt-get update -qq && $SUDO apt-get install -y python3 || true;
    fi
fi

# Compose Plugin prüfen
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Docker Compose ist einsatzbereit.${NC}"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ docker-compose (Legacy) ist einsatzbereit.${NC}"
elif [ "$DRY_RUN" = true ]; then
    COMPOSE_CMD="docker compose"
    echo -e "${YELLOW}[DRY-RUN] Docker Compose nicht gefunden (wird im Testmodus simuliert).${NC}"
else
    echo -e "${YELLOW}Docker Compose Plugin fehlt. Installiere docker-compose-plugin...${NC}"
    if command -v pacman &> /dev/null; then
        $SUDO pacman -Sy --noconfirm --overwrite "*" docker-compose || true
    elif command -v zypper &> /dev/null; then
        $SUDO zypper --non-interactive install docker-compose docker-compose-switch 2>/dev/null || $SUDO zypper --non-interactive install docker-compose || true
    elif command -v apk &> /dev/null; then
        $SUDO apk add --no-cache docker-cli-compose || true
    elif command -v dnf &> /dev/null; then
        $SUDO dnf install -y docker-compose-plugin || true
    elif command -v apt-get &> /dev/null; then
        $SUDO apt-get update -qq && $SUDO apt-get install -y docker-compose-plugin 2>/dev/null || true
    elif command -v apt &> /dev/null; then
        $SUDO apt update && $SUDO apt install -y docker-compose-plugin || true
    fi

    # Universeller Fallback auf offizielles Standalone-Binary falls Paketmanager kein v2 bereitstellt
    if [ "$DRY_RUN" = false ] && ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        ARCH=$(uname -m)
        [ "$ARCH" = "arm64" ] && ARCH="aarch64"
        DOCKER_PLUGIN_DIR="${HOME}/.docker/cli-plugins"
        mkdir -p "$DOCKER_PLUGIN_DIR"
        curl -fsSL "https://github.com/docker/compose/releases/latest/download/docker-compose-linux-${ARCH}" -o "${DOCKER_PLUGIN_DIR}/docker-compose" 2>/dev/null && chmod +x "${DOCKER_PLUGIN_DIR}/docker-compose" || true
    fi

    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        COMPOSE_CMD="docker compose"
    fi
fi

# PUID & PGID ermitteln (LinuxServer.io Container verbieten PUID=0/PGID=0)
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
if [ "$CURRENT_UID" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ]; then
        CURRENT_UID=$(id -u "$SUDO_USER" 2>/dev/null || echo 1000)
        CURRENT_GID=$(id -g "$SUDO_USER" 2>/dev/null || echo 1000)
    else
        CURRENT_UID=1000
        CURRENT_GID=1000
    fi
fi
echo -e "${GREEN}✓ Verwende System-Kennungen: PUID=${CURRENT_UID}, PGID=${CURRENT_GID}${NC}"

# Server-IP für die spätere Anzeige ermitteln
# Server-IP für die spätere Anzeige ermitteln (auch ohne hostname-Paket robust)
SERVER_IP=""
if command -v hostname &>/dev/null; then
    SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || true)
fi
if [ -z "$SERVER_IP" ] && command -v ip &>/dev/null; then
    SERVER_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{print $7}' || true)
    [ -z "$SERVER_IP" ] && SERVER_IP=$(ip -4 addr show scope global 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1 || true)
fi
if [ -z "$SERVER_IP" ] && command -v hostname &>/dev/null; then
    SERVER_IP=$(hostname -i 2>/dev/null | awk '{print $1}' || true)
fi
[ -z "$SERVER_IP" ] && SERVER_IP="localhost" 

# Prüfe Hardwarebeschleunigung (/dev/dri für Intel QuickSync / VAAPI / GPU)
DRI_PRESENT=false
RENDER_GID=""
if [ -d "/dev/dri" ]; then
    DRI_PRESENT=true
    if [ -e /dev/dri/renderD128 ]; then
        RENDER_GID=$(stat -c '%g' /dev/dri/renderD128 2>/dev/null || true)
    fi
    if [ -z "$RENDER_GID" ]; then
        RENDER_GID=$(getent group render 2>/dev/null | cut -d: -f3 || true)
    fi
    if [ -z "$RENDER_GID" ]; then
        RENDER_GID=$(getent group video 2>/dev/null | cut -d: -f3 || true)
    fi
    echo -e "${GREEN}✓ Hardware-Transcoding erkannt (/dev/dri) – GPU-Beschleunigung wird für Jellyfin aktiviert.${NC}"
fi

# ------------------------------------------------------------------------------
# 3.0 DOWNLOADER-AUSWAHL
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}==================================================================${NC}"
echo -e "${BOLD}▶ SCHRITT 1: Welchen Usenet-Downloader möchtest du nutzen?${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo -e "  ${BOLD}[1] SABnzbd${NC} (Moderne UI, intelligentes Caching & volle Gigabit-Power)"
echo -e "      Python mit C-optimierten sabctools (SIMD NEON/AVX2). Erstklassige moderne"
echo -e "      Weboberfläche, Direct Unpack, Auto-PAR2 und intelligentes RAM-Caching."
echo ""
echo -e "  ${BOLD}[2] NZBGet${NC}  (Ressourcen-Leichtgewicht für < 2 GB RAM / sparsame Hardware)"
echo -e "      Kompiliert in nativem C++. Minimaler RAM-Bedarf (~40-60 MB), Direct Unpack, ideal für"
echo -e "      Kleinst-Geräte (z. B. Raspberry Pi 3 oder 1 GB VPS)."
echo ""

if [ -n "$CLI_DOWNLOADER" ]; then
    if [ "$CLI_DOWNLOADER" = "2" ] || [ "$CLI_DOWNLOADER" = "nzbget" ]; then
        DOWNLOADER_CHOICE="2"
    else
        DOWNLOADER_CHOICE="1"
    fi
elif [ "$NON_INTERACTIVE" = true ]; then
    DOWNLOADER_CHOICE="1"
else
    read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " DOWNLOADER_CHOICE
    DOWNLOADER_CHOICE=${DOWNLOADER_CHOICE:-1}
fi

if [ "$DOWNLOADER_CHOICE" = "2" ]; then
    SELECTED_DOWNLOADER="nzbget"
    DOWNLOADER_PORT="6789"
    DOWNLOADER_PORT_VAR="PORT_NZBGET"
    DOWNLOADER_SERVICE_NAME="NZBGet"
else
    SELECTED_DOWNLOADER="sabnzbd"
    DOWNLOADER_PORT="8080"
    DOWNLOADER_PORT_VAR="PORT_SABNZBD"
    DOWNLOADER_SERVICE_NAME="SABnzbd"
fi
echo -e "${GREEN}✓ Ausgewählter Downloader: ${DOWNLOADER_SERVICE_NAME}${NC}"

# ------------------------------------------------------------------------------
# 4.0 NETZWERK- & VPN-KONFIGURATION (MIT ODER OHNE GLUETUN)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}==================================================================${NC}"
echo -e "${BOLD}▶ SCHRITT 2: Möchtest du ein VPN (Gluetun) für Downloader & Indexer nutzen?${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo -e "  ${BOLD}[1] Ohne VPN (Direkte SSL/TLS-Verbindung)${NC}"
echo -e "      Verbindungen zum Usenet-Provider sind über SSL/TLS (Port 563) standardmäßig"
echo -e "      vollständig verschlüsselt. Volle Übertragungsrate ohne CPU-Overhead"
echo -e "      und ohne Notwendigkeit eines kostenpflichtigen VPN-Abonnements."
echo ""
echo -e "  ${BOLD}[2] Mit VPN (Gluetun-Tunneling via WireGuard oder OpenVPN)${NC}"
echo -e "      Leitet Downloader und Indexer über einen VPN-Tunnel. Maskiert deine IP"
echo -e "      zusätzlich gegenüber dem Provider und schützt vor möglichem ISP-Traffic-Shaping."
echo ""

if [ -n "$CLI_VPN" ]; then
    if [ "$CLI_VPN" = "none" ] || [ "$CLI_VPN" = "1" ] || [ "$CLI_VPN" = "no" ] || [ "$CLI_VPN" = "false" ]; then
        VPN_MODE_CHOICE="1"
    else
        VPN_MODE_CHOICE="2"
        if [ "$CLI_VPN" = "openvpn" ] || [ "$CLI_VPN" = "ovpn" ] || [ "$CLI_VPN" = "2" ]; then
            VPN_PROTO_CHOICE="2"
        else
            VPN_PROTO_CHOICE="1"
        fi
    fi
elif [ "$NON_INTERACTIVE" = true ]; then
    VPN_MODE_CHOICE="1"
else
    read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " VPN_MODE_CHOICE
    VPN_MODE_CHOICE=${VPN_MODE_CHOICE:-1}
fi

USE_VPN=false
VPN_TYPE="none"
VPN_PROVIDER="none"
WIREGUARD_PRIVATE_KEY=""
WIREGUARD_ADDRESSES=""
OPENVPN_USER=""
OPENVPN_PASS=""
VPN_COUNTRIES=""
LAN_SUBNET=""

if [ "$VPN_MODE_CHOICE" = "2" ]; then
    USE_VPN=true
    if [ -z "${VPN_PROTO_CHOICE:-}" ]; then
        echo ""
        echo -e "Welches VPN-Protokoll möchtest du nutzen?"
        echo -e "  [1] WireGuard (Direkt im Linux-Kernel integriert, minimaler CPU-Overhead)"
        echo -e "  [2] OpenVPN   (Klassisches Userspace-Protokoll, höhere CPU-Last)"
        read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " VPN_PROTO_CHOICE
        VPN_PROTO_CHOICE=${VPN_PROTO_CHOICE:-1}
    fi

    if [ -n "$CLI_VPN_PROVIDER" ]; then
        VPN_PROVIDER="$CLI_VPN_PROVIDER"
    else
        echo ""
        echo -e "Welchen VPN-Anbieter nutzt du?"
        echo -e "  [1] Mullvad"
        echo -e "  [2] ProtonVPN"
        echo -e "  [3] Surfshark"
        echo -e "  [4] IVPN"
        echo -e "  [5] Anderer / Custom"
        read_input -p "Auswahl [1-5, Standard: 1]: " VPN_PROV_CHOICE
        VPN_PROV_CHOICE=${VPN_PROV_CHOICE:-1}

        case "$VPN_PROV_CHOICE" in
            1) VPN_PROVIDER="mullvad" ;;
            2) VPN_PROVIDER="protonvpn" ;;
            3) VPN_PROVIDER="surfshark" ;;
            4) VPN_PROVIDER="ivpn" ;;
            *) VPN_PROVIDER="custom" ;;
        esac
    fi

    if [ "${VPN_PROTO_CHOICE:-1}" = "2" ] || [ "${VPN_PROTO_CHOICE:-}" = "openvpn" ]; then
        VPN_TYPE="openvpn"
        echo ""
        if [ -n "$CLI_OVPN_USER" ]; then
            OPENVPN_USER="$CLI_OVPN_USER"
        else
            read_input -p "Gib deinen OpenVPN Benutzernamen ein: " OPENVPN_USER
        fi
        if [ -n "$CLI_OVPN_PASS" ]; then
            OPENVPN_PASS="$CLI_OVPN_PASS"
        else
            read_secret -p "Gib dein OpenVPN Passwort ein: " OPENVPN_PASS
        fi
        echo ""
        OPENVPN_USER=${OPENVPN_USER:-"dummy_user"}
        OPENVPN_PASS=${OPENVPN_PASS:-"dummy_pass"}
    else
        VPN_TYPE="wireguard"
        echo ""
        if [ "$DRY_RUN" = true ] && [ -z "$CLI_WG_KEY" ]; then
            WIREGUARD_PRIVATE_KEY="c29tZXJhbmRvbXdpcmVndWFyZHByaXZhdGVrZXkxMjM0NTY="
            WIREGUARD_ADDRESSES="10.64.0.1/32"
        else
            if [ -n "$CLI_WG_KEY" ]; then
                WIREGUARD_PRIVATE_KEY="$CLI_WG_KEY"
            else
                while [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; do
                    read_input -p "Füge deinen WireGuard Private Key ein: " WIREGUARD_PRIVATE_KEY
                    if [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; then
                        if [ "$NON_INTERACTIVE" = true ]; then
                            WIREGUARD_PRIVATE_KEY="c29tZXJhbmRvbXdpcmVndWFyZHByaXZhdGVrZXkxMjM0NTY="
                            break
                        fi
                        echo -e "${YELLOW}⚠️  Der WireGuard Private Key darf nicht leer sein, da Gluetun sonst nicht starten kann.${NC}"
                    fi
                done
            fi
            if [ -n "$CLI_WG_IP" ]; then
                WIREGUARD_ADDRESSES="$CLI_WG_IP"
            else
                read_input -p "Deine zugewiesene WireGuard-IP (z. B. 10.64.0.1/32): " WIREGUARD_ADDRESSES
            fi
            WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES:-"10.64.0.1/32"}
        fi
    fi

    if [ -n "$CLI_VPN_COUNTRIES" ]; then
        VPN_COUNTRIES="$CLI_VPN_COUNTRIES"
    else
        read_input -p "Gewünschte VPN Server-Länder [Standard: Netherlands,Germany]: " VPN_COUNTRIES
    fi
    VPN_COUNTRIES=${VPN_COUNTRIES:-"Netherlands,Germany"}

    # Lokales Heimnetzwerk für Gluetun Firewall ermitteln
    DEFAULT_IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n 1 || true)
    DETECTED_SUBNET=""
    if [ -n "$DEFAULT_IFACE" ]; then
        DETECTED_SUBNET=$(ip route show dev "$DEFAULT_IFACE" 2>/dev/null | grep -v default | grep -E '192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[0-1])\.' | awk '{print $1}' | head -n 1 || true)
    fi
    if [ -z "$DETECTED_SUBNET" ]; then
        DEFAULT_GW=$(ip route show default 2>/dev/null | awk '{print $3}' | head -n 1 || true)
        if [[ "$DEFAULT_GW" =~ ^192\.168\.[0-9]+\. ]]; then
            DETECTED_SUBNET="${DEFAULT_GW%.*}.0/24"
        else
            DETECTED_SUBNET="192.168.178.0/24"
        fi
    fi
    if [ -n "$CLI_SUBNET" ]; then
        CHOSEN_SUBNET="$CLI_SUBNET"
    else
        echo ""
        echo -e "${CYAN}▶ Lokale Heimnetz-Erkennung (Gluetun Firewall Bypass):${NC}"
        echo -e "Erkanntes lokales Subnetz: ${BOLD}${DETECTED_SUBNET}${NC}"
        read_input -p "Lokales Subnetz übernehmen (Enter) oder manuell anpassen: " CUSTOM_SUBNET
        CHOSEN_SUBNET=${CUSTOM_SUBNET:-$DETECTED_SUBNET}
    fi
else
    echo -e "${GREEN}✓ Direktmodus gewählt: Verbindungen laufen ohne VPN direkt über SSL/TLS (Port 563).${NC}"
fi

# ==============================================================================
# SCHRITT 3: Möchtest du Tailscale für sicheren Fernzugriff nutzen?
# ==============================================================================
echo ""
echo -e "${CYAN}=================================================================="
echo -e "▶ SCHRITT 3: Möchtest du Tailscale für sicheren Fernzugriff nutzen?"
echo -e "==================================================================${NC}"
echo -e "  Tailscale ermöglicht den verschlüsselten Zugriff auf Jellyfin, Seerr"
echo -e "  und deinen gesamten Stack von unterwegs (Smartphone, Laptop etc.),"
echo -e "  ganz ohne unsichere Router-Portweiterleitungen einrichten zu müssen."
echo -e "  📖 Dokumentation & DERP-Direct-Play Ratgeber:"
echo -e "  ${CYAN}https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/VPNs.md#43-tailscale-dienst-auf-dem-host-system-hinzuf%C3%BCgen${NC}\n"

TAILSCALE_DETECTED_IP=$(tailscale ip -4 2>/dev/null || true)
WANT_TAILSCALE=false
TAILSCALE_IP=""

if [ "$CLI_TAILSCALE" = true ]; then
    WANT_TAILSCALE=true
    [ -n "$TAILSCALE_DETECTED_IP" ] && TAILSCALE_IP="$TAILSCALE_DETECTED_IP"
elif [ "$CLI_TAILSCALE" = false ]; then
    WANT_TAILSCALE=false
elif [ -n "$TAILSCALE_DETECTED_IP" ]; then
    echo -e "${GREEN}✓ Aktiver Tailscale-Dienst auf diesem System erkannt (IP: ${BOLD}${TAILSCALE_DETECTED_IP}${GREEN}).${NC}"
    read_input -p "Möchtest du Tailscale in diesen Stack einbinden? [J/n]: " TAILSCALE_INPUT
    TAILSCALE_INPUT=${TAILSCALE_INPUT:-J}
    if [[ "$TAILSCALE_INPUT" =~ ^[jJyY]$ ]]; then
        WANT_TAILSCALE=true
        TAILSCALE_IP="$TAILSCALE_DETECTED_IP"
        echo -e "${GREEN}✓ Tailscale wird in den Stack eingebunden.${NC}"
    else
        echo -e "${YELLOW}Tailscale-Einbindung übersprungen.${NC}"
    fi
else
    if [ "$NON_INTERACTIVE" = true ]; then
        TAILSCALE_INPUT="n"
    else
        read_input -p "Möchtest du Tailscale für sicheren Fernzugriff einrichten und einbinden? [J/n]: " TAILSCALE_INPUT
        TAILSCALE_INPUT=${TAILSCALE_INPUT:-J}
    fi
    if [[ "$TAILSCALE_INPUT" =~ ^[jJyY]$ ]]; then
        WANT_TAILSCALE=true
        echo -e "${GREEN}✓ Tailscale wird nach dem Start des Stacks eingerichtet.${NC}"
    else
        echo -e "${YELLOW}Tailscale übersprungen. Du kannst es bei Bedarf jederzeit später einrichten.${NC}"
    fi
fi

# Firewall-Bypass für Gluetun finalisieren: Tailscale nur hinzufügen, wenn gewünscht!
if [ "$USE_VPN" = true ]; then
    LAN_SUBNET="${CHOSEN_SUBNET}"
    if [[ "$LAN_SUBNET" != *"172.16.0.0/12"* ]]; then
        LAN_SUBNET="${LAN_SUBNET},172.16.0.0/12"
    fi
    if [ "$WANT_TAILSCALE" = true ]; then
        if [[ "$LAN_SUBNET" != *"100.64.0.0/10"* ]]; then
            LAN_SUBNET="${LAN_SUBNET},100.64.0.0/10"
        fi
        echo -e "${GREEN}✓ Gluetun Firewall-Bypass gesetzt: Lokales Netz (${CHOSEN_SUBNET}), Docker-Bridge (172.16.0.0/12) & Tailscale (100.64.0.0/10).${NC}"
    else
        echo -e "${GREEN}✓ Gluetun Firewall-Bypass auf lokales Heimnetz (${CHOSEN_SUBNET}) & Docker-Bridge (172.16.0.0/12) gesetzt.${NC}"
    fi
fi

# ==============================================================================
# SCHRITT 4: Installationsverzeichnis festlegen
# ==============================================================================
TARGET_USER="${SUDO_USER:-${USER:-root}}"
TARGET_HOME=$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6 || true)
TARGET_HOME=${TARGET_HOME:-${HOME:-/root}}

IS_TEMP_DRY_RUN_DIR=false
if [ "$DRY_RUN" = true ]; then
    DEFAULT_INSTALL_DIR=$(mktemp -d -t usenet-kompass-dryrun-XXXXXX 2>/dev/null || echo "/tmp/usenet-kompass-dryrun")
    IS_TEMP_DRY_RUN_DIR=true
elif [ -f "$ORIGINAL_DIR/docker-compose.example.yml" ] || [ "$(basename "$ORIGINAL_DIR")" = "Usenet-Kompass" ]; then
    DEFAULT_INSTALL_DIR="$ORIGINAL_DIR"
else
    DEFAULT_INSTALL_DIR="${TARGET_HOME}/usenet-kompass"
fi

echo ""
echo -e "${CYAN}=================================================================="
echo -e "▶ SCHRITT 4: Installationsverzeichnis festlegen"
echo -e "==================================================================${NC}"
echo -e "  In welchem Ordner soll dein Usenet-Stack eingerichtet werden?"
echo -e "  Standard-Pfad: ${BOLD}${DEFAULT_INSTALL_DIR}${NC}"
if [ -n "$CLI_DIR" ]; then
    USER_DIR_INPUT="$CLI_DIR"
elif [ "$NON_INTERACTIVE" = true ]; then
    USER_DIR_INPUT="$DEFAULT_INSTALL_DIR"
else
    read_input -p "Pfad übernehmen (Enter) oder individuellen Pfad eingeben: " USER_DIR_INPUT
fi
INSTALL_DIR="${USER_DIR_INPUT:-$DEFAULT_INSTALL_DIR}"
# Tilde (~) im Pfad expandieren falls vom Nutzer eingegeben
INSTALL_DIR="${INSTALL_DIR/#\~/$TARGET_HOME}"

# Verzeichnis anlegen und absoluten Pfad ermitteln
mkdir -p "$INSTALL_DIR" 2>/dev/null || $SUDO mkdir -p "$INSTALL_DIR"
INSTALL_DIR="$(cd "$INSTALL_DIR" && pwd)"

# Falls link-apps.sh im ursprünglichen Ordner existiert, ins Zielverzeichnis kopieren
if [ -f "$ORIGINAL_DIR/link-apps.sh" ] && [ ! -f "$INSTALL_DIR/link-apps.sh" ]; then
    cp "$ORIGINAL_DIR/link-apps.sh" "$INSTALL_DIR/" 2>/dev/null || true
fi

# In Installationsverzeichnis wechseln
cd "$INSTALL_DIR"
echo -e "${GREEN}✓ Installationsordner gesetzt: ${BOLD}${INSTALL_DIR}${NC}"

# Vorhandene Port-Variablen einlesen, falls bereits eine .env existiert
if [ -f "$INSTALL_DIR/.env" ]; then
    while IFS='=' read -r key val || [ -n "$key" ]; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue
        key=$(echo "$key" | tr -d '[:space:]')
        val=$(echo "$val" | tr -d '[:space:]' | tr -d '"' | tr -d "'")
        case "$key" in
            PORT_SABNZBD) [ -n "$val" ] && PORT_SABNZBD="$val" ;;
            PORT_NZBGET)  [ -n "$val" ] && PORT_NZBGET="$val" ;;
            PORT_PROWLARR) [ -n "$val" ] && PORT_PROWLARR="$val" ;;
            PORT_SONARR)  [ -n "$val" ] && PORT_SONARR="$val" ;;
            PORT_RADARR)  [ -n "$val" ] && PORT_RADARR="$val" ;;
            PORT_JELLYFIN) [ -n "$val" ] && PORT_JELLYFIN="$val" ;;
            PORT_SEERR)   [ -n "$val" ] && PORT_SEERR="$val" ;;
        esac
    done < "$INSTALL_DIR/.env"
fi

if [ "$SELECTED_DOWNLOADER" = "nzbget" ]; then
    ACTIVE_DOWNLOADER_PORT="${PORT_NZBGET}"
else
    ACTIVE_DOWNLOADER_PORT="${PORT_SABNZBD}"
fi

# ------------------------------------------------------------------------------
# 5.0 VERZEICHNISSTRUKTUR ANLEGEN (TRaSH-GUIDES STANDARD)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}▶ Erstelle TRaSH-Guides Verzeichnisstruktur für Instant Atomic Moves...${NC}"

mkdir -p "$INSTALL_DIR/data/usenet/complete/movies"
mkdir -p "$INSTALL_DIR/data/usenet/complete/tv"
mkdir -p "$INSTALL_DIR/data/usenet/incomplete"
mkdir -p "$INSTALL_DIR/data/media/movies"
mkdir -p "$INSTALL_DIR/data/media/tv"

if [ "$USE_VPN" = true ]; then
    mkdir -p "$INSTALL_DIR/config/gluetun"
fi
mkdir -p "$INSTALL_DIR/config/prowlarr"
mkdir -p "$INSTALL_DIR/config/sonarr"
mkdir -p "$INSTALL_DIR/config/radarr"
mkdir -p "$INSTALL_DIR/config/jellyfin"
mkdir -p "$INSTALL_DIR/config/seerr"
# Falls Konfiguration von vorherigem jellyseerr existiert, migriere sie nach seerr
if [ -d "$INSTALL_DIR/config/jellyseerr" ] && [ ! -f "$INSTALL_DIR/config/seerr/db/db.sqlite" ] && [ -f "$INSTALL_DIR/config/jellyseerr/db/db.sqlite" ]; then
    cp -rn "$INSTALL_DIR/config/jellyseerr/"* "$INSTALL_DIR/config/seerr/" 2>/dev/null || true
fi
mkdir -p "$INSTALL_DIR/config/$SELECTED_DOWNLOADER"

# Servarr API-Keys vorab initialisieren (falls noch keine Konfiguration existiert)
generate_servarr_key() {
    if command -v openssl &>/dev/null; then
        openssl rand -hex 16
    else
        head -c 32 /dev/urandom | md5sum | awk '{print $1}'
    fi
}

for app in prowlarr sonarr radarr; do
    if [ ! -f "$INSTALL_DIR/config/$app/config.xml" ]; then
        APP_KEY=$(generate_servarr_key)
        cat <<EOF > "$INSTALL_DIR/config/$app/config.xml"
<Config>
  <ApiKey>${APP_KEY}</ApiKey>
</Config>
EOF
    fi
done

# Falls SELinux aktiv ist (z. B. Fedora, openSUSE Leap 16, RHEL), Container-Berechtigungen setzen
SELINUX_ENFORCING=false
if [ -f /sys/fs/selinux/enforce ] && [ "$(cat /sys/fs/selinux/enforce 2>/dev/null)" = "1" ]; then
    SELINUX_ENFORCING=true
elif command -v getenforce &> /dev/null && [ "$(getenforce 2>/dev/null)" = "Enforcing" ]; then
    SELINUX_ENFORCING=true
elif [ -x /usr/sbin/getenforce ] && [ "$(/usr/sbin/getenforce 2>/dev/null)" = "Enforcing" ]; then
    SELINUX_ENFORCING=true
fi

if [ "$SELINUX_ENFORCING" = true ]; then
    echo -e "${CYAN}SELinux (Enforcing) erkannt: Setze Dateiberechtigungen für Container-Volumes...${NC}"
    chcon -Rt container_file_t "$INSTALL_DIR/config" "$INSTALL_DIR/data" 2>/dev/null || $SUDO chcon -Rt container_file_t "$INSTALL_DIR/config" "$INSTALL_DIR/data" 2>/dev/null || true
fi

# Berechtigungen sicherstellen
chmod -R 755 "$INSTALL_DIR/data" || true
echo -e "${GREEN}✓ Ordnerstruktur erfolgreich unter $INSTALL_DIR/data angelegt.${NC}"

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# 6.0 .ENV & DOCKER-COMPOSE.YML GENERIEREN
# ------------------------------------------------------------------------------
echo -e "${CYAN}▶ Generiere maßgeschneiderte .env und docker-compose.yml...${NC}"

# 6.1 .env-Datei generieren
cat <<EOF > "$INSTALL_DIR/.env"
# ==============================================================================
# 🧭 USENET-KOMPASS - UMGEBUNGSVARIABLEN (.env)
# Automatisch generiert durch install.sh
# ==============================================================================

PUID=${CURRENT_UID}
PGID=${CURRENT_GID}
TZ=Europe/Berlin
CONFIG_DIR=./config
DATA_DIR=./data

# --- WebUI & Port-Konfiguration ---
PORT_SABNZBD=${PORT_SABNZBD}
PORT_NZBGET=${PORT_NZBGET}
PORT_PROWLARR=${PORT_PROWLARR}
PORT_SONARR=${PORT_SONARR}
PORT_RADARR=${PORT_RADARR}
PORT_JELLYFIN=${PORT_JELLYFIN}
PORT_SEERR=${PORT_SEERR}
EOF

if [ "$USE_VPN" = true ]; then
cat <<EOF >> "$INSTALL_DIR/.env"

# --- VPN Konfiguration (Gluetun) ---
VPN_SERVICE_PROVIDER=${VPN_PROVIDER}
VPN_TYPE=${VPN_TYPE}
EOF

if [ "$VPN_TYPE" = "wireguard" ]; then
cat <<EOF >> "$INSTALL_DIR/.env"
WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
EOF
else
cat <<EOF >> "$INSTALL_DIR/.env"
OPENVPN_USER=${OPENVPN_USER}
OPENVPN_PASSWORD=${OPENVPN_PASS}
EOF
fi

cat <<EOF >> "$INSTALL_DIR/.env"
SERVER_COUNTRIES=${VPN_COUNTRIES}
FIREWALL_OUTBOUND_SUBNETS=${LAN_SUBNET}
EOF
fi

chmod 600 "$INSTALL_DIR/.env" || true
echo -e "${GREEN}✓ .env erfolgreich mit restriktiven Rechten (chmod 600) erstellt.${NC}"

# 6.2 docker-compose.yml generieren
if [ "$USE_VPN" = true ]; then
cat <<EOF > "$INSTALL_DIR/docker-compose.yml"
# Wiederverwendbarer Logging-Block gegen unbegrenzt volllaufende Festplatten
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    <<: *default-logging
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=\${VPN_SERVICE_PROVIDER}
      - VPN_TYPE=\${VPN_TYPE}
EOF

if [ "$VPN_TYPE" = "wireguard" ]; then
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - WIREGUARD_PRIVATE_KEY=\${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=\${WIREGUARD_ADDRESSES}
EOF
else
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - OPENVPN_USER=\${OPENVPN_USER}
      - OPENVPN_PASSWORD=\${OPENVPN_PASSWORD}
EOF
fi

cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - SERVER_COUNTRIES=\${SERVER_COUNTRIES}
      - FIREWALL_OUTBOUND_SUBNETS=\${FIREWALL_OUTBOUND_SUBNETS}
      - TZ=\${TZ}
      - PUID=\${PUID}
      - PGID=\${PGID}
    ports:
      - "\${${DOWNLOADER_PORT_VAR}}:${DOWNLOADER_PORT}" # Downloader (${DOWNLOADER_SERVICE_NAME}) WebUI
      - "\${PORT_RADARR}:7878" # Radarr WebUI & API
      - "\${PORT_SONARR}:8989" # Sonarr WebUI & API
      - "\${PORT_PROWLARR}:9696" # Prowlarr WebUI & API
    volumes:
      - \${CONFIG_DIR}/gluetun:/gluetun
    restart: unless-stopped

  # --- Downloader: ${DOWNLOADER_SERVICE_NAME} ---
  ${SELECTED_DOWNLOADER}:
    image: lscr.io/linuxserver/${SELECTED_DOWNLOADER}:latest
    container_name: ${SELECTED_DOWNLOADER}
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/${SELECTED_DOWNLOADER}:/config
      - \${DATA_DIR}:/data
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"

  # --- Arr-Stack (Automation & Indexer) ---
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/prowlarr:/config
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/sonarr:/config
      - \${DATA_DIR}:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/radarr:/config
      - \${DATA_DIR}:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped
EOF

else
# OHNE VPN (DIREKT-MODUS)
cat <<EOF > "$INSTALL_DIR/docker-compose.yml"
# Wiederverwendbarer Logging-Block gegen unbegrenzt volllaufende Festplatten
x-logging: &default-logging
  logging:
    driver: "json-file"
    options:
      max-size: "10m"
      max-file: "3"

services:
  # --- Downloader: ${DOWNLOADER_SERVICE_NAME} ---
  ${SELECTED_DOWNLOADER}:
    image: lscr.io/linuxserver/${SELECTED_DOWNLOADER}:latest
    container_name: ${SELECTED_DOWNLOADER}
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/${SELECTED_DOWNLOADER}:/config
      - \${DATA_DIR}:/data
    ports:
      - "\${${DOWNLOADER_PORT_VAR}}:${DOWNLOADER_PORT}"
    restart: unless-stopped

  # --- Arr-Stack (Automation & Indexer) ---
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/prowlarr:/config
    ports:
      - "\${PORT_PROWLARR}:9696"
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/sonarr:/config
      - \${DATA_DIR}:/data
    ports:
      - "\${PORT_SONARR}:8989"
    depends_on:
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/radarr:/config
      - \${DATA_DIR}:/data
    ports:
      - "\${PORT_RADARR}:7878"
    depends_on:
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped
EOF
fi

cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"

  # --- Frontend (Medienserver & Anfragen) ---
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    <<: *default-logging
    environment:
      - PUID=\${PUID}
      - PGID=\${PGID}
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/jellyfin:/config
      - \${DATA_DIR}/media:/data/media
    ports:
      - "\${PORT_JELLYFIN}:8096"
    restart: unless-stopped
EOF

if [ "$DRI_PRESENT" = true ]; then
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
    devices:
      - /dev/dri:/dev/dri
EOF
if [ -n "$RENDER_GID" ]; then
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
    group_add:
      - "${RENDER_GID}"
EOF
fi
fi

cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"

  seerr:
    image: ghcr.io/seerr-team/seerr:latest
    container_name: seerr
    <<: *default-logging
    init: true
    environment:
      - TZ=\${TZ}
    volumes:
      - \${CONFIG_DIR}/seerr:/app/config
    ports:
      - "\${PORT_SEERR}:5055"
    depends_on:
      - radarr
      - sonarr
EOF

if [ "$USE_VPN" = true ]; then
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - gluetun
EOF
fi

cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
    restart: unless-stopped
EOF

echo -e "${GREEN}✓ .env und docker-compose.yml wurden erfolgreich erstellt!${NC}\n"

if [ "$DRY_RUN" = true ]; then
    echo -e "${CYAN}==================================================================${NC}"
    echo -e "${GREEN}${BOLD}✓ [DRY-RUN] Validierung & Konfigurations-Generierung erfolgreich!${NC}"
    echo -e "${CYAN}==================================================================${NC}"
    if command -v docker &>/dev/null && docker compose version &>/dev/null; then
        if docker compose config -q 2>/dev/null; then
            echo -e "  ${GREEN}✓ .env & docker-compose.yml sind syntaktisch 100% valide (geprüft via 'docker compose config').${NC}"
        else
            echo -e "  ${RED}✗ Fehler bei Validierung von docker-compose.yml via 'docker compose config'.${NC}"
            docker compose config || true
            exit 1
        fi
    else
        echo -e "  ${GREEN}✓ docker-compose.yml erfolgreich generiert.${NC}"
    fi
    echo -e "  ${GREEN}✓ TRaSH-Guides Verzeichnisstruktur (/data, /config) erfolgreich vorbereitet.${NC}"
    echo -e "  ${GREEN}✓ API-Keys für Prowlarr, Sonarr & Radarr vorkonfiguriert.${NC}"
    echo -e "${CYAN}==================================================================${NC}\n"
    if [ "$IS_TEMP_DRY_RUN_DIR" = true ] && [ -d "$INSTALL_DIR" ]; then
        cd "$ORIGINAL_DIR" 2>/dev/null || true
        rm -rf "$INSTALL_DIR" 2>/dev/null || true
    fi
    exit 0
fi

# ------------------------------------------------------------------------------
# 7.0 STARTEN DES STACKS
# ------------------------------------------------------------------------------
# Prüfe, ob Docker-Befehle ohne sudo ausgeführt werden können (z. B. direkt nach Neuinstallation)
RUN_DOCKER_CMD="$COMPOSE_CMD"
DOCKER_BIN="docker"
if ! docker ps &>/dev/null; then
    if [ -n "$SUDO" ] && $SUDO docker ps &>/dev/null; then
        RUN_DOCKER_CMD="$SUDO $COMPOSE_CMD"
        DOCKER_BIN="$SUDO docker"
    fi
fi

# Prüfe vorab auf Namenskonflikte mit bestehenden Containern
CONFLICTING_CONTAINERS=$($DOCKER_BIN ps -a --format '{{.Names}}' 2>/dev/null | grep -E "^(gluetun|sonarr|radarr|prowlarr|jellyfin|seerr|jellyseerr|${SELECTED_DOWNLOADER})$" || true)

START_NOW="J"
if [ "$CLI_SKIP_START" = true ]; then
    START_NOW="n"
elif [ -n "$CONFLICTING_CONTAINERS" ]; then
    echo -e "${YELLOW}⚠️  ACHTUNG: Auf diesem System existieren bereits Container mit identischen Namen:${NC}"
    echo -e "${BOLD}${CONFLICTING_CONTAINERS}${NC}"
    if [ "$NON_INTERACTIVE" = true ]; then
        REMOVE_CONFLICTS="N"
    else
        read_input -p "Möchtest du diese bestehenden Container stoppen und entfernen, um den neuen Stack zu starten? [j/N]: " REMOVE_CONFLICTS
    fi
    REMOVE_CONFLICTS=${REMOVE_CONFLICTS:-N}
    if [[ "$REMOVE_CONFLICTS" =~ ^[jJyY]$ ]]; then
        echo -e "${CYAN}Stoppe und entferne kollidierende Container...${NC}"
        echo "$CONFLICTING_CONTAINERS" | while read -r cname; do
            [ -n "$cname" ] && $DOCKER_BIN rm -f "$cname" >/dev/null 2>&1 || true
        done
    else
        echo -e "\n${YELLOW}Hinweis: Die neue docker-compose.yml wurde erstellt, wird aber wegen der bestehenden Container nicht gestartet.${NC}"
        START_NOW="n"
    fi
fi

if [ "$START_NOW" != "n" ]; then
    if [ "$NON_INTERACTIVE" = true ]; then
        START_NOW="J"
    else
        read_input -p "Möchtest du den Stack jetzt direkt im Hintergrund starten? [J/n]: " START_NOW
        START_NOW=${START_NOW:-J}
    fi
fi

if [[ "$START_NOW" =~ ^[jJyY]$ ]]; then
    # Berechtigungen vor dem Containerstart an den Zielbenutzer übergeben
    if [[ "$RUN_DOCKER_CMD" == *"sudo"* ]] || [ "$(id -u)" -eq 0 ]; then
        $SUDO chown -R "${CURRENT_UID}:${CURRENT_GID}" "$INSTALL_DIR" 2>/dev/null || true
    fi
    echo -e "${CYAN}Starte Docker Stack via '$RUN_DOCKER_CMD up -d'...${NC}"
    $RUN_DOCKER_CMD up -d
    echo -e "\n${GREEN}${BOLD}🎉 HERZLICHEN GLÜCKWUNSCH! DEIN STACK LÄUFT!${NC}\n"

    # --- 7.1 STATUS-CHECK (VPN-LEAK-TEST ODER DIREKT-MODUS) ---
    if [ "$USE_VPN" = true ]; then
        echo -e "${CYAN}⏳ Warte kurz auf VPN-Tunnelverbindung für den Sicherheits-Check...${NC}"
        VPN_JSON=""
        for _ in {1..10}; do
            VPN_JSON=$($DOCKER_BIN exec gluetun wget -qO- --timeout=5 https://ipinfo.io/json 2>/dev/null || true)
            if [[ "$VPN_JSON" == *"\"ip\":"* ]]; then
                break
            fi
            sleep 2
        done

        if [[ "$VPN_JSON" == *"\"ip\":"* ]]; then
            VPN_IP=$(echo "$VPN_JSON" | grep -oPm1 '(?<="ip": ")[^"]+' 2>/dev/null || echo "$VPN_JSON" | sed -n 's/.*"ip": "\([^"]*\)".*/\1/p' 2>/dev/null || true)
            VPN_CITY=$(echo "$VPN_JSON" | grep -oPm1 '(?<="city": ")[^"]+' 2>/dev/null || echo "$VPN_JSON" | sed -n 's/.*"city": "\([^"]*\)".*/\1/p' 2>/dev/null || true)
            VPN_COUNTRY=$(echo "$VPN_JSON" | grep -oPm1 '(?<="country": ")[^"]+' 2>/dev/null || echo "$VPN_JSON" | sed -n 's/.*"country": "\([^"]*\)".*/\1/p' 2>/dev/null || true)
            VPN_ORG=$(echo "$VPN_JSON" | grep -oPm1 '(?<="org": ")[^"]+' 2>/dev/null || echo "$VPN_JSON" | sed -n 's/.*"org": "\([^"]*\)".*/\1/p' 2>/dev/null || true)

            echo -e "${GREEN}=================================================================="
            echo -e "          🔒  VPN-LEAK-TEST: ERFOLGREICH BESTANDEN!               "
            echo -e "==================================================================${NC}"
            echo -e "  ${BOLD}Öffentliche VPN-IP:${NC}  ${GREEN}${BOLD}${VPN_IP}${NC}"
            echo -e "  ${BOLD}Server-Standort:${NC}     ${VPN_CITY} (${VPN_COUNTRY})"
            echo -e "  ${BOLD}Provider / ISP:${NC}      ${VPN_ORG}"
            echo -e "  ${GREEN}✓ Deine echte Internet-IP ist zu 100% maskiert und geschützt.${NC}\n"
        else
            echo -e "${YELLOW}ℹ️  VPN-Tunnel baut sich noch im Hintergrund auf (Handshake läuft).${NC}\n"
        fi
    else
        echo -e "${GREEN}=================================================================="
        echo -e "          ⚡  DIREKT-MODUS AKTIV (SSL/TLS VERSCHLÜSSELT)           "
        echo -e "==================================================================${NC}"
        echo -e "  ${BOLD}Verschlüsselung:${NC}     Ende-zu-Ende via SSL/TLS (Port 563)"
        echo -e "  ${BOLD}Netzwerkmodus:${NC}       Native Leitungsgeschwindigkeit ohne VPN-Tunnel"
        echo -e "  ${GREEN}✓ Downloads sind gegenüber deinem ISP und Dritten vollkommen verschlüsselt.${NC}\n"
    fi

    # --- 7.2 AUTOMATISCHES APP-LINKING ANBIETEN ---
    echo -e "${CYAN}------------------------------------------------------------------${NC}"
    echo -e "${BOLD}▶ Möchtest du die Medien-Apps jetzt vollautomatisch verknüpfen?${NC}"
    echo -e "  Verbindet Prowlarr ↔ Sonarr ↔ Radarr ↔ ${DOWNLOADER_SERVICE_NAME}"
    echo -e "  und richtet die Root-Folder (/data/media) automatisch ein."
    if [ "$CLI_SKIP_LINK" = true ]; then
        RUN_LINK="n"
    elif [ "$NON_INTERACTIVE" = true ]; then
        RUN_LINK="J"
    else
        read_input -p "Apps jetzt automatisch verknüpfen? [J/n]: " RUN_LINK
        RUN_LINK=${RUN_LINK:-J}
    fi
    if [[ "$RUN_LINK" =~ ^[jJyY]$ ]]; then
        if [ -f "$INSTALL_DIR/link-apps.sh" ]; then
            chmod +x "$INSTALL_DIR/link-apps.sh"
            bash "$INSTALL_DIR/link-apps.sh" "$INSTALL_DIR" || true
        else
            curl -fsSL "https://raw.githubusercontent.com/KAiSER086/Usenet-Kompass/main/link-apps.sh" -o "$INSTALL_DIR/link-apps.sh" 2>/dev/null || true
            chmod +x "$INSTALL_DIR/link-apps.sh" 2>/dev/null || true
            if [ -f "$INSTALL_DIR/link-apps.sh" ]; then
                bash "$INSTALL_DIR/link-apps.sh" "$INSTALL_DIR" || true
            fi
        fi
    else
        echo -e "${YELLOW}Du kannst die Apps jederzeit später verknüpfen mit: ${BOLD}cd $INSTALL_DIR && ./link-apps.sh${NC}\n"
    fi
else
    echo -e "\n${YELLOW}Alles vorbereitet! Starte den Stack später mit: ${BOLD}cd $INSTALL_DIR && $RUN_DOCKER_CMD up -d${NC}\n"
fi

# ------------------------------------------------------------------------------
# 7.3 OPTIONALER FERNZUGRIFF MIT TAILSCALE
# ------------------------------------------------------------------------------
if [ "$WANT_TAILSCALE" = true ] && [ "$CLI_SKIP_START" = false ]; then
    if [ -z "$TAILSCALE_IP" ]; then
        echo -e "${CYAN}------------------------------------------------------------------${NC}"
        echo -e "${BOLD}▶ Richte Tailscale für sicheren Fernzugriff ein...${NC}"
        if ! command -v tailscale &>/dev/null; then
            echo -e "${CYAN}Installiere Tailscale...${NC}"
            curl -fsSL https://tailscale.com/install.sh | $SUDO sh
        else
            echo -e "${GREEN}✓ Tailscale ist bereits auf diesem System installiert.${NC}"
        fi

        echo -e "${CYAN}Starte Tailscale-Dienst und Authentifizierung...${NC}"
        echo -e "${YELLOW}ℹ️  Öffne den angezeigten Login-Link in deinem Browser:${NC}"
        $SUDO tailscale up || true
        TAILSCALE_IP=$(tailscale ip -4 2>/dev/null || true)
        if [ -n "$TAILSCALE_IP" ]; then
            echo -e "\n${GREEN}✓ Tailscale erfolgreich verbunden! Deine Tailscale-IP: ${BOLD}${TAILSCALE_IP}${NC}\n"
        fi
    else
        echo -e "\n${GREEN}✓ Tailscale ist aktiv und verbunden! (IP: ${BOLD}${TAILSCALE_IP}${GREEN})${NC}\n"
    fi
fi

# ------------------------------------------------------------------------------
# 8.0 ÜBERSICHT DER WEB-INTERFACES
# ------------------------------------------------------------------------------
echo -e "${CYAN}=================================================================="
echo -e "                   DEINE WEB-INTERFACES                           "
echo -e "==================================================================${NC}"
echo -e "📁 ${BOLD}Installationsordner:${NC}            ${INSTALL_DIR}"
echo -e "🍿 ${BOLD}Seerr (Medien-Anfragen):${NC}         http://${SERVER_IP}:${PORT_SEERR}"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:${PORT_SEERR}"
fi
echo -e "🎬 ${BOLD}Jellyfin (Medienserver):${NC}         http://${SERVER_IP}:${PORT_JELLYFIN}"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:${PORT_JELLYFIN}"
fi
echo -e "⚡ ${BOLD}${DOWNLOADER_SERVICE_NAME} (Downloader):${NC}         http://${SERVER_IP}:${ACTIVE_DOWNLOADER_PORT}"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:${ACTIVE_DOWNLOADER_PORT}"
fi
echo -e "📺 ${BOLD}Sonarr (Serien-Manager):${NC}         http://${SERVER_IP}:${PORT_SONARR}"
echo -e "🎬 ${BOLD}Radarr (Film-Manager):${NC}           http://${SERVER_IP}:${PORT_RADARR}"
echo -e "🔍 ${BOLD}Prowlarr (Indexer-Hub):${NC}          http://${SERVER_IP}:${PORT_PROWLARR}"
echo -e "${CYAN}=================================================================="
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "${YELLOW}⚡ Performance-Tipp für Jellyfin via Tailscale:${NC}"
    echo -e "   Leite im Heim-Router UDP-Port 41641 an diesen Server weiter, um gedrosselte"
    echo -e "   DERP-Relays zu umgehen und maximale Videoqualität (Direct Play) zu erzielen."
    echo -e "   Details: ${CYAN}https://github.com/KAiSER086/Usenet-Kompass/blob/main/Docker%20Compose%20Stack/VPNs.md#43-tailscale-dienst-auf-dem-host-system-hinzuf%C3%BCgen${NC}\n"
fi
echo -e "📌 Nächste Schritte: Richte deinen Indexer in Prowlarr ein und hinterlege"
echo -e "   deinen Provider in ${DOWNLOADER_SERVICE_NAME}."
echo -e "   Vollständige Anleitung: ${BOLD}https://github.com/KAiSER086/Usenet-Kompass${NC}\n"

# ------------------------------------------------------------------------------
# 9.0 INTERAKTIVE SCHRITT-FÜR-SCHRITT ANLEITUNG (JELLYFIN & SEERR)
# ------------------------------------------------------------------------------
if [ "$CLI_SKIP_START" = false ] && [ "$CLI_SKIP_GUIDE" = false ] && [ "$NON_INTERACTIVE" = false ]; then
    echo -e "${CYAN}------------------------------------------------------------------${NC}"
    echo -e "${BOLD}▶ Möchtest du jetzt den Schritt-für-Schritt Einrichtungsassistenten"
    echo -e "  für Jellyfin & Seerr starten?${NC}"
    read_input -p "Ersteinrichtung jetzt Schritt für Schritt durchgehen? [J/n]: " RUN_FRONTEND_GUIDE
    RUN_FRONTEND_GUIDE=${RUN_FRONTEND_GUIDE:-J}
else
    RUN_FRONTEND_GUIDE="n"
fi

if [[ "$RUN_FRONTEND_GUIDE" =~ ^[jJyY]$ ]]; then
    # API-Keys für Seerr aus den Configs auslesen
    RADARR_API_KEY=$(grep -oPm1 '(?<=<ApiKey>)[^<]+' "$INSTALL_DIR/config/radarr/config.xml" 2>/dev/null || sed -n 's/.*<ApiKey>\([^<]*\)<\/ApiKey>.*/\1/p' "$INSTALL_DIR/config/radarr/config.xml" 2>/dev/null || echo "siehe config/radarr/config.xml")
    SONARR_API_KEY=$(grep -oPm1 '(?<=<ApiKey>)[^<]+' "$INSTALL_DIR/config/sonarr/config.xml" 2>/dev/null || sed -n 's/.*<ApiKey>\([^<]*\)<\/ApiKey>.*/\1/p' "$INSTALL_DIR/config/sonarr/config.xml" 2>/dev/null || echo "siehe config/sonarr/config.xml")

    # Host-Erklärung je nach gewähltem Netzwerkmodus
    if [ "$USE_VPN" = true ]; then
        HOST_EXPLANATION="Da Sonarr und Radarr über das VPN-Netzwerk von Gluetun laufen, erreichst du sie containerintern über den Hostnamen 'gluetun'."
    else
        HOST_EXPLANATION="Da die Dienste im direkten Bridge-Netzwerk laufen, erreichst du sie containerintern über ihre direkten Dienstnamen 'radarr' bzw. 'sonarr'."
    fi

    # --- SCHRITT 1: JELLYFIN ---
    echo -e "\n${CYAN}=================================================================="
    echo -e "       🎬 Schritt 1 / 3: Jellyfin Medienserver einrichten        "
    echo -e "==================================================================${NC}"
    if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:${PORT_JELLYFIN}${NC} (oder via Tailscale: ${BOLD}http://${TAILSCALE_IP}:${PORT_JELLYFIN}${NC})"
    else
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:${PORT_JELLYFIN}${NC}"
    fi
    echo -e "2. Wähle die Sprache und erstelle dein ${BOLD}Admin-Benutzerkonto${NC}."
    echo -e "3. Füge deine zwei Mediatheken hinzu:"
    echo -e "   • ${BOLD}Filme:${NC}  Wähle den Ordner ${GREEN}/data/media/movies${NC}"
    echo -e "   • ${BOLD}Serien:${NC} Wähle den Ordner ${GREEN}/data/media/tv${NC}"
    echo -e "4. Schließe den Assistenten ab. (Jellyfin ist nun einsatzbereit!)\n"

    read_input -p "Drücke [Enter], wenn Jellyfin eingerichtet ist, um zu Schritt 2 (Seerr) zu wechseln... " _

    # --- SCHRITT 2: SEERR INITIALISIEREN ---
    echo -e "\n${CYAN}=================================================================="
    echo -e "       🍿 Schritt 2 / 3: Seerr Anfrage-Portal initialisieren     "
    echo -e "==================================================================${NC}"
    if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:${PORT_SEERR}${NC} (oder via Tailscale: ${BOLD}http://${TAILSCALE_IP}:${PORT_SEERR}${NC})"
    else
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:${PORT_SEERR}${NC}"
    fi
    echo -e "2. Wähle ${BOLD}\"Mit Jellyfin anmelden\"${NC}."
    echo -e "3. Gib folgende Verbindungsdaten für Jellyfin ein:"
    echo -e "   • ${BOLD}Jellyfin-URL:${NC}  ${GREEN}http://jellyfin:8096${NC}"
    echo -e "   • ${BOLD}Benutzername:${NC}  Dein soeben erstellter Jellyfin-Admin"
    echo -e "   • ${BOLD}Passwort:${NC}      Dein Jellyfin-Passwort"
    echo -e "4. Wähle die synchronisierten Bibliotheken (Filme & Serien) aus und klicke auf Weiter.\n"

    read_input -p "Drücke [Enter], wenn Schritt 2 abgeschlossen ist, für die Radarr/Sonarr-Verknüpfung... " _

    # --- SCHRITT 3: RADARR & SONARR IN SEERR EINBINDEN ---
    echo -e "\n${CYAN}=================================================================="
    echo -e "       🔗 Schritt 3 / 3: Radarr & Sonarr in Seerr verknüpfen     "
    echo -e "==================================================================${NC}"
    echo -e "${YELLOW}ℹ️  ${HOST_EXPLANATION}${NC}\n"
    echo -e "Gehe in Seerr auf ${BOLD}Einstellungen > Dienste${NC} und füge hinzu:\n"

    if [ "$USE_VPN" = true ]; then
        echo -e "🍿 ${BOLD}Radarr (Filme):${NC}"
        echo -e "   • Standardserver:        ${GREEN}Aktivieren${NC}"
        echo -e "   • Servername:            Radarr"
        echo -e "   • Hostname oder IP:      ${GREEN}${BOLD}gluetun${NC}"
        echo -e "   • Port:                  ${BOLD}7878${NC}"
        echo -e "   • API-Schlüssel:         ${GREEN}${BOLD}${RADARR_API_KEY}${NC}"
        echo -e "   • Stammordner:           /data/media/movies\n"

        echo -e "📺 ${BOLD}Sonarr (Serien):${NC}"
        echo -e "   • Standardserver:        ${GREEN}Aktivieren${NC}"
        echo -e "   • Servername:            Sonarr"
        echo -e "   • Hostname oder IP:      ${GREEN}${BOLD}gluetun${NC}"
        echo -e "   • Port:                  ${BOLD}8989${NC}"
        echo -e "   • API-Schlüssel:         ${GREEN}${BOLD}${SONARR_API_KEY}${NC}"
        echo -e "   • Stammordner:           /data/media/tv\n"
    else
        echo -e "🍿 ${BOLD}Radarr (Filme):${NC}"
        echo -e "   • Standardserver:        ${GREEN}Aktivieren${NC}"
        echo -e "   • Servername:            Radarr"
        echo -e "   • Hostname oder IP:      ${GREEN}${BOLD}radarr${NC}"
        echo -e "   • Port:                  ${BOLD}7878${NC}"
        echo -e "   • API-Schlüssel:         ${GREEN}${BOLD}${RADARR_API_KEY}${NC}"
        echo -e "   • Stammordner:           /data/media/movies\n"

        echo -e "📺 ${BOLD}Sonarr (Serien):${NC}"
        echo -e "   • Standardserver:        ${GREEN}Aktivieren${NC}"
        echo -e "   • Servername:            Sonarr"
        echo -e "   • Hostname oder IP:      ${GREEN}${BOLD}sonarr${NC}"
        echo -e "   • Port:                  ${BOLD}8989${NC}"
        echo -e "   • API-Schlüssel:         ${GREEN}${BOLD}${SONARR_API_KEY}${NC}"
        echo -e "   • Stammordner:           /data/media/tv\n"
    fi

    echo -e "${GREEN}✓ Klicke bei beiden Servern auf 'Verbindung testen' und anschließend auf 'Speichern'.${NC}"
    echo -e "${GREEN}${BOLD}🎉 Fertig! Dein gesamter Medien- und Download-Workflow ist nun zu 100% startklar!${NC}\n"
fi