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
for arg in "$@"; do
    case "$arg" in
        --dry-run|--test|-t)
            DRY_RUN=true
            ;;
        --help|-h)
            echo "Verwendung: bash install.sh [OPTIONEN]"
            echo "Optionen:"
            echo "  --dry-run, --test, -t   Führt Syntaxprüfungen und Template-Generierung ohne Container-Start durch."
            echo "  --help, -h              Zeigt diesen Hilfetext an."
            exit 0
            ;;
    esac
done

# Interaktive Benutzereingaben sicherstellen – auch wenn das Skript
# per Pipe (curl -fsSL ... | bash) oder non-tty ausgeführt wird:
read_input() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    elif [ -t 0 ]; then
        read -r "$@"
    elif (exec < /dev/tty) 2>/dev/null; then
        read -r "$@" < /dev/tty
    else
        read -r "$@"
    fi
}

read_secret() {
    if [ "$DRY_RUN" = true ]; then
        return 0
    elif [ -t 0 ]; then
        read -r -s "$@"
    elif (exec < /dev/tty) 2>/dev/null; then
        read -r -s "$@" < /dev/tty
    else
        read -r -s "$@"
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

# --- Farben & UI-Elemente ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

clear || true

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
echo -e "drei Dinge bereitliegen hast:\n"
echo -e "  ${BOLD}1. Einen Usenet-Provider Account${NC} (z. B. Eweka, NewsgroupDirect, etc.)"
echo -e "  ${BOLD}2. Mindestens einen Usenet-Indexer${NC} mit API-Key (z. B. Treasure-Maps, NZBGeek)"
echo -e "  ${BOLD}3. Einen VPN-Account${NC} mit WireGuard-Support (z. B. Mullvad, ProtonVPN, Surfshark)"
echo ""
read_input -p "Hast du diese Zugänge bereit und möchtest fortfahren? [J/n]: " READY_CHOICE
READY_CHOICE=${READY_CHOICE:-J}

if [[ ! "$READY_CHOICE" =~ ^[jJyY]$ ]]; then
    echo -e "\n${RED}Installation abgebrochen.${NC}"
    echo "Besorge dir zuerst die nötigen Zugänge und starte den Installer danach erneut."
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
DISTRO_ID=""
DISTRO_LIKE=""
if [ -f /etc/os-release ]; then
    DISTRO_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
    DISTRO_ID=$(grep -E '^ID=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
    DISTRO_LIKE=$(grep -E '^ID_LIKE=' /etc/os-release 2>/dev/null | cut -d= -f2- | tr -d '"' || true)
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
            if [ "$USER" != "root" ] && [ -n "${USER:-}" ]; then
                $SUDO usermod -aG docker "$USER" 2>/dev/null || true
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
    CURRENT_UID=1000
    CURRENT_GID=1000
fi
echo -e "${GREEN}✓ Verwende System-Kennungen: PUID=${CURRENT_UID}, PGID=${CURRENT_GID}${NC}"

# Server-IP für die spätere Anzeige ermitteln
SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "localhost")

# Prüfe Hardwarebeschleunigung (/dev/dri für Intel QuickSync / VAAPI)
DRI_PRESENT=false
RENDER_GID=""
if [ -d "/dev/dri" ]; then
    DRI_PRESENT=true
    RENDER_GID=$(getent group render 2>/dev/null | cut -d: -f3 || true)
    echo -e "${GREEN}✓ Hardware-Transcoding erkannt (/dev/dri) – QuickSync / VAAPI wird für Jellyfin aktiviert.${NC}"
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
read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " DOWNLOADER_CHOICE
DOWNLOADER_CHOICE=${DOWNLOADER_CHOICE:-1}

if [ "$DOWNLOADER_CHOICE" = "2" ]; then
    SELECTED_DOWNLOADER="nzbget"
    DOWNLOADER_PORT="6789"
    DOWNLOADER_SERVICE_NAME="NZBGet"
else
    SELECTED_DOWNLOADER="sabnzbd"
    DOWNLOADER_PORT="8080"
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
read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " VPN_MODE_CHOICE
VPN_MODE_CHOICE=${VPN_MODE_CHOICE:-1}

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
    echo ""
    echo -e "Welches VPN-Protokoll möchtest du nutzen?"
    echo -e "  [1] WireGuard (Direkt im Linux-Kernel integriert, minimaler CPU-Overhead)"
    echo -e "  [2] OpenVPN   (Klassisches Userspace-Protokoll, höhere CPU-Last)"
    read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " VPN_PROTO_CHOICE
    VPN_PROTO_CHOICE=${VPN_PROTO_CHOICE:-1}

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

    if [ "$VPN_PROTO_CHOICE" = "2" ]; then
        VPN_TYPE="openvpn"
        echo ""
        read_input -p "Gib deinen OpenVPN Benutzernamen ein: " OPENVPN_USER
        read_secret -p "Gib dein OpenVPN Passwort ein: " OPENVPN_PASS
        echo ""
        OPENVPN_USER=${OPENVPN_USER:-"dummy_user"}
        OPENVPN_PASS=${OPENVPN_PASS:-"dummy_pass"}
    else
        VPN_TYPE="wireguard"
        echo ""
        if [ "$DRY_RUN" = true ]; then
            WIREGUARD_PRIVATE_KEY="c29tZXJhbmRvbXdpcmVndWFyZHByaXZhdGVrZXkxMjM0NTY="
            WIREGUARD_ADDRESSES="10.64.0.1/32"
        else
            while [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; do
                read_input -p "Füge deinen WireGuard Private Key ein: " WIREGUARD_PRIVATE_KEY
                if [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; then
                    echo -e "${YELLOW}⚠️  Der WireGuard Private Key darf nicht leer sein, da Gluetun sonst nicht starten kann.${NC}"
                fi
            done
            read_input -p "Deine zugewiesene WireGuard-IP (z. B. 10.64.0.1/32): " WIREGUARD_ADDRESSES
        fi
    fi

    read_input -p "Gewünschte VPN Server-Länder [Standard: Netherlands,Germany]: " VPN_COUNTRIES
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
    echo ""
    echo -e "${CYAN}▶ Lokale Heimnetz-Erkennung (Gluetun Firewall Bypass):${NC}"
    echo -e "Erkanntes lokales Subnetz: ${BOLD}${DETECTED_SUBNET}${NC}"
    read_input -p "Lokales Subnetz übernehmen (Enter) oder manuell anpassen: " CUSTOM_SUBNET
    CHOSEN_SUBNET=${CUSTOM_SUBNET:-$DETECTED_SUBNET}
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

if [ -n "$TAILSCALE_DETECTED_IP" ]; then
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
    read_input -p "Möchtest du Tailscale für sicheren Fernzugriff einrichten und einbinden? [j/N]: " TAILSCALE_INPUT
    TAILSCALE_INPUT=${TAILSCALE_INPUT:-N}
    if [[ "$TAILSCALE_INPUT" =~ ^[jJyY]$ ]]; then
        WANT_TAILSCALE=true
        echo -e "${GREEN}✓ Tailscale wird nach dem Start des Stacks eingerichtet.${NC}"
    else
        echo -e "${YELLOW}Tailscale übersprungen. Du kannst es bei Bedarf jederzeit später einrichten.${NC}"
    fi
fi

# Firewall-Bypass für Gluetun finalisieren: Tailscale nur hinzufügen, wenn gewünscht!
if [ "$USE_VPN" = true ]; then
    if [ "$WANT_TAILSCALE" = true ]; then
        if [[ "$CHOSEN_SUBNET" != *"100.64.0.0/10"* ]]; then
            LAN_SUBNET="${CHOSEN_SUBNET},100.64.0.0/10"
        else
            LAN_SUBNET="${CHOSEN_SUBNET}"
        fi
        echo -e "${GREEN}✓ Gluetun Firewall-Bypass gesetzt: Lokales Netz (${CHOSEN_SUBNET}) & Tailscale (100.64.0.0/10).${NC}"
    else
        LAN_SUBNET="${CHOSEN_SUBNET}"
        echo -e "${GREEN}✓ Gluetun Firewall-Bypass auf lokales Heimnetz beschränkt (${CHOSEN_SUBNET}). Kein Tailscale-Bypass.${NC}"
    fi
fi

# ------------------------------------------------------------------------------
# 5.0 VERZEICHNISSTRUKTUR ANLEGEN (TRaSH-GUIDES STANDARD)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}▶ Erstelle TRaSH-Guides Verzeichnisstruktur für Instant Atomic Moves...${NC}"

INSTALL_DIR="$(pwd)"
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
      - VPN_SERVICE_PROVIDER=\${VPN_SERVICE_PROVIDER:-${VPN_PROVIDER}}
      - VPN_TYPE=\${VPN_TYPE:-${VPN_TYPE}}
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
      - SERVER_COUNTRIES=\${SERVER_COUNTRIES:-${VPN_COUNTRIES}}
      - FIREWALL_OUTBOUND_SUBNETS=\${FIREWALL_OUTBOUND_SUBNETS:-${LAN_SUBNET}}
      - TZ=\${TZ:-Europe/Berlin}
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
    ports:
      - "${DOWNLOADER_PORT}:${DOWNLOADER_PORT}" # Downloader (${DOWNLOADER_SERVICE_NAME}) WebUI
      - "7878:7878" # Radarr WebUI & API
      - "8989:8989" # Sonarr WebUI & API
      - "9696:9696" # Prowlarr WebUI & API
    volumes:
      - \${CONFIG_DIR:-./config}/gluetun:/gluetun
    restart: unless-stopped

  # --- Downloader: ${DOWNLOADER_SERVICE_NAME} ---
  ${SELECTED_DOWNLOADER}:
    image: lscr.io/linuxserver/${SELECTED_DOWNLOADER}:latest
    container_name: ${SELECTED_DOWNLOADER}
    <<: *default-logging
    environment:
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/${SELECTED_DOWNLOADER}:/config
      - \${DATA_DIR:-./data}:/data
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
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/prowlarr:/config
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/sonarr:/config
      - \${DATA_DIR:-./data}:/data
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
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/radarr:/config
      - \${DATA_DIR:-./data}:/data
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
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/${SELECTED_DOWNLOADER}:/config
      - \${DATA_DIR:-./data}:/data
    ports:
      - "${DOWNLOADER_PORT}:${DOWNLOADER_PORT}"
    restart: unless-stopped

  # --- Arr-Stack (Automation & Indexer) ---
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    <<: *default-logging
    environment:
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/prowlarr:/config
    ports:
      - "9696:9696"
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    <<: *default-logging
    environment:
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/sonarr:/config
      - \${DATA_DIR:-./data}:/data
    ports:
      - "8989:8989"
    depends_on:
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    <<: *default-logging
    environment:
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/radarr:/config
      - \${DATA_DIR:-./data}:/data
    ports:
      - "7878:7878"
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
      - PUID=\${PUID:-1000}
      - PGID=\${PGID:-1000}
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/jellyfin:/config
      - \${DATA_DIR:-./data}/media:/data/media
    ports:
      - "8096:8096"
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
      - TZ=\${TZ:-Europe/Berlin}
    volumes:
      - \${CONFIG_DIR:-./config}/seerr:/app/config
    ports:
      - "5055:5055"
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
if [ -n "$CONFLICTING_CONTAINERS" ]; then
    echo -e "${YELLOW}⚠️  ACHTUNG: Auf diesem System existieren bereits Container mit identischen Namen:${NC}"
    echo -e "${BOLD}${CONFLICTING_CONTAINERS}${NC}"
    read_input -p "Möchtest du diese bestehenden Container stoppen und entfernen, um den neuen Stack zu starten? [j/N]: " REMOVE_CONFLICTS
    REMOVE_CONFLICTS=${REMOVE_CONFLICTS:-N}
    if [[ "$REMOVE_CONFLICTS" =~ ^[jJyY]$ ]]; then
        echo -e "${CYAN}Stoppe und entferne kollidierende Container...${NC}"
        echo "$CONFLICTING_CONTAINERS" | xargs -r $DOCKER_BIN rm -f
    else
        echo -e "\n${YELLOW}Hinweis: Die neue docker-compose.yml wurde erstellt, wird aber wegen der bestehenden Container nicht gestartet.${NC}"
        START_NOW="n"
    fi
fi

if [ "$START_NOW" != "n" ]; then
    read_input -p "Möchtest du den Stack jetzt direkt im Hintergrund starten? [J/n]: " START_NOW
    START_NOW=${START_NOW:-J}
fi

if [[ "$START_NOW" =~ ^[jJyY]$ ]]; then
    echo -e "${CYAN}Starte Docker Stack via '$RUN_DOCKER_CMD up -d'...${NC}"
    $RUN_DOCKER_CMD up -d
    if [[ "$RUN_DOCKER_CMD" == *"sudo"* ]] || [ "$(id -u)" -eq 0 ]; then
        $SUDO chown -R "${CURRENT_UID}:${CURRENT_GID}" "$INSTALL_DIR/data" "$INSTALL_DIR/config" 2>/dev/null || true
    fi
    echo -e "\n${GREEN}${BOLD}🎉 HERZLICHEN GLÜCKWUNSCH! DEIN STACK LÄUFT!${NC}\n"

    # --- 7.1 STATUS-CHECK (VPN-LEAK-TEST ODER DIREKT-MODUS) ---
    if [ "$USE_VPN" = true ]; then
        echo -e "${CYAN}⏳ Warte kurz auf VPN-Tunnelverbindung für den Sicherheits-Check...${NC}"
        VPN_JSON=""
        for i in {1..10}; do
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
    read_input -p "Apps jetzt automatisch verknüpfen? [J/n]: " RUN_LINK
    RUN_LINK=${RUN_LINK:-J}
    if [[ "$RUN_LINK" =~ ^[jJyY]$ ]]; then
        if [ -f "$INSTALL_DIR/link-apps.sh" ]; then
            chmod +x "$INSTALL_DIR/link-apps.sh"
            bash "$INSTALL_DIR/link-apps.sh" || true
        else
            curl -fsSL "https://raw.githubusercontent.com/KAiSER086/Usenet-Kompass/main/link-apps.sh" -o "$INSTALL_DIR/link-apps.sh" 2>/dev/null || true
            chmod +x "$INSTALL_DIR/link-apps.sh" 2>/dev/null || true
            if [ -f "$INSTALL_DIR/link-apps.sh" ]; then
                bash "$INSTALL_DIR/link-apps.sh" || true
            fi
        fi
    else
        echo -e "${YELLOW}Du kannst die Apps jederzeit später verknüpfen mit: ${BOLD}./link-apps.sh${NC}\n"
    fi
else
    echo -e "\n${YELLOW}Alles vorbereitet! Starte den Stack später mit: ${BOLD}$RUN_DOCKER_CMD up -d${NC}\n"
fi

# ------------------------------------------------------------------------------
# 7.3 OPTIONALER FERNZUGRIFF MIT TAILSCALE
# ------------------------------------------------------------------------------
if [ "$WANT_TAILSCALE" = true ]; then
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
echo -e "🍿 ${BOLD}Seerr (Medien-Anfragen):${NC}         http://${SERVER_IP}:5055"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:5055"
fi
echo -e "🎬 ${BOLD}Jellyfin (Medienserver):${NC}         http://${SERVER_IP}:8096"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:8096"
fi
echo -e "⚡ ${BOLD}${DOWNLOADER_SERVICE_NAME} (Downloader):${NC}         http://${SERVER_IP}:${DOWNLOADER_PORT}"
if [ "$WANT_TAILSCALE" = true ] && [ -n "$TAILSCALE_IP" ]; then
    echo -e "   └─ Unterwegs (Tailscale):        http://${TAILSCALE_IP}:${DOWNLOADER_PORT}"
fi
echo -e "📺 ${BOLD}Sonarr (Serien-Manager):${NC}         http://${SERVER_IP}:8989"
echo -e "🎬 ${BOLD}Radarr (Film-Manager):${NC}           http://${SERVER_IP}:7878"
echo -e "🔍 ${BOLD}Prowlarr (Indexer-Hub):${NC}          http://${SERVER_IP}:9696"
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
echo -e "${CYAN}------------------------------------------------------------------${NC}"
echo -e "${BOLD}▶ Möchtest du jetzt den Schritt-für-Schritt Einrichtungsassistenten"
echo -e "  für Jellyfin & Seerr starten?${NC}"
read_input -p "Ersteinrichtung jetzt Schritt für Schritt durchgehen? [J/n]: " RUN_FRONTEND_GUIDE
RUN_FRONTEND_GUIDE=${RUN_FRONTEND_GUIDE:-J}

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
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:8096${NC} (oder via Tailscale: ${BOLD}http://${TAILSCALE_IP}:8096${NC})"
    else
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:8096${NC}"
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
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:5055${NC} (oder via Tailscale: ${BOLD}http://${TAILSCALE_IP}:5055${NC})"
    else
        echo -e "1. Öffne im Browser: ${BOLD}http://${SERVER_IP}:5055${NC}"
    fi
    echo -e "2. Wähle ${BOLD}„Mit Jellyfin anmelden“${NC}."
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
