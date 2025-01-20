#include "memory_utils.h"
#include <getopt.h>
#include <time.h>

#define VERSION "1.0.0"
#define PATTERN_SIZE 4096
#define MAX_RANGES 1024

static void print_usage(const char* program) {
    fprintf(stderr, "MARF - Memory Analysis Research Framework v%s\n", VERSION);
    fprintf(stderr, "Usage: %s [options] command\n\n", program);
    fprintf(stderr, "Commands:\n");
    fprintf(stderr, "  analyze     Analyze memory layout\n");
    fprintf(stderr, "  pattern     Generate memory pattern\n");
    fprintf(stderr, "  map         Generate memory map\n");
    fprintf(stderr, "  verify      Verify memory access\n\n");
    fprintf(stderr, "Options:\n");
    fprintf(stderr, "  -o, --output <file>    Output file\n");
    fprintf(stderr, "  -s, --size <size>      Pattern size\n");
    fprintf(stderr, "  -r, --random           Use random pattern\n");
    fprintf(stderr, "  -c, --cyclic           Use cyclic pattern\n");
    fprintf(stderr, "  -v, --verbose          Verbose output\n");
    fprintf(stderr, "  -h, --help             Show this help\n");
}

static void generate_cyclic_pattern(unsigned char* buffer, size_t size) {
    const char charset[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                          "abcdefghijklmnopqrstuvwxyz"
                          "0123456789";
    const size_t charset_len = strlen(charset);
    
    for (size_t i = 0; i < size; i++) {
        buffer[i] = charset[i % charset_len];
    }
}

static void perform_memory_analysis(const char* outfile, int verbose) {
    analysis_result_t result = analyze_memory_layout();
    
    if (verbose) {
        printf("Stack base: 0x%lx\n", result.stack_base);
        printf("Stack size: %lu bytes\n", result.stack_size);
        printf("Target address: 0x%lx\n", result.target_addr);
        printf("Offset: %zu\n", result.offset);
        printf("Protection flags: %d\n", result.protection_flags);
    }
    
    if (outfile) {
        FILE* f = fopen(outfile, "w");
        if (f) {
            fprintf(f, "MEMORY ANALYSIS REPORT\n");
            fprintf(f, "--------------------\n");
            fprintf(f, "Stack base: 0x%lx\n", result.stack_base);
            fprintf(f, "Stack size: %lu bytes\n", result.stack_size);
            fprintf(f, "Target address: 0x%lx\n", result.target_addr);
            fprintf(f, "Offset: %zu\n", result.offset);
            fprintf(f, "Protection flags: %d\n", result.protection_flags);
            fclose(f);
        }
    }
}

int main(int argc, char* argv[]) {
    static struct option long_options[] = {
        {"output", required_argument, 0, 'o'},
        {"size",   required_argument, 0, 's'},
        {"random", no_argument,       0, 'r'},
        {"cyclic", no_argument,       0, 'c'},
        {"verbose", no_argument,      0, 'v'},
        {"help",    no_argument,      0, 'h'},
        {0, 0, 0, 0}
    };

    char* outfile = NULL;
    size_t pattern_size = PATTERN_SIZE;
    int random_pattern = 0;
    int cyclic_pattern = 0;
    int verbose = 0;

    int opt;
    while ((opt = getopt_long(argc, argv, "o:s:rcvh", long_options, NULL)) != -1) {
        switch (opt) {
            case 'o': outfile = optarg; break;
            case 's': pattern_size = atoi(optarg); break;
            case 'r': random_pattern = 1; break;
            case 'c': cyclic_pattern = 1; break;
            case 'v': verbose = 1; break;
            case 'h': print_usage(argv[0]); return 0;
            default: print_usage(argv[0]); return 1;
        }
    }

    if (optind >= argc) {
        print_usage(argv[0]);
        return 1;
    }

    const char* command = argv[optind];

    if (strcmp(command, "analyze") == 0) {
        perform_memory_analysis(outfile, verbose);
    }
    else if (strcmp(command, "pattern") == 0) {
        unsigned char* buffer = malloc(pattern_size);
        if (!buffer) {
            perror("Failed to allocate memory");
            return 1;
        }

        pattern_options_t options = {
            .length = pattern_size,
            .pattern = buffer,
            .cyclic = cyclic_pattern,
            .random = random_pattern
        };

        create_pattern(buffer, &options);

        if (outfile) {
            FILE* f = fopen(outfile, "wb");
            if (f) {
                fwrite(buffer, 1, pattern_size, f);
                fclose(f);
            }
        } else {
            hexdump(buffer, pattern_size);
        }

        free(buffer);
    }
    else if (strcmp(command, "map") == 0) {
        generate_memory_map(outfile);
    }
    else if (strcmp(command, "verify") == 0) {
        if (optind + 1 >= argc) {
            fprintf(stderr, "Error: verify command requires an address\n");
            return 1;
        }
        unsigned long addr = strtoul(argv[optind + 1], NULL, 16);
        if (is_address_mapped(addr)) {
            printf("Address 0x%lx is mapped\n", addr);
        } else {
            printf("Address 0x%lx is not mapped\n", addr);
        }
    }
    else {
        fprintf(stderr, "Unknown command: %s\n", command);
        return 1;
    }

    return 0;
}