#ifndef MEMORY_UTILS_H
#define MEMORY_UTILS_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <stdint.h>
#include <errno.h>

// Memory range structure
typedef struct {
    unsigned long start;
    unsigned long end;
    unsigned char permissions[5];
    char module[256];
} memory_range_t;

// Pattern generation options
typedef struct {
    size_t length;
    unsigned char* pattern;
    int cyclic;
    int random;
} pattern_options_t;

// Memory analysis results
typedef struct {
    unsigned long stack_base;
    unsigned long stack_size;
    unsigned long target_addr;
    size_t offset;
    int protection_flags;
} analysis_result_t;

// Function declarations
memory_range_t* get_memory_ranges(size_t* count);
void create_pattern(unsigned char* buffer, pattern_options_t* options);
analysis_result_t analyze_memory_layout(void);
int verify_memory_access(void* addr, size_t len, int prot);
void dump_memory_region(void* start, size_t len, const char* outfile);
unsigned long find_base_address(const char* module);
int is_address_mapped(unsigned long addr);
void generate_memory_map(const char* outfile);

// Utility functions
unsigned long align_address(unsigned long addr, size_t alignment);
int set_memory_protection(void* addr, size_t len, int prot);
void hexdump(void* ptr, size_t len);

#endif // MEMORY_UTILS_H