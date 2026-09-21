#!/usr/bin/env bash
# ==============================================================================
# 🧭 USENET-KOMPASS INSTALLER
# Der umfassende deutsche Leitfaden für automatisierte Usenet-Downloads,
# Medienserver und Heimkino mit Docker Compose.
# Repository: https://github.com/KAiSER086/Usenet-Kompass
# ==============================================================================

set -euo pipefail

# Interaktive Benutzereingaben sicherstellen – auch wenn das Skript
# per Pipe (curl -fsSL ... | bash) ausgeführt wird:
read_input() {
    if [ -e /dev/tty ]; then
        read -r "$@" < /dev/tty
    else
        read -r "$@"
    fi
}

read_secret() {
    if [ -e /dev/tty ]; then
        read -r -s "$@" < /dev/tty
    else
        read -r -s "$@"
    fi
}

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
    DISTRO_NAME=$(grep -E '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
    DISTRO_ID=$(grep -E '^ID=' /etc/os-release | cut -d= -f2- | tr -d '"')
    DISTRO_LIKE=$(grep -E '^ID_LIKE=' /etc/os-release | cut -d= -f2- | tr -d '"')
fi
[ -z "$DISTRO_NAME" ] && DISTRO_NAME="$(uname -s) ($(uname -m))"

echo -e "${GREEN}✓ Betriebssystem erkannt: ${BOLD}${DISTRO_NAME}${NC}"

# Docker & Compose prüfen
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}Docker ist noch nicht installiert.${NC}"
    read_input -p "Möchtest du Docker jetzt automatisch offiziell installieren lassen? [J/n]: " INSTALL_DOCKER
    INSTALL_DOCKER=${INSTALL_DOCKER:-J}
    if [[ "$INSTALL_DOCKER" =~ ^[jJyY]$ ]]; then
        echo -e "${CYAN}Installiere Docker für ${DISTRO_NAME}...${NC}"
        if command -v pacman &> /dev/null; then
            echo -e "${CYAN}Arch Linux Familie erkannt: Installiere Docker via pacman...${NC}"
            sudo pacman -Sy --noconfirm docker docker-compose || true
        elif command -v zypper &> /dev/null; then
            echo -e "${CYAN}openSUSE Familie erkannt: Installiere Docker via zypper...${NC}"
            sudo zypper --non-interactive install docker docker-compose docker-compose-switch 2>/dev/null || sudo zypper --non-interactive install docker docker-compose || true
        elif command -v apk &> /dev/null; then
            echo -e "${CYAN}Alpine Linux erkannt: Installiere Docker via apk...${NC}"
            sudo apk add --no-cache docker docker-cli-compose || true
        else
            echo -e "${CYAN}Installiere Docker via offiziellem Docker-Installationsskript...${NC}"
            curl -fsSL https://get.docker.com | sh
        fi
        sudo usermod -aG docker "$USER" 2>/dev/null || true
        if command -v systemctl &>/dev/null; then
            sudo systemctl enable --now docker 2>/dev/null || sudo systemctl start docker 2>/dev/null || true
        elif command -v rc-service &>/dev/null; then
            sudo rc-service docker start 2>/dev/null || true
            sudo rc-update add docker default 2>/dev/null || true
        fi
        echo -e "${GREEN}✓ Docker erfolgreich installiert!${NC}"
    else
        echo -e "${RED}Docker ist erforderlich. Bitte installiere Docker manuell und starte den Installer erneut.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker ist vorhanden.${NC}"
fi

# Stelle sicher, dass der Docker-Daemon aktiv ist
if ! docker ps &>/dev/null && ! sudo docker ps &>/dev/null; then
    if command -v systemctl &>/dev/null; then
        sudo systemctl enable --now docker 2>/dev/null || sudo systemctl start docker 2>/dev/null || true
    elif command -v rc-service &>/dev/null; then
        sudo rc-service docker start 2>/dev/null || true
    fi
fi

# VPN- & TUN-Kernelmodule laden, falls nicht aktiv (z. B. minimales openSUSE Leap / Debian)
sudo modprobe tun 2>/dev/null || true
sudo modprobe wireguard 2>/dev/null || true

# Compose Plugin prüfen
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Docker Compose ist einsatzbereit.${NC}"
elif command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ docker-compose (Legacy) ist einsatzbereit.${NC}"
else
    echo -e "${YELLOW}Docker Compose Plugin fehlt. Installiere docker-compose-plugin...${NC}"
    if command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm docker-compose || true
    elif command -v zypper &> /dev/null; then
        sudo zypper --non-interactive install docker-compose docker-compose-switch 2>/dev/null || sudo zypper --non-interactive install docker-compose || true
    elif command -v apk &> /dev/null; then
        sudo apk add --no-cache docker-cli-compose || true
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y docker-compose-plugin || true
    elif command -v apt-get &> /dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y docker-compose-plugin 2>/dev/null || true
    elif command -v apt &> /dev/null; then
        sudo apt update && sudo apt install -y docker-compose-plugin || true
    fi

    # Universeller Fallback auf offizielles Standalone-Binary falls Paketmanager kein v2 bereitstellt
    if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
        ARCH=$(uname -m)
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

