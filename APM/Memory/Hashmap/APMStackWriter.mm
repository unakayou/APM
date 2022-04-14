//
//  APMStackWriter.m
//  APM
//
//  Created by unakayou on 2022/4/14.
//

#import "APMStackWriter.h"

APMStackWriter::APMStackWriter() {
    
}

APMStackWriter::~APMStackWriter() {
    
}

void APMStackWriter::updateStack(merge_stack_t *current,base_stack_t *stacks) {
    printf("⚠️ 累积达到大内存警告: digest:%llu\n", current->digest);
    printf("堆栈信息:\n");
    for (int i = 0; i < stacks->depth; i++) {
        printf("0x%lx\n", (vm_address_t)stacks->stack[i]);
    }
    // 重制size,防止频繁调用
    current->size = 0;
}

void APMStackWriter::removeStack(merge_stack_t *current,bool needRemove) {
    
}

