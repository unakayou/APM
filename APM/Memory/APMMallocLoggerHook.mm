//
//  APMMallocLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMallocLoggerHook.h"
#import "APMMallocManager.h"
#import "APMLeakManager.h"
#import "APMDefines.h"

extern APMMallocManager *g_apmMallocManager;
extern APMLeakManager *g_apmLeakManager;

void startMallocLogger(void) {
    // 重复设置大可不必
    if ((malloc_logger_t *)apm_malloc_logger == malloc_logger) {
        return;
    }
    
    // 保存之前的malloc_logger
    if (malloc_logger && malloc_logger != apm_malloc_logger) {
        g_apm_pre_malloc_logger = malloc_logger;
    }
    
    // 指向新函数
    malloc_logger = (malloc_logger_t *)apm_malloc_logger;
}

void stopMallocLogger(void) {
    // 还原malloc_logger
    malloc_logger = g_apm_pre_malloc_logger;
}

/// ⚠️ 记录关键逻辑
/// libmalloc 源码中判断了malloc_logger 是否存在，如果存在，则调用对应的方法
/// malloc_logger 回调
/// @param type malloc, realloc, etc... + NSZoneMalloc
/// @param arg1 malloc_zone_t 地址
/// @param arg2 size (realloc时: 原本开辟地址, free时: 释放的地址)
/// @param arg3 0     (realloc时: size)
/// @param result = malloc_zone_t->malloc(zone, size) 返回新开辟的内存地址
/// @param backtrace_to_skip 0
void apm_malloc_logger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    if (g_apm_pre_malloc_logger != NULL) {
        g_apm_pre_malloc_logger(type, arg1, arg2, arg3, result, backtrace_to_skip);
    }
    
    // 消除共同项
    if (type & stack_logging_flag_zone) {
        type &= ~stack_logging_flag_zone;
    }

    // 统计Malloc (0.002 ms / 次 - 0.015 ms / 次)
    if (g_apmMallocManager != NULL && g_apmMallocManager->enableTracking) {
        apmMemoryLogger(type, arg1, arg2, arg3, result, backtrace_to_skip);
    }
    
    // 泄漏统计
    if (g_apmLeakManager != NULL && g_apmLeakManager->enableTracking) {
        apm_Leak_logger(type, arg1, arg2, arg3, result, backtrace_to_skip);
    }
}
