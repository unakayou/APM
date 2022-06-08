//
//  APMStackDumper.m
//  APM
//
//  Created by unakayou on 2022/4/12.
//

#import "APMStackDumper.h"
#import "execinfo.h"
#import "APMRapidCRC.h"
#import <mach-o/dyld.h>

typedef struct {
    vm_address_t beginAddr;
    vm_address_t endAddr;
}App_Address;

static App_Address app_addrs[3];    // 记录主image地址区间

APMStackDumper::APMStackDumper() {
    uint32_t count = _dyld_image_count();
    allImages.imageInfos =(segImageInfo **)malloc(count*sizeof(segImageInfo*));
    allImages.size = 0;
    for (uint32_t i = 0; i < count; i++) {
        const mach_header_t* header = (const mach_header_t*)_dyld_get_image_header(i);
        const char* name = _dyld_get_image_name(i);
        const char* tmp = strrchr(name, '/');
        long slide = _dyld_get_image_vmaddr_slide(i);
        if (tmp) {
            name = tmp + 1;
        }
        long offset = (long)header + sizeof(mach_header_t);
        for (unsigned int j = 0; j < header->ncmds; j++) {
            const segment_command_t* segment = (const segment_command_t*)offset;
            if (segment->cmd == MY_SEGMENT_CMD_TYPE && strcmp(segment->segname, SEG_TEXT) == 0) {
                long begin = (long)segment->vmaddr + slide;
                long end = (long)(begin + segment->vmsize);
                segImageInfo *image = (segImageInfo *)malloc(sizeof(segImageInfo));
                image->loadAddr = (long)header;
                image->beginAddr = begin;
                image->endAddr = end;
                image->name = name;

                if(i == 0){
                    app_addrs[0].beginAddr = image->beginAddr;
                    app_addrs[0].endAddr = image->endAddr;
                }
                allImages.imageInfos[allImages.size++] = image;
                break;
            }
            offset += segment->cmdsize;
        }
    }
}

APMStackDumper::~APMStackDumper() {
    for (size_t i = 0; i < allImages.size; i++) {
        free(allImages.imageInfos[i]);
    }
    free(allImages.imageInfos);
    allImages.imageInfos = NULL;
    allImages.size = 0;
}

#warning 有泄漏
size_t APMStackDumper::recordBacktrace(bool needSystemStack,
                                       size_t backtrace_to_skip,
                                       vm_address_t **app_stack,
                                       uint64_t *digest,
                                       size_t max_stack_depth) {
    vm_address_t *orig_stack[MAX_STACK_DEPTH];
    size_t depth = backtrace((void**)orig_stack, MAX_STACK_DEPTH);  // 导出堆栈
    size_t orig_depth = depth;  // 备份一下当前获取的堆栈深度
    // 深度超过最大值,设置为最大值
    if(depth > max_stack_depth){
        depth = max_stack_depth;
    }
    
    size_t offset = 0;
    size_t real_length = depth - 2 - backtrace_to_skip;
    for(size_t i = backtrace_to_skip; i < backtrace_to_skip + real_length; i++){
        if(needSystemStack) {
            // 要所有堆栈
            app_stack[offset++] = orig_stack[i];
        } else {
            // 不要系统堆栈,只要App模块的
            if(isInAppAddress((vm_address_t)orig_stack[i])){
                app_stack[offset++] = orig_stack[i];
            }
        }
    }
    app_stack[offset] = orig_stack[orig_depth - 2]; // main()

    if(offset > 0) {
        size_t remainder = (offset * 4) % 8;
        size_t compress_len = offset * 4 + (remainder == 0 ? 0 : (8 - remainder));
        uint64_t crc = 0;
        crc = APMCRC64(crc, (const char *)&app_stack, compress_len);   // 校验
        *digest = crc;
        return offset + 1;
    }
    return 0;
}

bool APMStackDumper::isInAppAddress(vm_address_t address) {
    if((address >= app_addrs[0].beginAddr && address < app_addrs[0].endAddr)) {
        return true;
    }
    return false;
}

bool APMStackDumper::getImageByAddr(vm_address_t addr,segImageInfo *image) {
    for (size_t i = 0; i < allImages.size; i++) {
        if (addr > allImages.imageInfos[i]->beginAddr && addr < allImages.imageInfos[i]->endAddr) {
            image->name = allImages.imageInfos[i]->name;
            image->loadAddr = allImages.imageInfos[i]->loadAddr;
            image->beginAddr = allImages.imageInfos[i]->beginAddr;
            image->endAddr = allImages.imageInfos[i]->endAddr;
            return true;
        }
    }
    return false;
}

