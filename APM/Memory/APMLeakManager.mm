//
//  APMLeakManager.m
//  APM
//
//  Created by unakayou on 2022/4/21.
//

#import "APMLeakManager.h"
#import "APMRapidCRC.h"

#define do_lockHashmap os_unfair_lock_lock(&_leak_hashmap_unfair_lock);
#define do_unlockHashmap os_unfair_lock_unlock(&_leak_hashmap_unfair_lock);
extern malloc_zone_t *g_apm_hashmap_zone;

APMLeakManager::APMLeakManager() {
    initCRCTable();

    // 初始化logger存储空间
    if (NULL == g_apm_hashmap_zone) {
        g_apm_hashmap_zone = malloc_create_zone(0, 0);
        malloc_set_zone_name(g_apm_hashmap_zone, "APMHashmapZone");
    }
    
    if (_stack_dumper == NULL) {
        _stack_dumper = new APMStackDumper();
    }
}

APMLeakManager::~APMLeakManager() {
    if (NULL != _stack_dumper) {
        delete _stack_dumper;
    }
}

void APMLeakManager::startLeakManager() {
    do_lockHashmap
    if (NULL == _apm_address_hashmap) {
        _apm_address_hashmap = new APMAddresshashmap(50000, g_apm_hashmap_zone);
    }
    
    if (NULL == _apm_leak_stack_hashmap) {
        _apm_leak_stack_hashmap = new APMLeakStackHashmap(5000, g_apm_hashmap_zone);
    }
    
    if (NULL == _apm_leaked_hashmap) {
        _apm_leaked_hashmap = new APMLeakedHashmap(200, g_apm_hashmap_zone);
    }
    do_unlockHashmap
    
    enableTracking = true;
}

void APMLeakManager::stopLeakManager() {
    enableTracking = false;

    do_lockHashmap
    if (NULL != _apm_address_hashmap) {
        delete _apm_address_hashmap;
    }
    
    if (NULL != _apm_leak_stack_hashmap) {
        delete _apm_leak_stack_hashmap;
    }
    
    if (NULL != _apm_leaked_hashmap) {
        delete _apm_leaked_hashmap;
    }
    do_unlockHashmap
}

void APMLeakManager::recordMallocStack(vm_address_t address,uint32_t size,const char*name,size_t stack_num_to_skip) {
    base_leaked_stack_t base_stack;
    base_ptr_log base_ptr;
    uint64_t digest;
    vm_address_t *stack[max_stack_depth];
    
    base_stack.depth = _stack_dumper->recordBacktrace(true, stack_num_to_skip, stack, &digest, max_stack_depth);
    if (base_stack.depth > 0) {
        base_stack.stack = stack;
        base_stack.extra.name = name;
        base_stack.extra.size = size;
        
        base_ptr.digest = digest;
        base_ptr.size = 0;
        
        do_lockHashmap
        if (_apm_address_hashmap && _apm_leak_stack_hashmap) {
            if (_apm_address_hashmap->insertPtr(address, &base_ptr)) {
                _apm_leak_stack_hashmap->insertStackAndIncreaseCountIfExist(digest, &base_stack);
            }
        }
        do_unlockHashmap
    }
}

void APMLeakManager::removeMallocStack(vm_address_t address) {
    do_lockHashmap
    if (_apm_address_hashmap && _apm_leak_stack_hashmap) {
        uint32_t size = 0;
        uint64_t digest = 0;
        if (_apm_address_hashmap->removePtr(address, &size, &digest)) {
            _apm_leak_stack_hashmap->removeIfCountIsZero(digest, size);
        }
    }
    do_unlockHashmap
}

uintptr_t APMLeakManager::getMemoryZone() {
    return (uintptr_t)g_apm_hashmap_zone;
}