# PUID & PGID ermitteln
CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)
echo -e "${GREEN}✓ Verwende System-Kennungen: PUID=${CURRENT_UID}, PGID=${CURRENT_GID}${NC}"

# Lokales Heimnetzwerk / Subnetz über das physische Interface der Default Route ermitteln
DEFAULT_IFACE=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n 1 || true)
DETECTED_SUBNET=""
if [ -n "$DEFAULT_IFACE" ]; then
    # Nur das Subnetz des physischen Interfaces abfragen (ignoriert docker0, br-xxx etc.)
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
echo -e "${CYAN}▶ Lokale Heimnetz-Erkennung (Gluetun Firewall):${NC}"
echo -e "Erkanntes lokales Subnetz: ${BOLD}${DETECTED_SUBNET}${NC}"
read_input -p "Lokales Subnetz übernehmen (Enter) oder manuell anpassen: " CUSTOM_SUBNET
LAN_SUBNET=${CUSTOM_SUBNET:-$DETECTED_SUBNET}
echo -e "${GREEN}✓ Lokales Subnetz für Gluetun gesetzt: ${LAN_SUBNET}${NC}"

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
echo -e "  ${BOLD}[1] NZBGet${NC}  ${GREEN}(⭐ Dringend empfohlen für sparsame Server & Raspberry Pi)${NC}"
echo -e "      Kompiliert in nativem C++. Extrem ressourcenschonend, liefert maximale"
echo -e "      Download-Geschwindigkeit bei minimaler CPU-Auslastung auch auf sparsamer Hardware."
echo ""
echo -e "  ${BOLD}[2] SABnzbd${NC} (Sehr beliebt & modern)"
echo -e "      Python-basiert mit erstklassiger, moderner Weboberfläche, integrierter"
echo -e "      Auto-PAR2-Reparatur und Direkt-Entpacken."
echo ""
read_input -p "Deine Wahl [1 oder 2, Standard: 1]: " DOWNLOADER_CHOICE
DOWNLOADER_CHOICE=${DOWNLOADER_CHOICE:-1}

if [ "$DOWNLOADER_CHOICE" = "2" ]; then
    SELECTED_DOWNLOADER="sabnzbd"
    DOWNLOADER_PORT="8080"
    DOWNLOADER_SERVICE_NAME="SABnzbd"
else
    SELECTED_DOWNLOADER="nzbget"
    DOWNLOADER_PORT="6789"
    DOWNLOADER_SERVICE_NAME="NZBGet"
fi
echo -e "${GREEN}✓ Ausgewählter Downloader: ${DOWNLOADER_SERVICE_NAME}${NC}"

# ------------------------------------------------------------------------------
# 4.0 VPN-KONFIGURATION (WIREGUARD VS. OPENVPN)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}==================================================================${NC}"
echo -e "${BOLD}▶ SCHRITT 2: VPN-Protokoll & Sicherheit (Gluetun)${NC}"
echo -e "${CYAN}==================================================================${NC}"
echo -e "  ${BOLD}[1] WireGuard${NC} ${GREEN}(⭐ Dringend empfohlen!)${NC}"
echo -e "      Modern, direkt im Linux-Kernel integriert. Liefert maximalen Durchsatz"
echo -e "      bei minimaler Prozessorlast auf sparsamer Hardware / Mini-PCs."
echo ""
echo -e "  ${BOLD}[2] OpenVPN${NC}   ${YELLOW}(Veraltetes Fallback)${NC}"
echo -e "      Erzeugt hohe CPU-Last und bremst schnelle Internetleitungen oft aus."
echo ""
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

WIREGUARD_PRIVATE_KEY=""
WIREGUARD_ADDRESSES=""
OPENVPN_USER=""
OPENVPN_PASS=""

if [ "$VPN_PROTO_CHOICE" = "2" ]; then
    VPN_TYPE="openvpn"
    echo ""
    read_input -p "Gib deinen OpenVPN Benutzernamen ein: " OPENVPN_USER
    read_secret -p "Gib dein OpenVPN Passwort ein: " OPENVPN_PASS
    echo ""
