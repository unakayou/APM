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
    if(arg1 == (uintptr_t)g_apmMallocManager->getMemoryZone()){
        printf("不统计APM自身开辟内存空间");
        return;
    }
    
    if (type & stack_logging_flag_zone) {
        type &= ~stack_logging_flag_zone;
    }
    
    if (type == (stack_logging_type_dealloc | stack_logging_type_alloc)) {
        // 只有一个特殊既包含alloc、又包含dealloc,如realloc(), 先删除旧地址,再插入新地址
//        if (g_apmMallocManager->limitSize < arg3) {
//            // 大内存警告
//            printf("⚠️ 内存超过阈值");
//        }
    } else if (type == stack_logging_type_dealloc) {
        // 只包含dealloc的才是释放空间,如free、etc...
        g_apmMallocManager->removeMallocStack(arg2);
//        printf("type:销毁空间, zone地址:0x%lx, 销毁地址:0x%lx\n", arg1, arg2);
    } else if ((type & stack_logging_type_alloc) == stack_logging_type_alloc) {
        // 只要有type_alloc就是新开辟空间,如malloc、calloc、etc...
        g_apmMallocManager->recordMallocStack(result, (uint32_t)arg2, backtrace_to_skip);
//        printf("type:申请空间, zone地址:0x%lx, 申请地址:0x%lx, size:%lu, arg3:%lu, skip:%d \n", arg1, result, arg2, arg3, backtrace_to_skip);
//        if (g_apmMallocManager->limitSize < arg3) {
//            // 大内存警告
//            printf("⚠️ 内存超过阈值");
//        }
    }
}
