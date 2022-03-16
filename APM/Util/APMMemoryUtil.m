//
//  APMMemoryUtil.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMMemoryUtil.h"
#import <mach/mach.h>
#import <mach-o/dyld.h>
#import <mach-o/loader.h>

@implementation APMMemoryUtil

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

+ (double)physFootprintMemory {
    int64_t memoryUsageInByte = 0;
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernelReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if(kernelReturn == KERN_SUCCESS) {
        memoryUsageInByte = (int64_t) vmInfo.phys_footprint;
    }
    return memoryUsageInByte / 1024.0f / 1024.0f;
}

+ (double)getTotalMemory {
    return [[NSProcessInfo processInfo] physicalMemory] / 1024.0f / 1024.0f;
}

@end
