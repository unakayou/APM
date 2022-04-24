//
//  APMLeakLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMLeakLogger.h"
#import "APMLeakManager.h"

extern APMLeakManager *g_apmLeakManager;
void apm_Leak_logger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    if (arg1 == g_apmLeakManager->getMemoryZone()) {
        return;
    }
    
    if (type == (stack_logging_type_dealloc | stack_logging_type_alloc)) {
        g_apmLeakManager->removeMallocStack(arg2);
        g_apmLeakManager->recordMallocStack(result, (uint32_t)arg3, NULL, backtrace_to_skip);
    } else if (type == stack_logging_type_dealloc) {
        g_apmLeakManager->removeMallocStack(arg2);
    } else if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        g_apmLeakManager->recordMallocStack(result, (uint32_t)arg2, NULL,backtrace_to_skip);
    }
}
