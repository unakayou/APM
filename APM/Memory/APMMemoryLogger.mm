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
    
    if (type == (stack_logging_type_dealloc | stack_logging_type_alloc)) {
        // 只有一个特殊既包含alloc、又包含dealloc,如realloc(), 先删除旧地址,再插入新地址
    } else if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        // 只要有type_alloc就是新开辟空间,如malloc、calloc、etc...
        g_apmMallocManager->recordMallocStack(result, (uint32_t)arg2, backtrace_to_skip);
    } else if (type == stack_logging_type_dealloc) {
        // 只包含dealloc的才是释放空间,如free、etc...
        g_apmMallocManager->removeMallocStack(result);
    }
}
