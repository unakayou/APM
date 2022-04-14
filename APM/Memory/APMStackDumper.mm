//
//  APMStackDumper.m
//  APM
//
//  Created by unakayou on 2022/4/12.
//

#import "APMStackDumper.h"
#import "execinfo.h"
#import "APMRapidCRC.h"

APMStackDumper::APMStackDumper() {
    
}

APMStackDumper::~APMStackDumper() {
    
}

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
    return true;
}
