//
//  APMMemoryChecker.m
//  APM
//
//  Created by unakayou on 2022/4/24.
//

#import "APMMemoryChecker.h"

APMMemoryChecker::~APMMemoryChecker() {
    printf("销毁checker");
}

void APMMemoryChecker::check_ptr_in_vmrange(vm_range_t range) {
    const uint32_t align_size = sizeof(void *);
    vm_address_t vm_addr = range.address;
    vm_size_t vm_size = range.size;
    vm_size_t end_addr = vm_addr + vm_size;
    if (align_size <= vm_size) {
        uint8_t *ptr_addr = (uint8_t *)vm_addr;
        for (uint64_t addr = vm_addr; addr < end_addr && ((end_addr - addr) >= align_size); addr += align_size, ptr_addr += align_size) {
            vm_address_t *dest_ptr = (vm_address_t *)ptr_addr;
            leak_manager->findPtrInMemoryRegion(*dest_ptr);
        }
    }
}
