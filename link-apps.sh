#!/usr/bin/env bash
# ==============================================================================
# Usenet-Kompass - Automatischer App-Linker (link-apps.sh)
#
# Verknüpft vollautomatisch über die REST-APIs:
#   - Prowlarr  <-->  Sonarr (fullSync)
#   - Prowlarr  <-->  Radarr (fullSync)
#   - Sonarr    <-->  NZBGet / SABnzbd + Root-Folder (/data/media/tv)
#   - Radarr    <-->  NZBGet / SABnzbd + Root-Folder (/data/media/movies)
# ==============================================================================

set -e

# Farben & Formatierung
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "=================================================================="
echo "          🧭  U S E N E T - K O M P A S S                      "
echo "              AUTOMATISCHER APP-LINKER                          "
echo "=================================================================="
echo -e "${NC}"

INSTALL_DIR="$(pwd)"
CONFIG_DIR="$INSTALL_DIR/config"

if [ ! -d "$CONFIG_DIR" ]; then
    echo -e "${RED}Fehler: Kein 'config'-Verzeichnis in $INSTALL_DIR gefunden!${NC}"
    echo "Bitte führe dieses Skript direkt im Usenet-Installationsordner aus."
    exit 1
fi

echo -e "${CYAN}▶ Prüfe Erreichbarkeit der APIs & lese Konfigurationen aus...${NC}"

# 1.0 WARTE BIS APIS BEREIT SIND
wait_for_api() {
    local name="$1"
    local port="$2"
    local path="$3"
    local max_wait=30
    local waited=0
    
    printf "  Warte auf %s (Port %s)... " "$name" "$port"
    while ! curl -s --connect-timeout 2 "http://localhost:${port}${path}" &>/dev/null; do
        sleep 2
        waited=$((waited + 2))
        if [ "$waited" -ge "$max_wait" ]; then
            echo -e "${YELLOW}[TIMEOUT - Fahre fort]${NC}"
            return 1
        fi
    done
    echo -e "${GREEN}✓ Bereit!${NC}"
    return 0
}

wait_for_api "Prowlarr" "9696" "/api/v1/system/status" || true
wait_for_api "Sonarr"   "8989" "/api/v3/system/status" || true
wait_for_api "Radarr"   "7878" "/api/v3/system/status" || true

# 2.0 API-KEYS EXTRAHIEREN
extract_xml_key() {
    local file="$1"
    if [ -f "$file" ]; then
        grep -oPm1 "(?<=<ApiKey>)[^<]+" "$file" 2>/dev/null || sed -n 's/.*<ApiKey>\(.*\)<\/ApiKey>.*/\1/p' "$file" 2>/dev/null || true
    fi
}

PROWLARR_KEY=""
SONARR_KEY=""
RADARR_KEY=""

for i in {1..20}; do
    PROWLARR_KEY=$(extract_xml_key "$CONFIG_DIR/prowlarr/config.xml")
    SONARR_KEY=$(extract_xml_key "$CONFIG_DIR/sonarr/config.xml")
    RADARR_KEY=$(extract_xml_key "$CONFIG_DIR/radarr/config.xml")
    if [ -n "$PROWLARR_KEY" ] && [ -n "$SONARR_KEY" ] && [ -n "$RADARR_KEY" ]; then
        break
    fi
    sleep 2
done

if [ -z "$PROWLARR_KEY" ] || [ -z "$SONARR_KEY" ] || [ -z "$RADARR_KEY" ]; then
    echo -e "${RED}Fehler: Konnte nicht alle API-Keys finden.${NC}"
    echo "  Prowlarr Key: ${PROWLARR_KEY:-'FEHLT'}"
    echo "  Sonarr Key:   ${SONARR_KEY:-'FEHLT'}"
    echo "  Radarr Key:   ${RADARR_KEY:-'FEHLT'}"
    echo "Laufen alle Docker-Container? Bitte warte ein paar Sekunden und starte das Skript erneut."
    exit 1
fi

