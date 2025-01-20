#include "memory_utils.h"
#include <fcntl.h>
#include <sys/stat.h>

memory_range_t* get_memory_ranges(size_t* count) {
    FILE* maps = fopen("/proc/self/maps", "r");
    if (!maps) {
        *count = 0;
        return NULL;
    }

    memory_range_t* ranges = malloc(sizeof(memory_range_t) * MAX_RANGES);
    if (!ranges) {
        fclose(maps);
        *count = 0;
        return NULL;
    }

    char line[512];
    size_t n = 0;

    while (fgets(line, sizeof(line), maps) && n < MAX_RANGES) {
        unsigned long start, end;
        char perms[5];
        
        if (sscanf(line, "%lx-%lx %4s", &start, &end, perms) == 3) {
            ranges[n].start = start;
            ranges[n].end = end;
            strncpy(ranges[n].permissions, perms, 4);
            ranges[n].permissions[4] = '\0';
            
            // Extract module name if present
            char* module = strchr(line, '/');
            if (module) {
                size_t len = strlen(module);
                if (len > 0 && module[len-1] == '\n') {
                    module[len-1] = '\0';
                }
                strncpy(ranges[n].module, module, sizeof(ranges[n].module)-1);
            } else {
                ranges[n].module[0] = '\0';
            }
            
            n++;
        }
    }

    fclose(maps);
    *count = n;
    return ranges;
}

void create_pattern(unsigned char* buffer, pattern_options_t* options) {
    if (!buffer || !options || options->length == 0) return;

    if (options->random) {
        for (size_t i = 0; i < options->length; i++) {
            buffer[i] = rand() & 0xFF;
        }
    } else if (options->cyclic) {
        for (size_t i = 0; i < options->length; i++) {
            buffer[i] = 'A' + (i % 26);
        }
    } else {
        // Default pattern
        static const unsigned char default_pattern[] = {
            0x90, 0x90, 0x90, 0x90,  // NOP sled
            0xCC, 0xCC, 0xCC, 0xCC   // INT3 breakpoints
        };
        
        for (size_t i = 0; i < options->length; i++) {
            buffer[i] = default_pattern[i % sizeof(default_pattern)];
        }
    }
}

analysis_result_t analyze_memory_layout(void) {
    analysis_result_t result = {0};
    size_t count;
    memory_range_t* ranges = get_memory_ranges(&count);

    if (!ranges) return result;

    // Find stack region
    for (size_t i = 0; i < count; i++) {
        if (strstr(ranges[i].module, "[stack]")) {
            result.stack_base = ranges[i].start;
            result.stack_size = ranges[i].end - ranges[i].start;
            break;
        }
    }

    // Analyze protections
    if (result.stack_base) {
        result.protection_flags = 0;
        if (strchr(ranges[count-1].permissions, 'r')) result.protection_flags |= PROT_READ;
        if (strchr(ranges[count-1].permissions, 'w')) result.protection_flags |= PROT_WRITE;
        if (strchr(ranges[count-1].permissions, 'x')) result.protection_flags |= PROT_EXEC;
    }

    free(ranges);
    return result;
}

void hexdump(void* ptr, size_t len) {
    unsigned char* buf = (unsigned char*)ptr;
    for (size_t</antArtifact>