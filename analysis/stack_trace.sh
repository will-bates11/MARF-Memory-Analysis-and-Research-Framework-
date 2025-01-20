#!/bin/bash

# MARF Stack Analysis Utility
# Provides detailed stack tracing and analysis capabilities

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common.sh"

usage() {
    cat << EOF
MARF Stack Trace Utility
Usage: $(basename $0) [options] <binary>

Options:
    -d, --depth <n>     Analysis depth (default: 50)
    -o, --output <file> Output file (default: stack_trace.log)
    -v, --verbose       Verbose output
    -f, --follow        Follow child processes
    -h, --help         Show this help message

Examples:
    $(basename $0) -d 100 ./target_binary
    $(basename $0) -o analysis.log --verbose ./target_binary
EOF
    exit 1
}

# Default values
DEPTH=50
OUTPUT="stack_trace.log"
VERBOSE=0
FOLLOW=0

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--depth)
            DEPTH="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -f|--follow)
            FOLLOW=1
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            BINARY="$1"
            shift
            ;;
    esac
done

# Validate input
if [ -z "$BINARY" ]; then
    error "No binary specified"
    usage
fi

if [ ! -x "$BINARY" ]; then
    error "Binary '$BINARY' not found or not executable"
    exit 1
fi

# Setup analysis environment
setup_analysis_env() {
    info "Setting up analysis environment..."
    mkdir -p "$(dirname "$OUTPUT")"
    
    # Check for required tools
    check_tool "gdb"
    check_tool "addr2line"
    check_tool "nm"
    
    # Create GDB script
    cat > "$TEMP_DIR/gdb_script" << EOF
set pagination off
set logging on $OUTPUT
set logging overwrite on

# Break at main
break main
run

# Analyze stack frame
define print_frame_info
    printf "Frame %d: %s\n", \$arg0, \$pc
    info frame
    info locals
    info args
end

# Stack trace command
define analyze_stack
    set \$i = 0
    while \$i < $DEPTH
        select-frame \$i
        print_frame_info \$i
        up-silently
        set \$i = \$i + 1
    end
end

analyze_stack
quit
EOF
}

# Perform stack analysis
analyze_stack() {
    info "Starting stack analysis..."
    
    # Run GDB analysis
    if [ $VERBOSE -eq 1 ]; then
        gdb -q -x "$TEMP_DIR/gdb_script" "$BINARY"
    else
        gdb -q -x "$TEMP_DIR/gdb_script" "$BINARY" > /dev/null 2>&1
    fi
    
    # Post-process results
    info "Processing analysis results..."
    {
        echo "=== MARF Stack Analysis Report ==="
        echo "Binary: $BINARY"
        echo "Date: $(date)"
        echo "Depth: $DEPTH"
        echo "=== Stack Trace ==="
        cat "$OUTPUT"
        echo "=== End of Report ==="
    } > "$OUTPUT.tmp"
    mv "$OUTPUT.tmp" "$OUTPUT"
}

# Main execution
main() {
    banner "MARF Stack Analysis"
    
    setup_analysis_env
    analyze_stack
    
    if [ $FOLLOW -eq 1 ]; then
        info "Following child processes..."
        # Implementation for child process tracking
    fi
    
    cleanup
    info "Analysis complete. Results saved to $OUTPUT"
}

main "$@"