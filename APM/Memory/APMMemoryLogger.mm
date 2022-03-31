//
//  APMMemoryLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMemoryLogger.h"
#import "APMMallocManager.h"

extern APMMallocManager *g_apmMallocManager;

/// malloc_logger 回调
/// @param type malloc, realloc, etc... + NSZoneMalloc
/// @param arg1 malloc_zone_t 地址
/// @param arg2 size
/// @param arg3 0
/// @param result = malloc_zone_t->malloc(zone, size) 返回开辟的内存地址
/// @param backtrace_to_skip 0
void apmMemoryLogger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    if (type & stack_logging_flag_zone) {
        type &= ~stack_logging_flag_zone;
    }
    
    if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        g_apmMallocManager->recordMallocStack(result, (uint32_t)arg2, backtrace_to_skip);
    } else if ((type & stack_logging_type_dealloc) == stack_logging_type_dealloc) {
        g_apmMallocManager->removeMallocStack(result);
    }
}
