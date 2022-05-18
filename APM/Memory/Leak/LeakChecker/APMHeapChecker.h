//
//  APMHeapChecker.h
//  APM
//
//  Created by unakayou on 2022/5/9.
//
//  堆中指针查找

#import "APMMemoryChecker.h"

class APMHeapChecker : public APMMemoryChecker {
public:
    APMHeapChecker(APMLeakManager *leak_manager):APMMemoryChecker(leak_manager){};
    void startPtrCheck();
private:
    static void check_ptr_in_heap(task_t task, void *baton, unsigned type, vm_range_t *ptrs, unsigned count);
    static void find_ptr_in_heap(task_t task, void *baton, unsigned type, vm_range_t *ptrs, unsigned count);
    void enumerate_ptr_in_zone (void *baton, const malloc_zone_t *zone,vm_range_recorder_t recorder);
};
