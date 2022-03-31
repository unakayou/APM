//
//  APMMallocLogger.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  Malloc回调 负责接收回调分配给对应入口

#import <Foundation/Foundation.h>
#import "APMLeakLogger.h"
#import "APMMemoryLogger.h"
#import <malloc/malloc.h>

#ifdef __cplusplus
extern "C" {
#endif

/// libmalloc.dylib/stack_logging.h 中声明的函数类型
typedef void (malloc_logger_t)(uint32_t type,
                               uintptr_t arg1,
                               uintptr_t arg2,
                               uintptr_t arg3,
                               uintptr_t result,
                               uint32_t num_hot_frames_to_skip);

/// 接收malloc_logger回调函数
void apmMallocLoggerHook(uint32_t type,
                         uintptr_t arg1,
                         uintptr_t arg2,
                         uintptr_t arg3,
                         uintptr_t result,
                         uint32_t backtrace_to_skip);

/// libmalloc库中的malloc_logger()函数指针
extern malloc_logger_t* malloc_logger;

/// 保存原本的malloc_logger()函数指针
static malloc_logger_t *g_apmPreMallocLogger;

/// MallocLogger所需要的HashMap开辟在这里,不统计此zone中的内存变化
extern malloc_zone_t *g_apmHashmapZone;

#ifdef __cplusplus
}

void startMallocLogger();
void stopMallocLogger();
#endif
