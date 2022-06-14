//
//  APMHeapChecker.m
//  APM
//
//  Created by unakayou on 2022/5/9.
//

#import "APMHeapChecker.h"
#import <mach/mach.h>

extern kern_return_t memory_reader (task_t task, vm_address_t remote_address, vm_size_t size, void **local_memory);
void APMHeapChecker::startPtrCheck() {
    vm_address_t *zones = NULL;
    unsigned int zone_num;
    // 获取所有zone
    kern_return_t err = malloc_get_all_zones(mach_task_self(), memory_reader, &zones, &zone_num);
    if (KERN_SUCCESS == err) {
        for (int i = 0; i < zone_num; ++i) {
            // 如果是自己创建的zone，不处理
            if(zones[i] == (vm_address_t)(leak_manager->getMemoryZone())) {
                continue;
            }
            enumerate_ptr_in_zone(this, (const malloc_zone_t *)zones[i], APMHeapChecker::check_ptr_in_heap);
        }
    }
}

void APMHeapChecker::enumerate_ptr_in_zone (void *baton, const malloc_zone_t *zone,vm_range_recorder_t recorder) {
    // 获取Zone内所有分配的节点
    if (zone && zone->introspect && zone->introspect->enumerator)
        zone->introspect->enumerator(mach_task_self(),
                                     this,
                                     MALLOC_PTR_IN_USE_RANGE_TYPE,
                                     (vm_address_t)zone,
                                     memory_reader,
                                     recorder);
}

// 遍历zone回调
void APMHeapChecker::check_ptr_in_heap(task_t task, void *baton, unsigned type, vm_range_t *ptrs, unsigned count) {
    APMHeapChecker *heapChecker = (APMHeapChecker *)baton;
    while(count--) {
        vm_range_t range = {ptrs->address,ptrs->size};
        // 检查是否命中
        heapChecker->check_ptr_in_vmrange(range);
        ptrs++;
    }
}
