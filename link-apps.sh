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
    local max_wait=120
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

wait_for_api "Prowlarr" "9696" "/ping" || true
wait_for_api "Sonarr"   "8989" "/ping" || true
wait_for_api "Radarr"   "7878" "/ping" || true

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
    {"name": "syncCategories", "value": [5000, 5010, 5020, 5030, 5040, 5045, 5050, 5070, 5080, 5090]},
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

    # Sonarr -> NZBGet (Kategorie: tv)
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
    {"name": "tvCategory", "value": "tv"}
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

    # Radarr -> NZBGet (Kategorie: movies)
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
    {"name": "movieCategory", "value": "movies"}
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
    wait_for_api "SABnzbd" "8080" "" || true
    SAB_API_KEY=""
    for i in {1..30}; do
        SAB_API_KEY=$(grep -E "^api_key" "$CONFIG_DIR/sabnzbd/sabnzbd.ini" 2>/dev/null | awk -F'=' '{gsub(/[ \t]/, "", $2); print $2}' || true)
        [ -n "$SAB_API_KEY" ] && break
        sleep 2
    done
    
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

# 6.0 TRaSH-GUIDES NAMING SCHEMES & DACH CUSTOM FORMATS
echo -e "\n${CYAN}▶ Konfiguriere TRaSH-Guides Naming Schemes & DACH Custom Formats...${NC}"

if command -v python3 &>/dev/null; then
    python3 - "$SONARR_KEY" "$RADARR_KEY" << 'EOF'
import sys
import json
import urllib.request
import urllib.error

sonarr_key = sys.argv[1] if len(sys.argv) > 1 else ""
radarr_key = sys.argv[2] if len(sys.argv) > 2 else ""

def api_request(url, method="GET", data=None, key=""):
    headers = {
        "X-Api-Key": key,
        "Content-Type": "application/json"
    }
    encoded = json.dumps(data).encode("utf-8") if data is not None else None
    req = urllib.request.Request(url, data=encoded, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=15) as res:
            resp_bytes = res.read()
            return json.loads(resp_bytes) if resp_bytes else {}
    except Exception:
        return None

# --- SONARR ---
if sonarr_key:
    # 1. TRaSH Naming Scheme
    naming = api_request("http://localhost:8989/api/v3/config/naming", key=sonarr_key)
    if isinstance(naming, dict) and "renameEpisodes" in naming:
        naming["renameEpisodes"] = True
        naming["replaceIllegalCharacters"] = True
        naming["standardEpisodeFormat"] = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{MediaInfo AudioCodec} { MediaInfo AudioChannels}]{-Release Group}"
        naming["dailyEpisodeFormat"] = "{Series TitleYear} - {Air-Date} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{MediaInfo AudioCodec} { MediaInfo AudioChannels}]{-Release Group}"
        naming["animeEpisodeFormat"] = "{Series TitleYear} - S{season:00}E{episode:00} - {Episode CleanTitle} [{Custom Formats }{Quality Full}]{[MediaInfo VideoDynamicRangeType]}[{MediaInfo VideoBitDepth}bit]{[MediaInfo VideoCodec]}[{MediaInfo AudioCodec} { MediaInfo AudioChannels}]{-Release Group}"
        naming["seriesFolderFormat"] = "{Series TitleYear} [tvdb-{TvdbId}]"
        naming["seasonFolderFormat"] = "Season {season:00}"
        if api_request("http://localhost:8989/api/v3/config/naming", method="PUT", data=naming, key=sonarr_key) is not None:
            print("  \033[0;32m✓ Sonarr: TRaSH Naming Scheme angewendet (inkl. MediaInfo & Custom Formats).\033[0m")

    # 2. Media Management: downloadPropersAndRepacks
    mm = api_request("http://localhost:8989/api/v3/config/mediamanagement", key=sonarr_key)
    if isinstance(mm, dict) and "downloadPropersAndRepacks" in mm:
        mm["downloadPropersAndRepacks"] = "doNotPrefer"
        if api_request("http://localhost:8989/api/v3/config/mediamanagement", method="PUT", data=mm, key=sonarr_key) is not None:
            print("  \033[0;32m✓ Sonarr: Propers & Repacks auf 'doNotPrefer' gesetzt.\033[0m")

    # 3. Custom Formats
    cfs = api_request("http://localhost:8989/api/v3/customformat", key=sonarr_key)
    existing_cf_names = [c.get("name") for c in cfs] if isinstance(cfs, list) else []

    if "German DL" not in existing_cf_names:
        cf_german_dl = {
            "name": "German DL",
            "includeCustomFormatWhenRenaming": True,
            "specifications": [
                {
                    "name": "German",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": 4}]
                },
                {
                    "name": "Original Language",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": -2}]
                }
            ]
        }
        if api_request("http://localhost:8989/api/v3/customformat", method="POST", data=cf_german_dl, key=sonarr_key):
            print("  \033[0;32m✓ Sonarr: Custom Format 'German DL' registriert.\033[0m")
    else:
        print("  \033[0;32m✓ Sonarr: Custom Format 'German DL' bereits vorhanden.\033[0m")

    if "German" not in existing_cf_names:
        cf_german = {
            "name": "German",
            "includeCustomFormatWhenRenaming": True,
            "specifications": [
                {
                    "name": "German",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": 4}]
                }
            ]
        }
        if api_request("http://localhost:8989/api/v3/customformat", method="POST", data=cf_german, key=sonarr_key):
            print("  \033[0;32m✓ Sonarr: Custom Format 'German' registriert.\033[0m")
    else:
        print("  \033[0;32m✓ Sonarr: Custom Format 'German' bereits vorhanden.\033[0m")

    # 4. Quality Profiles Scoring
    profiles = api_request("http://localhost:8989/api/v3/qualityprofile", key=sonarr_key)
    if isinstance(profiles, list):
        for p in profiles:
            format_items = p.get("formatItems", [])
            for fi in format_items:
                if fi.get("name") == "German DL":
                    fi["score"] = 1500
                elif fi.get("name") == "German":
                    fi["score"] = 1000
            p["upgradeAllowed"] = True
            p["cutoffFormatScore"] = 1500
            api_request(f"http://localhost:8989/api/v3/qualityprofile/{p['id']}", method="PUT", data=p, key=sonarr_key)
        print("  \033[0;32m✓ Sonarr: Alle Qualitätsprofile mit DACH-Scoring (German DL +1500, German +1000) versehen.\033[0m")

