//
//  APMMemoryLogger.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  内存开辟记录

#import <Foundation/Foundation.h>
#ifdef __cplusplus
extern "C" {
#endif
    /// 内存开辟记录到Hashmap
    void apmMemoryLogger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip);
    
#ifdef __cplusplus
}
#endif
