#!/bin/bash

# MARF Memory Mapping Utility
# Generates detailed memory maps and analyzes memory layout

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
    cat << EOF
MARF Memory Mapping Utility
Usage: $(basename $0) [options] <pid|binary>

Options:
    -p, --pid          Analyze running process
    -b, --binary       Analyze binary file
    -o, --output       Output file (default: memory_map.log)
    -f, --format       Output format (text|json|xml)
    -d, --detailed     Include detailed segment analysis
    -h, --help         Show this help message

Examples:
    $(basename $0) -p 1234 -o map.json -f json
    $(basename $0) -b ./target_binary --detailed
EOF
    exit 1
}

# Default values
OUTPUT="memory_map.log"
FORMAT="text"
DETAILED=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--pid)
            PID="$2"
            shift 2
            ;;
        -b|--binary)
            BINARY="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -f|--format)
            FORMAT="$2"
            shift 2
            ;;
        -d|--detailed)
            DETAILED=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            error "Unknown option: $1"
            usage
            ;;
    esac
done

# Analysis functions
analyze_process() {
    local pid="$1"
    info "Analyzing process $pid..."
    
    # Check process exists
    if ! kill -0 "$pid" 2>/dev/null; then
        error "Process $pid not found"
        exit 1
    }
    
    # Gather memory information
    cat /proc/$pid/maps > "$TEMP_DIR/maps"
    cat /proc/$pid/smaps > "$TEMP_DIR/smaps"
    
    if [ $DETAILED -eq 1 ]; then
        # Detailed memory analysis
        analyze_segments "$pid"
        analyze_heap "$pid"
        analyze_stack "$pid"
    fi
}

analyze_binary() {
    local binary="$1"
    info "Analyzing binary $binary..."
    
    # Check binary exists and is executable
    if [ ! -x "$binary" ]; then
        error "Binary $binary not found or not executable"
        exit 1
    }
    
    # Analyze binary segments
    readelf -a "$binary" > "$TEMP_DIR/segments"
    objdump -d "$binary" > "$TEMP_DIR/disasm"
    
    if [ $DETAILED -eq 1 ]; then
        # Detailed binary analysis
        analyze_sections "$binary"
        analyze_symbols "$binary"
        analyze_relocations "$binary"
    fi
}

analyze_segments() {
    local pid="$1"
    info "Analyzing memory segments..."
    
    # Process memory maps
    awk '
    BEGIN { print "=== Memory Segments ===" }
    {
        split($1,addr,"-")
        size = strtonum("0x" addr[2]) - strtonum("0x" addr[1])
        printf "Address: %s\nSize: %d bytes\nPerms: %s\nMapping: %s\n\n",
               $1, size, $2, $NF
    }
    ' "$TEMP_DIR/maps" > "$TEMP_DIR/segment_analysis"
}

generate_output() {
    info "Generating $FORMAT output..."
    
    case "$FORMAT" in
        json)
            generate_json_output
            ;;
        xml)
            generate_xml_output
            ;;
        text|*)
            generate_text_output
            ;;
    esac
}

main() {
    banner "MARF Memory Mapping"
    
    # Validate input
    if [ -z "$PID" ] && [ -z "$BINARY" ]; then
        error "Must specify either PID or binary"
        usage
    fi
    
    # Create temporary directory
    setup_temp_dir
    
    # Perform analysis
    if [ -n "$PID" ]; then
        analyze_process "$PID"
    else
        analyze_binary "$BINARY"
    fi
    
    # Generate output
    generate_output
    
    # Cleanup
    cleanup
    
    info "Analysis complete. Results saved to $OUTPUT"
}

main "$@"