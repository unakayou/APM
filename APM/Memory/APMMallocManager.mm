//
//  APMMemoryManager.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMMallocManager.h"
#import <malloc/malloc.h>
#import "APMLogManager.h"
#import "APMRapidCRC.h"
#import "Block.h"

APMMallocManager::APMMallocManager() {
    // 初始化logger存储空间
    if (NULL == g_apmHashmapZone) {
        g_apmHashmapZone = malloc_create_zone(0, 0);
        malloc_set_zone_name(g_apmHashmapZone, "APMHashmapZone");
    }
    
    // 初始化crc table
    initCRCTable();
    
    if (NULL == _apmAddressHashmap) {
        _apmAddressHashmap = new APMAddresshashmap(50000, g_apmHashmapZone);
    }
    
    if (NULL == _apmStackHashmap) {
        _apmStackHashmap = new APMStackHashmap(50000, g_apmHashmapZone, _funcLimitSize, _logPath, _logMmapSize);
    }
    
    if (NULL == _stackDumper) {
        _stackDumper = new APMStackDumper();
    }
}

APMMallocManager::~APMMallocManager() {
    if (NULL != _stackDumper) {
        delete _stackDumper;
    }
    
    os_unfair_lock_lock(&_hashmap_unfair_lock);
    if (NULL != _apmAddressHashmap) {
        delete _apmAddressHashmap;
    }
    
    if (NULL != _apmStackHashmap) {
        delete _apmStackHashmap;
    }
    os_unfair_lock_unlock(&_hashmap_unfair_lock);
    
    if (NULL != g_apmHashmapZone) {
        delete g_apmHashmapZone;
    }
}

void APMMallocManager::setWriterParamarters(NSString *path, size_t mmap_size) {
    _logPath = [path copy];
    _logMmapSize = mmap_size;
}

void APMMallocManager::setMallocFuncLimitSize(size_t funcLimitSize) {
    _funcLimitSize = funcLimitSize;
}

void APMMallocManager::setSingleMallocLimitSize(size_t singleLimitSize, MallocChunkCallback mallocBlock) {
    _singleLimitSize = singleLimitSize;
    _mallocBlock = [mallocBlock copy];
}

void APMMallocManager::recordMallocStack(vm_address_t address, uint32_t size, size_t stack_num_to_skip) {
    base_ptr_log base_ptr;
    
    // 堆栈
    vm_address_t  *stack[MAX_STACK_DEPTH];
    // 堆栈crc
    uint64_t digest;

    // 导出堆栈
    size_t depth = _stackDumper->recordBacktrace(true, stack_num_to_skip, stack, &digest, MAX_STACK_DEPTH);
    base_ptr.digest = digest;
    base_ptr.size = size;
    
    os_unfair_lock_lock(&_hashmap_unfair_lock);
    if (_apmAddressHashmap) {
        if (_apmAddressHashmap->insertPtr(address, &base_ptr)) {
            printf("添加成功 0x%lx \n", address);
        } else {
            printf("添加失败 0x%lx \n", address);
        }
    }
    os_unfair_lock_unlock(&_hashmap_unfair_lock);
}

void APMMallocManager::removeMallocStack(vm_address_t address) {
    os_unfair_lock_lock(&_hashmap_unfair_lock);
    if (_apmAddressHashmap) {
        uint32_t size = 0;
        uint64_t digest = 0;
        if (_apmAddressHashmap->removePtr(address, &size, &digest)) {
            printf("删除成功 0x%lx \n", address);
        } else {
            printf("删除失败 0x%lx \n", address);
        }
    }
    os_unfair_lock_unlock(&_hashmap_unfair_lock);
}

uintptr_t APMMallocManager::getMemoryZone() {
    return (uintptr_t)g_apmHashmapZone;
}
