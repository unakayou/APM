//
//  APMMemoryLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMemoryLogger.h"
#import "APMMallocManager.h"

extern APMMallocManager *g_apmMallocManager;

void apmMemoryLogger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    if (type == (stack_logging_type_dealloc | stack_logging_type_alloc)) {
        // realloc(), result:新地址 ar2:旧地址 arg3:size
        g_apmMallocManager->removeMallocStack(arg2);
        g_apmMallocManager->recordMallocStack(result, (uint32_t)arg3, backtrace_to_skip);
    } else if (type == stack_logging_type_dealloc) {
        // free(), arg2:旧地址
        g_apmMallocManager->removeMallocStack(arg2);
    } else if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        // malloc(), result:新地址 arg2:size
        g_apmMallocManager->recordMallocStack(result, (uint32_t)arg2, backtrace_to_skip);
    }
}
