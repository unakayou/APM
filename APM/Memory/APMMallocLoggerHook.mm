//
//  APMMallocLogger.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMallocLoggerHook.h"
#import "APMMallocManager.h"
#import "APMDefines.h"

malloc_zone_t *g_apmHashmapZone;
extern APMMallocManager *g_apmMallocManager;

void startMallocLogger(void) {
    // 保存之前的malloc_logger
    if (malloc_logger && malloc_logger != apmMallocLoggerHook) {
        g_apmPreMallocLogger = malloc_logger;
    }
    malloc_logger = (malloc_logger_t *)apmMallocLoggerHook;
}

void stopMallocLogger(void) {
    // 还原malloc_logger
    malloc_logger = g_apmPreMallocLogger;
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
void apmMallocLoggerHook(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip) {
    if (g_apmMallocManager == NULL) {
        return;
    }
    
    if (!g_apmMallocManager->enableMallocMonitor) {
        return;
    }
    
    if (g_apmPreMallocLogger) {
        g_apmPreMallocLogger(type, arg1, arg2, arg3, result, backtrace_to_skip);
    }
    
    // 消除共同项
    if (type & stack_logging_flag_zone) {
        type &= ~stack_logging_flag_zone;
    }
    
    // 内存统计
    apmMemoryLogger(type, arg1, arg2, arg3, result, backtrace_to_skip);
    
    // 泄漏统计
    apm_Leak_logger(type, arg1, arg2, arg3, result, backtrace_to_skip);
}