echo -e "${GREEN}✓ Alle Servarr-API-Keys erfolgreich ermittelt.${NC}"

# Downloader erkennen
DOWNLOADER_TYPE=""
if [ -d "$CONFIG_DIR/nzbget" ]; then
    DOWNLOADER_TYPE="nzbget"
elif [ -d "$CONFIG_DIR/sabnzbd" ]; then
    DOWNLOADER_TYPE="sabnzbd"
fi

# 3.0 ROOT FOLDERS IN SONARR & RADARR ANLEGEN
echo -e "\n${CYAN}▶ Richte Medien-Verzeichnisse (Root Folders) ein...${NC}"

# Sonarr: /data/media/tv
EXISTING_SONARR_RF=$(curl -s -H "X-Api-Key: $SONARR_KEY" http://localhost:8989/api/v3/rootfolder 2>/dev/null || true)
if [[ "$EXISTING_SONARR_RF" != *"/data/media/tv"* ]]; then
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $SONARR_KEY" \
        -d '{"path": "/data/media/tv"}' \
        http://localhost:8989/api/v3/rootfolder >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓ Sonarr Root-Folder angelegt: /data/media/tv${NC}"
else
    echo -e "  ${GREEN}✓ Sonarr Root-Folder bereits vorhanden: /data/media/tv${NC}"
fi

# Radarr: /data/media/movies
EXISTING_RADARR_RF=$(curl -s -H "X-Api-Key: $RADARR_KEY" http://localhost:7878/api/v3/rootfolder 2>/dev/null || true)
if [[ "$EXISTING_RADARR_RF" != *"/data/media/movies"* ]]; then
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $RADARR_KEY" \
        -d '{"path": "/data/media/movies"}' \
        http://localhost:7878/api/v3/rootfolder >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓ Radarr Root-Folder angelegt: /data/media/movies${NC}"
else
    echo -e "  ${GREEN}✓ Radarr Root-Folder bereits vorhanden: /data/media/movies${NC}"
fi

# 4.0 APPS IN PROWLARR REGISTRIEREN
echo -e "\n${CYAN}▶ Verknüpfe Sonarr & Radarr mit Prowlarr...${NC}"

EXISTING_PROWLARR_APPS=$(curl -s -H "X-Api-Key: $PROWLARR_KEY" http://localhost:9696/api/v1/applications 2>/dev/null || true)

# Sonarr in Prowlarr
if [[ "$EXISTING_PROWLARR_APPS" != *"Sonarr"* ]]; then
    SONARR_PAYLOAD=$(cat <<EOF
{
  "name": "Sonarr",
  "syncLevel": "fullSync",
  "enable": true,
  "implementation": "Sonarr",
  "implementationName": "Sonarr",
  "configContract": "SonarrSettings",
  "fields": [
    {"name": "prowlarrUrl", "value": "http://localhost:9696"},
    {"name": "baseUrl", "value": "http://localhost:8989"},
    {"name": "apiKey", "value": "${SONARR_KEY}"},
    {"name": "syncCategories", "value": [5000, 5010, 5020, 5030, 5040, 5045, 5050, 5090]},
    {"name": "animeSyncCategories", "value": [5070]},
    {"name": "syncAnimeStandardFormatSearch", "value": true},
    {"name": "syncRejectBlocklistedTorrentHashesWhileGrabbing", "value": false}
  ]
}
EOF
)
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $PROWLARR_KEY" \
        -d "$SONARR_PAYLOAD" \
        http://localhost:9696/api/v1/applications >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓ Sonarr erfolgreich in Prowlarr eingebunden (fullSync).${NC}"
else
    echo -e "  ${GREEN}✓ Sonarr bereits in Prowlarr vorhanden.${NC}"
fi

# Radarr in Prowlarr
if [[ "$EXISTING_PROWLARR_APPS" != *"Radarr"* ]]; then
    RADARR_PAYLOAD=$(cat <<EOF
{
  "name": "Radarr",
  "syncLevel": "fullSync",
  "enable": true,
  "implementation": "Radarr",
  "implementationName": "Radarr",
  "configContract": "RadarrSettings",
  "fields": [
    {"name": "prowlarrUrl", "value": "http://localhost:9696"},
    {"name": "baseUrl", "value": "http://localhost:7878"},
    {"name": "apiKey", "value": "${RADARR_KEY}"},
    {"name": "syncCategories", "value": [2000, 2010, 2020, 2030, 2040, 2045, 2050, 2060, 2070, 2080, 2090]},
    {"name": "syncRejectBlocklistedTorrentHashesWhileGrabbing", "value": false}
  ]
}
EOF
)
    curl -s -X POST \
        -H "Content-Type: application/json" \
        -H "X-Api-Key: $PROWLARR_KEY" \
        -d "$RADARR_PAYLOAD" \
        http://localhost:9696/api/v1/applications >/dev/null 2>&1 || true
    echo -e "  ${GREEN}✓ Radarr erfolgreich in Prowlarr eingebunden (fullSync).${NC}"
else
    echo -e "  ${GREEN}✓ Radarr bereits in Prowlarr vorhanden.${NC}"
fi

# 5.0 DOWNLOAD CLIENT IN SONARR & RADARR ANBINDEN
echo -e "\n${CYAN}▶ Binde Downloader an Sonarr & Radarr an...${NC}"

if [ "$DOWNLOADER_TYPE" = "nzbget" ]; then
    NZBGET_USER=$(grep -E "^ControlUsername=" "$CONFIG_DIR/nzbget/nzbget.conf" 2>/dev/null | cut -d= -f2 || true)
    NZBGET_PASS=$(grep -E "^ControlPassword=" "$CONFIG_DIR/nzbget/nzbget.conf" 2>/dev/null | cut -d= -f2 || true)
    NZBGET_USER=${NZBGET_USER:-"nzbget"}
    NZBGET_PASS=${NZBGET_PASS:-"tegbzn6789"}

    # Sonarr -> NZBGet (Kategorie: Series)
    EXISTING_SONARR_DC=$(curl -s -H "X-Api-Key: $SONARR_KEY" http://localhost:8989/api/v3/downloadclient 2>/dev/null || true)
    if [[ "$EXISTING_SONARR_DC" != *"NZBGet"* ]]; then
        NZBGET_SONARR_PAYLOAD=$(cat <<EOF
{
  "name": "NZBGet",
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "implementation": "Nzbget",
  "implementationName": "NZBGet",
  "configContract": "NzbgetSettings",
  "fields": [
    {"name": "host", "value": "localhost"},
    {"name": "port", "value": 6789},
    {"name": "useSsl", "value": false},
    {"name": "username", "value": "${NZBGET_USER}"},
    {"name": "password", "value": "${NZBGET_PASS}"},
    {"name": "tvCategory", "value": "Series"}
  ]
}
EOF
)
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $SONARR_KEY" \
            -d "$NZBGET_SONARR_PAYLOAD" \
            http://localhost:8989/api/v3/downloadclient >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓ NZBGet als Download-Client in Sonarr registriert.${NC}"
    else
        echo -e "  ${GREEN}✓ NZBGet bereits in Sonarr registriert.${NC}"
    fi

    # Radarr -> NZBGet (Kategorie: Movies)
    EXISTING_RADARR_DC=$(curl -s -H "X-Api-Key: $RADARR_KEY" http://localhost:7878/api/v3/downloadclient 2>/dev/null || true)
    if [[ "$EXISTING_RADARR_DC" != *"NZBGet"* ]]; then
        NZBGET_RADARR_PAYLOAD=$(cat <<EOF
{
  "name": "NZBGet",
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "implementation": "Nzbget",
  "implementationName": "NZBGet",
  "configContract": "NzbgetSettings",
  "fields": [
    {"name": "host", "value": "localhost"},
    {"name": "port", "value": 6789},
    {"name": "useSsl", "value": false},
    {"name": "username", "value": "${NZBGET_USER}"},
    {"name": "password", "value": "${NZBGET_PASS}"},
    {"name": "movieCategory", "value": "Movies"}
  ]
}
EOF
)
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $RADARR_KEY" \
            -d "$NZBGET_RADARR_PAYLOAD" \
            http://localhost:7878/api/v3/downloadclient >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓ NZBGet als Download-Client in Radarr registriert.${NC}"
    else
        echo -e "  ${GREEN}✓ NZBGet bereits in Radarr registriert.${NC}"
    fi

elif [ "$DOWNLOADER_TYPE" = "sabnzbd" ]; then
    SAB_API_KEY=$(grep -E "^api_key" "$CONFIG_DIR/sabnzbd/sabnzbd.ini" 2>/dev/null | awk -F'=' '{gsub(/[ \t]/, "", $2); print $2}' || true)
    
    # Sonarr -> SABnzbd (Kategorie: tv)
    EXISTING_SONARR_DC=$(curl -s -H "X-Api-Key: $SONARR_KEY" http://localhost:8989/api/v3/downloadclient 2>/dev/null || true)
    if [[ "$EXISTING_SONARR_DC" != *"SABnzbd"* ]]; then
        SAB_SONARR_PAYLOAD=$(cat <<EOF
{
  "name": "SABnzbd",
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "implementation": "Sabnzbd",
  "implementationName": "SABnzbd",
  "configContract": "SabnzbdSettings",
  "fields": [
    {"name": "host", "value": "localhost"},
    {"name": "port", "value": 8080},
    {"name": "useSsl", "value": false},
    {"name": "apiKey", "value": "${SAB_API_KEY}"},
    {"name": "tvCategory", "value": "tv"}
  ]
}
EOF
)
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $SONARR_KEY" \
            -d "$SAB_SONARR_PAYLOAD" \
            http://localhost:8989/api/v3/downloadclient >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓ SABnzbd als Download-Client in Sonarr registriert.${NC}"
    else
        echo -e "  ${GREEN}✓ SABnzbd bereits in Sonarr registriert.${NC}"
    fi

    # Radarr -> SABnzbd (Kategorie: movies)
    EXISTING_RADARR_DC=$(curl -s -H "X-Api-Key: $RADARR_KEY" http://localhost:7878/api/v3/downloadclient 2>/dev/null || true)
    if [[ "$EXISTING_RADARR_DC" != *"SABnzbd"* ]]; then
        SAB_RADARR_PAYLOAD=$(cat <<EOF
{
  "name": "SABnzbd",
  "enable": true,
  "protocol": "usenet",
  "priority": 1,
  "implementation": "Sabnzbd",
  "implementationName": "SABnzbd",
  "configContract": "SabnzbdSettings",
  "fields": [
    {"name": "host", "value": "localhost"},
    {"name": "port", "value": 8080},
    {"name": "useSsl", "value": false},
    {"name": "apiKey", "value": "${SAB_API_KEY}"},
    {"name": "movieCategory", "value": "movies"}
  ]
}
EOF
)
        curl -s -X POST \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $RADARR_KEY" \
            -d "$SAB_RADARR_PAYLOAD" \
            http://localhost:7878/api/v3/downloadclient >/dev/null 2>&1 || true
        echo -e "  ${GREEN}✓ SABnzbd als Download-Client in Radarr registriert.${NC}"
    else
        echo -e "  ${GREEN}✓ SABnzbd bereits in Radarr registriert.${NC}"
    fi
else
    echo -e "  ${YELLOW}Hinweis: Kein aktiver Downloader (nzbget/sabnzbd) im config-Ordner gefunden.${NC}"
fi

echo -e "\n${GREEN}${BOLD}🎉 FERTIG! ALLE MEDIEN-APPS WURDEN ERFOLGREICH VERKNÜPFT!${NC}"
echo -e "Sobald du jetzt in Prowlarr einen Indexer hinterlegst, wird dieser"
echo -e "vollautomatisch und sekundenschnell an Sonarr und Radarr synchronisiert.\n"
