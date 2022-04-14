//
//  APMDeviceInfo.m
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import "APMDeviceInfo.h"
#import <UIKit/UIKit.h>
#import <sys/sysctl.h>
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

@implementation APMDeviceInfo

+ (NSString *)systemVersion {
    return [UIDevice currentDevice].systemVersion;
}

+ (uint64_t)systemLaunchTimeStamp {
    NSTimeInterval time = [NSProcessInfo processInfo].systemUptime;
    NSDate *curDate = [[NSDate alloc] init];
    NSDate *startTime = [curDate dateByAddingTimeInterval:-time];
    return [startTime timeIntervalSince1970];
}

+ (NSTimeInterval)processStartTime {
    struct kinfo_proc kProcInfo;
    if ([self processInfoForPID:[[NSProcessInfo processInfo] processIdentifier] procInfo:&kProcInfo]) {
        NSTimeInterval timeStart = kProcInfo.kp_proc.p_un.__p_starttime.tv_sec * USEC_PER_SEC + kProcInfo.kp_proc.p_un.__p_starttime.tv_usec;
        NSTimeInterval timeNow = [[NSDate date] timeIntervalSince1970];
        return timeNow * USEC_PER_SEC - timeStart;
    } else {
        return 0;
    }
}

// sysctl():在运行时配置内核参数
+ (BOOL)processInfoForPID:(int)pid procInfo:(struct kinfo_proc*)procInfo {
    int cmd[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, pid};
    size_t size = sizeof(*procInfo);
    return sysctl(cmd, sizeof(cmd)/sizeof(*cmd), procInfo, &size, NULL, 0) == 0;
}

+ (Float32)currentCPUUsagePercent {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    thread_array_t thread_list;
    mach_msg_type_number_t thread_count;
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    float tot_cpu = 0;

    for (int j = 0; j < thread_count; j++) {
        thread_info_data_t thinfo;
        mach_msg_type_number_t thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO, (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        thread_basic_info_t basic_info_th = (thread_basic_info_t)thinfo;
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE;
        }
    }

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    return tot_cpu;
}

+ (NSString *)mainMachOUUID {
    uint32_t count = _dyld_image_count();
    for (int i = 0; i < count; i++) {
        const char *name = _dyld_get_image_name(i);
        const char* tmp = strrchr(name, '/');
        if (tmp) {
            name = tmp + 1;
        }

        NSString *imageName = [NSString stringWithUTF8String:name];
        NSString *executableName = [[NSBundle mainBundle] infoDictionary][@"CFBundleExecutable"];
        if ([imageName isEqualToString:executableName]) {
            const struct mach_header *header = _dyld_get_image_header(i);
            struct segment_command_64 *cur_seg_cmd;
            uintptr_t cur = (uintptr_t)header + sizeof(struct mach_header_64);
            for (uint j = 0; j < header->ncmds; j++, cur += cur_seg_cmd->cmdsize) {
                cur_seg_cmd = (struct segment_command_64 *)cur;
                if (cur_seg_cmd->cmd == LC_UUID) {
                    struct uuid_command* uuid_seg_cmd = (struct uuid_command *)cur_seg_cmd;
                    CFUUIDRef uuidRef = CFUUIDCreateFromUUIDBytes(NULL, *((CFUUIDBytes*)uuid_seg_cmd->uuid));
                    NSString *uuid = (__bridge_transfer NSString*)CFUUIDCreateString(NULL, uuidRef);
                    CFRelease(uuidRef);
                    return uuid;
                }
            }
        }
    }
    return nil;
}

+ (Float32)physFootprintMemory {
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte / 1024.0f / 1024.0f;
}

+ (Float32)totalMemory {
    return [[NSProcessInfo processInfo] physicalMemory] / 1024.0f / 1024.0f;
}

@end