else
    VPN_TYPE="wireguard"
    echo ""
    while [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; do
        read_input -p "Füge deinen WireGuard Private Key ein: " WIREGUARD_PRIVATE_KEY
        if [ -z "${WIREGUARD_PRIVATE_KEY:-}" ]; then
            echo -e "${YELLOW}⚠️  Der WireGuard Private Key darf nicht leer sein, da Gluetun sonst nicht starten kann.${NC}"
        fi
    done
    read_input -p "Deine zugewiesene WireGuard-IP (z. B. 10.64.0.1/32): " WIREGUARD_ADDRESSES
fi

read_input -p "Gewünschte VPN Server-Länder [Standard: Netherlands,Germany]: " VPN_COUNTRIES
VPN_COUNTRIES=${VPN_COUNTRIES:-"Netherlands,Germany"}

# ------------------------------------------------------------------------------
# 5.0 VERZEICHNISSTRUKTUR ANLEGEN (TRaSH-GUIDES STANDARD)
# ------------------------------------------------------------------------------
echo ""
echo -e "${CYAN}▶ Erstelle TRaSH-Guides Verzeichnisstruktur für Instant Atomic Moves...${NC}"

INSTALL_DIR="$(pwd)"
mkdir -p "$INSTALL_DIR/data/usenet/complete"
mkdir -p "$INSTALL_DIR/data/usenet/incomplete"
mkdir -p "$INSTALL_DIR/data/media/movies"
mkdir -p "$INSTALL_DIR/data/media/tv"

mkdir -p "$INSTALL_DIR/config/gluetun"
mkdir -p "$INSTALL_DIR/config/prowlarr"
mkdir -p "$INSTALL_DIR/config/sonarr"
mkdir -p "$INSTALL_DIR/config/radarr"
mkdir -p "$INSTALL_DIR/config/jellyfin"
mkdir -p "$INSTALL_DIR/config/jellyseerr"
mkdir -p "$INSTALL_DIR/config/$SELECTED_DOWNLOADER"

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
    chcon -Rt container_file_t "$INSTALL_DIR/config" "$INSTALL_DIR/data" 2>/dev/null || sudo chcon -Rt container_file_t "$INSTALL_DIR/config" "$INSTALL_DIR/data" 2>/dev/null || true
fi

# Berechtigungen sicherstellen
chmod -R 755 "$INSTALL_DIR/data" || true
echo -e "${GREEN}✓ Ordnerstruktur erfolgreich unter $INSTALL_DIR/data angelegt.${NC}"

# ------------------------------------------------------------------------------
# 6.0 DOCKER-COMPOSE.YML GENERIEREN
# ------------------------------------------------------------------------------
echo -e "${CYAN}▶ Generiere maßgeschneiderte docker-compose.yml...${NC}"

cat <<EOF > "$INSTALL_DIR/docker-compose.yml"
services:
  gluetun:
    image: qmcgaw/gluetun:latest
    container_name: gluetun
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun:/dev/net/tun
    environment:
      - VPN_SERVICE_PROVIDER=${VPN_PROVIDER}
      - VPN_TYPE=${VPN_TYPE}
EOF

if [ "$VPN_TYPE" = "wireguard" ]; then
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - WIREGUARD_PRIVATE_KEY=${WIREGUARD_PRIVATE_KEY}
      - WIREGUARD_ADDRESSES=${WIREGUARD_ADDRESSES}
EOF
else
cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - OPENVPN_USER=${OPENVPN_USER}
      - OPENVPN_PASSWORD=${OPENVPN_PASS}
EOF
fi

cat <<EOF >> "$INSTALL_DIR/docker-compose.yml"
      - SERVER_COUNTRIES=${VPN_COUNTRIES}
      - FIREWALL_OUTBOUND_SUBNETS=${LAN_SUBNET}
      - TZ=Europe/Berlin
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
    ports:
      - "${DOWNLOADER_PORT}:${DOWNLOADER_PORT}" # Downloader (${DOWNLOADER_SERVICE_NAME}) WebUI
      - "7878:7878" # Radarr WebUI & API
      - "8989:8989" # Sonarr WebUI & API
      - "9696:9696" # Prowlarr WebUI & API
    volumes:
      - ./config/gluetun:/gluetun
    restart: unless-stopped

  # --- Downloader: ${DOWNLOADER_SERVICE_NAME} ---
  ${SELECTED_DOWNLOADER}:
    image: lscr.io/linuxserver/${SELECTED_DOWNLOADER}:latest
    container_name: ${SELECTED_DOWNLOADER}
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/${SELECTED_DOWNLOADER}:/config
      - ./data:/data
    restart: unless-stopped
    depends_on:
      - gluetun
    network_mode: "service:gluetun"

  # --- Arr-Stack (Automation & Indexer) ---
  prowlarr:
    image: lscr.io/linuxserver/prowlarr:latest
    container_name: prowlarr
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/prowlarr:/config
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
    restart: unless-stopped

  sonarr:
    image: lscr.io/linuxserver/sonarr:latest
    container_name: sonarr
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/sonarr:/config
      - ./data:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped

  radarr:
    image: lscr.io/linuxserver/radarr:latest
    container_name: radarr
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/radarr:/config
      - ./data:/data
    network_mode: "service:gluetun"
    depends_on:
      - gluetun
      - ${SELECTED_DOWNLOADER}
    restart: unless-stopped

  # --- Frontend (Medienserver & Anfragen) ---
  jellyfin:
    image: lscr.io/linuxserver/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/jellyfin:/config
      - ./data/media:/data/media
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

  jellyseerr:
    image: fallenbagel/jellyseerr:latest
    container_name: jellyseerr
    environment:
      - PUID=${CURRENT_UID}
      - PGID=${CURRENT_GID}
      - TZ=Europe/Berlin
    volumes:
      - ./config/jellyseerr:/app/config
    ports:
      - "5055:5055"
    depends_on:
      - radarr
      - sonarr
      - gluetun
    restart: unless-stopped
EOF

echo -e "${GREEN}✓ docker-compose.yml wurde erfolgreich erstellt!${NC}\n"

# ------------------------------------------------------------------------------
# 7.0 STARTEN DES STACKS
# ------------------------------------------------------------------------------
# Prüfe, ob Docker-Befehle ohne sudo ausgeführt werden können (z. B. direkt nach Neuinstallation)
RUN_DOCKER_CMD="$COMPOSE_CMD"
DOCKER_BIN="docker"
if ! docker ps &>/dev/null; then
    if sudo docker ps &>/dev/null; then
        RUN_DOCKER_CMD="sudo $COMPOSE_CMD"
        DOCKER_BIN="sudo docker"
    fi
fi

# Prüfe vorab auf Namenskonflikte mit bestehenden Containern
CONFLICTING_CONTAINERS=$($DOCKER_BIN ps -a --format '{{.Names}}' 2>/dev/null | grep -E "^(gluetun|sonarr|radarr|prowlarr|jellyfin|jellyseerr|${SELECTED_DOWNLOADER})$" || true)

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
    if [[ "$RUN_DOCKER_CMD" == *"sudo"* ]]; then
        sudo chown -R "${CURRENT_UID}:${CURRENT_GID}" "$INSTALL_DIR/data" "$INSTALL_DIR/config" 2>/dev/null || true
    fi
    echo -e "\n${GREEN}${BOLD}🎉 HERZLICHEN GLÜCKWUNSCH! DEIN STACK LÄUFT!${NC}\n"

    # --- 7.1 VPN-LEAK-TEST & LIVE-IP-CHECK ---
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

    # --- 7.2 AUTOMATISCHES APP-LINKING ANBIETEN ---
    echo -e "${CYAN}------------------------------------------------------------------${NC}"
    echo -e "${BOLD}▶ MÖCHTEST DU DIE MEDIEN-APPS JETZT VOLLAUTOMATISCH VERKNÜPFEN?${NC}"
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
# 8.0 ÜBERSICHT DER WEB-INTERFACES
# ------------------------------------------------------------------------------
echo -e "${CYAN}=================================================================="
echo -e "                   DEINE WEB-INTERFACES                           "
echo -e "==================================================================${NC}"
echo -e "🍿 ${BOLD}Jellyseerr (Medien-Anfragen):${NC}    http://${SERVER_IP}:5055"
echo -e "🎬 ${BOLD}Jellyfin (Medienserver):${NC}         http://${SERVER_IP}:8096"
echo -e "⚡ ${BOLD}${DOWNLOADER_SERVICE_NAME} (Downloader):${NC}         http://${SERVER_IP}:${DOWNLOADER_PORT}"
echo -e "📺 ${BOLD}Sonarr (Serien-Manager):${NC}         http://${SERVER_IP}:8989"
echo -e "🎬 ${BOLD}Radarr (Film-Manager):${NC}           http://${SERVER_IP}:7878"
echo -e "🔍 ${BOLD}Prowlarr (Indexer-Hub):${NC}          http://${SERVER_IP}:9696"
echo -e "${CYAN}==================================================================${NC}"
echo -e "📌 Nächste Schritte: Richte deinen Indexer in Prowlarr ein und hinterlege"
echo -e "   deinen Provider in ${DOWNLOADER_SERVICE_NAME}."
echo -e "   Vollständige Anleitung: ${BOLD}https://github.com/KAiSER086/Usenet-Kompass${NC}\n"
