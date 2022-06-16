//
//  APMLeakLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMLeakLogger.h"
#import "APMLeakManager.h"

extern APMLeakManager *g_apmLeakManager;

/// @param type malloc, realloc, etc... + NSZoneMalloc
/// @param arg1 malloc_zone_t 地址
/// @param arg2 size (realloc时: 原本开辟地址, free时: 释放的地址)
/// @param arg3 0     (realloc时: size)
/// @param result = malloc_zone_t->malloc(zone, size) 返回新开辟的内存地址
/// @param backtrace_to_skip 0
void apm_Leak_logger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    
    // realloc
    if (type == (stack_logging_type_dealloc | stack_logging_type_alloc)) {
        if (arg2 == result) return;
        
        if (!arg2) {
            if (g_apmLeakManager->isLeakChecking != true) {
                g_apmLeakManager->recordMallocStack(result, (uint32_t)arg3, "realloc", 5);
            }
        } else {
            g_apmLeakManager->removeMallocStack(arg2);
            if (g_apmLeakManager->isLeakChecking != true) {
                g_apmLeakManager->recordMallocStack(result, (uint32_t)arg3, "realloc", 5);
            }
        }
    } else if (type == stack_logging_type_dealloc) {
        if (!arg2) return;
        g_apmLeakManager->removeMallocStack((vm_address_t)arg2);
    } else if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        if (g_apmLeakManager->isLeakChecking != true) {
            g_apmLeakManager->recordMallocStack(result, (uint32_t)arg2, "malloc", 5);
        }
    }
}
