//
//  APMDefines.h
//  APM
//
//  Created by unakayou on 2022/3/21.
//

#ifndef APMDefines_h
#define APMDefines_h

#define APM_SYMBOL_SWITCH 1
#define APM_DEALLOC_LOG_SWITCH 0

#ifdef __LP64__
typedef struct mach_header_64 mach_header_t;
typedef struct segment_command_64 segment_command_t;
typedef struct section_64 section_t;
#else
typedef struct mach_header mach_header_t;
typedef struct segment_command segment_command_t;
typedef struct section section_t;
#endif

#if defined(__i386__)

#define MY_THREAD_STATE_COUTE x86_THREAD_STATE32_COUNT
#define MY_THREAD_STATE x86_THREAD_STATE32
#define MY_EXCEPTION_STATE_COUNT x86_EXCEPTION_STATE64_COUNT
#define MY_EXCEPITON_STATE ARM_EXCEPTION_STATE32
#define MY_SEGMENT_CMD_TYPE LC_SEGMENT

#elif defined(__x86_64__)

#define MY_THREAD_STATE_COUTE x86_THREAD_STATE64_COUNT
#define MY_THREAD_STATE x86_THREAD_STATE64
#define MY_EXCEPTION_STATE_COUNT x86_EXCEPTION_STATE64_COUNT
#define MY_EXCEPITON_STATE x86_EXCEPTION_STATE64
#define MY_SEGMENT_CMD_TYPE LC_SEGMENT_64

#elif defined(__arm64__)

#define MY_THREAD_STATE_COUTE ARM_THREAD_STATE64_COUNT
#define MY_THREAD_STATE ARM_THREAD_STATE64
#define MY_EXCEPTION_STATE_COUNT ARM_EXCEPTION_STATE64_COUNT
#define MY_EXCEPITON_STATE ARM_EXCEPTION_STATE64
#define MY_SEGMENT_CMD_TYPE LC_SEGMENT_64

#elif defined(__arm__)

#define MY_THREAD_STATE_COUTE ARM_THREAD_STATE_COUNT
#define MY_THREAD_STATE ARM_THREAD_STATE
#define MY_EXCEPITON_STATE ARM_EXCEPTION_STATE
#define MY_EXCEPTION_STATE_COUNT ARM_EXCEPTION_STATE_COUNT
#define MY_SEGMENT_CMD_TYPE LC_SEGMENT

#else
#error Unsupported host cpu.
#endif

#define stack_logging_type_free        0
#define stack_logging_type_generic    1    /* anything that is not allocation/deallocation */
#define stack_logging_type_alloc    2    /* malloc, realloc, etc... */
#define stack_logging_type_dealloc    4    /* free, realloc, etc... */
#define stack_logging_flag_zone        8    /* NSZoneMalloc, etc... */
#define stack_logging_type_vm_allocate  16      /* vm_allocate or mmap */
#define stack_logging_type_vm_deallocate  32    /* vm_deallocate or munmap */
#define stack_logging_type_mapped_file_or_shared_mem    128

typedef NS_ENUM(NSUInteger, APMRebootType) {
    APMRebootTypeUnKnow             = 0,    // 未知
    APMRebootTypeBegin              = 1,    // 开始
    
    APMRebootTypeQuitByUser         = 2,    // 上滑退出
    APMRebootTypeOSReboot           = 3,    // 系统重启
    APMRebootTypeAppVersionChange   = 4,    // App升级
    APMRebootTypeOSVersionChange    = 5,    // 系统升级
    APMRebootTypeQuitByExit         = 6,    // exit()

    APMRebootTypeCrash              = 7,    // 崩溃
    APMRebootTypeANR                = 8,    // 卡死
    APMRebootTypeFOOM               = 9,    // 前台OOM
    APMRebootTypeBOOM               = 10,   // 后台OOM或被Jestam杀掉
};

#endif /* APMDefines_h */
