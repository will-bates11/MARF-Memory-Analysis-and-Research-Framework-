#!/bin/bash

# MARF Common Utilities
# Shared functions and utilities for analysis scripts

# Colors and formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Temporary directory
TEMP_DIR="/tmp/marf_analysis_$$"

# Logging functions
info() {
    echo -e "${BLUE}[*]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1" >&2
}

error() {
    echo -e "${RED}[-]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[+]${NC} $1"
}

# Banner display
banner() {
    local text="$1"
    local width=50
    local padding=$(( (width - ${#text}) / 2 ))
    
    echo
    printf "%${width}s\n" | tr ' ' '='
    printf "%${padding}s%s%${padding}s\n" "" "$text" ""
    printf "%${width}s\n" | tr ' ' '='
    echo
}

# Environment setup
setup_temp_dir() {
    mkdir -p "$TEMP_DIR"
    trap cleanup EXIT
}

cleanup() {
    [ -d "$TEMP_DIR" ] && rm -rf "$TEMP_DIR"
}

# Tool checking
check_tool() {
    local tool="$1"
    if ! command -v "$tool" >/dev/null 2>&1; then
        error "Required tool '$tool' not found"
        exit 1
    fi
}

# Output generation
generate_text_output() {
    {
        echo "=== MARF Analysis Report ==="
        echo "Date: $(date)"
        echo "Target: ${PID:-$BINARY}"
        echo
        
        if [ -f "$TEMP_DIR/segment_analysis" ]; then
            cat "$TEMP_DIR/segment_analysis"
        fi
        
        if [ -f "$TEMP_DIR/maps" ]; then
            echo "=== Memory Maps ==="
            cat "$TEMP_DIR/maps"
        fi
        
        if [ -f "$TEMP_DIR/segments" ]; then
            echo "=== Binary Segments ==="
            cat "$TEMP_DIR/segments"
        fi
        
        echo "=== End of Report ==="
    } > "$OUTPUT"
}

generate_json_output() {
    {
        echo "{"
        echo "  \"analysis\": {"
        echo "    \"date\": \"$(date -Iseconds)\","
        echo "    \"target\": \"${PID:-$BINARY}\","
        
        if [ -f "$TEMP_DIR/maps" ]; then
            echo "    \"memory_maps\": ["
            awk -F' ' '
            {
                printf "      {\n"
                printf "        \"address\": \"%s\",\n", $1
                printf "        \"permissions\": \"%s\",\n", $2
                printf "        \"mapping\": \"%s\"\n", $NF
                printf "      }%s\n", (NR==NR?"":",")
            }
            ' "$TEMP_DIR/maps"
            echo "    ]"
        fi
        
        echo "  }"
        echo "}"
    } > "$OUTPUT"
}

generate_xml_output() {
    {
        echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>"
        echo "<marf_analysis>"
        echo "  <metadata>"
        echo "    <date>$(date -Iseconds)</date>"
        echo "    <target>${PID:-$BINARY}</target>"
        echo "  </metadata>"
        
        if [ -f "$TEMP_DIR/maps" ]; then
            echo "  <memory_maps>"
            awk -F' ' '
            {
                printf "    <segment>\n"
                printf "      <address>%s</address>\n", $1
                printf "      <permissions>%s</permissions>\n", $2
                printf "      <mapping>%s</mapping>\n", $NF
                printf "    </segment>\n"
            }
            ' "$TEMP_DIR/maps"
            echo "  </memory_maps>"
        fi
        
        echo "</marf_analysis>"
    } > "$OUTPUT"
}

# Utility functions
get_page_size() {
    getconf PAGE_SIZE
}

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        warning "Some operations may require root privileges"
        return 1
    fi
    return 0
}

parse_address() {
    local addr="$1"
    printf "%d" "0x$addr"
}

human_size() {
    local bytes="$1"
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$((bytes/1024))K"
    else
        echo "$((bytes/1048576))M"
    fi
}