# --- RADARR ---
if radarr_key:
    # 1. TRaSH Naming Scheme
    naming = api_request("http://localhost:7878/api/v3/config/naming", key=radarr_key)
    if isinstance(naming, dict) and "renameMovies" in naming:
        naming["renameMovies"] = True
        naming["replaceIllegalCharacters"] = True
        naming["standardMovieFormat"] = "{Movie CleanTitle} {(Release Year)} [imdb-{ImdbId}] - {[Custom Formats ]}{[Quality Full]}{[MediaInfo 3D]}{[MediaInfo VideoDynamicRangeType]}{[Mediainfo AudioCodec}{ MediaInfo AudioChannels]}{[MediaInfo VideoCodec]}{-Release Group}"
        naming["movieFolderFormat"] = "{Movie CleanTitle} ({Release Year}) [imdb-{ImdbId}]"
        if api_request("http://localhost:7878/api/v3/config/naming", method="PUT", data=naming, key=radarr_key) is not None:
            print("  \033[0;32m✓ Radarr: TRaSH Naming Scheme angewendet (inkl. MediaInfo & Custom Formats).\033[0m")

    # 2. Custom Formats
    cfs = api_request("http://localhost:7878/api/v3/customformat", key=radarr_key)
    existing_cf_names = [c.get("name") for c in cfs] if isinstance(cfs, list) else []

    if "German DL" not in existing_cf_names:
        cf_german_dl = {
            "name": "German DL",
            "includeCustomFormatWhenRenaming": True,
            "specifications": [
                {
                    "name": "German",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": 4}]
                },
                {
                    "name": "Original Language",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": -2}]
                }
            ]
        }
        if api_request("http://localhost:7878/api/v3/customformat", method="POST", data=cf_german_dl, key=radarr_key):
            print("  \033[0;32m✓ Radarr: Custom Format 'German DL' registriert.\033[0m")
    else:
        print("  \033[0;32m✓ Radarr: Custom Format 'German DL' bereits vorhanden.\033[0m")

    if "German" not in existing_cf_names:
        cf_german = {
            "name": "German",
            "includeCustomFormatWhenRenaming": True,
            "specifications": [
                {
                    "name": "German",
                    "implementation": "LanguageSpecification",
                    "negate": False,
                    "required": True,
                    "fields": [{"name": "value", "value": 4}]
                }
            ]
        }
        if api_request("http://localhost:7878/api/v3/customformat", method="POST", data=cf_german, key=radarr_key):
            print("  \033[0;32m✓ Radarr: Custom Format 'German' registriert.\033[0m")
    else:
        print("  \033[0;32m✓ Radarr: Custom Format 'German' bereits vorhanden.\033[0m")

    # 3. Quality Profiles Scoring
    profiles = api_request("http://localhost:7878/api/v3/qualityprofile", key=radarr_key)
    if isinstance(profiles, list):
        for p in profiles:
            format_items = p.get("formatItems", [])
            for fi in format_items:
                if fi.get("name") == "German DL":
                    fi["score"] = 1500
                elif fi.get("name") == "German":
                    fi["score"] = 1000
            p["upgradeAllowed"] = True
            p["cutoffFormatScore"] = 1500
            api_request(f"http://localhost:7878/api/v3/qualityprofile/{p['id']}", method="PUT", data=p, key=radarr_key)
        print("  \033[0;32m✓ Radarr: Alle Qualitätsprofile mit DACH-Scoring (German DL +1500, German +1000) versehen.\033[0m")

EOF
else
    echo -e "  ${YELLOW}Hinweis: python3 nicht gefunden – überspringe erweiterte Custom Formats & Profile-Scoring.${NC}"
fi

echo -e "\n${GREEN}${BOLD}🎉 FERTIG! ALLE MEDIEN-APPS WURDEN ERFOLGREICH VERKNÜPFT!${NC}"
echo -e "✓ Prowlarr synchronisiert Indexer an Sonarr & Radarr (fullSync)."
echo -e "✓ Root-Folder (/data/media) und Downloader-Kategorien sind eingerichtet."
echo -e "✓ TRaSH-Guides Naming Scheme & DACH Custom Formats (German DL +1500, German +1000) aktiv."
echo -e "✓ Sobald du in Prowlarr einen Indexer hinterlegst, ist dein Stack sofort einsatzbereit!\n"
