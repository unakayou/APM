//
//  APMMemoryManager.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMallocManager.h"
#import <malloc/malloc.h>
#import "APMLogManager.h"
#import "APMMallocLoggerHook.h"

APMMallocManager::APMMallocManager() {
    // 初始化logger存储空间
    if (NULL == g_apmHashmapZone) {
        g_apmHashmapZone = malloc_create_zone(0, 0);
        malloc_set_zone_name(g_apmHashmapZone, "APMHashmapZone");
    }
}

APMMallocManager::~APMMallocManager() {
    printf("销毁");
}

void APMMallocManager::initLogger(NSString *path, size_t mmap_size) {
    APMLogDebug(@"初始化Logger");
}

void APMMallocManager::startMallocStackMonitor(size_t threshholdInBytes) {
    if (NULL == apmAddressHashmap) {
        apmAddressHashmap = new APMAddresshashmap(50000, g_apmHashmapZone);
    }
    // 设置malloc_logger
    startMallocLogger();
    
    enableMallocMonitor = YES;
}

void APMMallocManager::recordMallocStack(vm_address_t address,uint32_t size,size_t stack_num_to_skip) {
    base_ptr_log base_ptr;
    base_ptr.digest = NULL;
    base_ptr.size = size;
    
    os_unfair_lock_lock(&hashmap_unfair_lock);
    if (apmAddressHashmap) {
        if (apmAddressHashmap->insertPtr(address, &base_ptr)) {

        }
    }
    os_unfair_lock_unlock(&hashmap_unfair_lock);
}

void APMMallocManager::removeMallocStack(vm_address_t address) {
    os_unfair_lock_lock(&hashmap_unfair_lock);
    if (apmAddressHashmap) {
        uint32_t size = 0;
        uint64_t digest = 0;
        if (apmAddressHashmap->removePtr(address, &size, &digest)) {
            printf("删除 0x%lx", address);
        }
    }
    os_unfair_lock_unlock(&hashmap_unfair_lock);
}
