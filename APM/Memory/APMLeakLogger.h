//
//  APMLeakLogger.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  泄漏记录

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    
    void apm_Leak_logger(uint32_t type, uintptr_t arg1, uintptr_t arg2, uintptr_t arg3, uintptr_t result, uint32_t backtrace_to_skip);

#ifdef __cplusplus
}
#endif
