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
#import "execinfo.h"


#define USE_UNFAIR_LOCK 1
#if USE_UNFAIR_LOCK
#define do_lockHashmap os_unfair_lock_lock(&_hashmap_unfair_lock);
#define do_unlockHashmap os_unfair_lock_unlock(&_hashmap_unfair_lock);
#else
#define do_lockHashmap dispatch_semaphore_wait(_hashmap_semaphore, DISPATCH_TIME_FOREVER);
#define do_unlockHashmap dispatch_semaphore_signal(_hashmap_semaphore);
#endif

extern malloc_zone_t *g_apm_hashmap_zone;

APMMallocManager::APMMallocManager() {
    // 初始化crc table
    initCRCTable();
    
#if !USE_UNFAIR_LOCK
    _hashmap_semaphore = dispatch_semaphore_create(1);
#endif
    
    // 初始化logger存储空间
    if (NULL == g_apm_hashmap_zone) {
        g_apm_hashmap_zone = malloc_create_zone(0, 0);
        malloc_set_zone_name(g_apm_hashmap_zone, "APMHashmapZone");
    }
    
    if (NULL == _stackDumper) {
        _stackDumper = new APMStackDumper();
    }
}

APMMallocManager::~APMMallocManager() {
    if (NULL != _stackDumper) {
        delete _stackDumper;
    }
}

void APMMallocManager::setWriterParamarters(NSString *path, size_t mmap_size) {
    _logPath = [path copy];
    _logMmapSize = mmap_size;
}

void APMMallocManager::setFuncMallocLimitSize(size_t funcLimitSize) {
    _funcLimitSize = funcLimitSize;
}

void APMMallocManager::setFuncMallocExceed(MallocExceedCallback callback) {
    if (callback) {
        _funcLimitCallback = [callback copy];
    }
}

void APMMallocManager::setSingleMallocLimitSize(size_t singleLimitSize) {
    _singleLimitSize = singleLimitSize;
}

void APMMallocManager::setSingleMallocExceedCallback(MallocExceedCallback callback) {
    if (callback) {
        _singleLimitCallback = [callback copy];
    }
}

void APMMallocManager::startMallocManager(void) {
    do_lockHashmap
    // 初始化指针hashmap
    if (NULL == _apmAddressHashmap) {
        _apmAddressHashmap = new APMAddresshashmap(50000, g_apm_hashmap_zone);
    }
    
    // 初始化堆栈hashmap
    if (NULL == _apmStackHashmap) {
        _apmStackHashmap = new APMStackHashmap(50000, g_apm_hashmap_zone, _funcLimitSize, _logPath, _logMmapSize);
    }
    do_unlockHashmap
    
    enableTracking = true;
}

void APMMallocManager::stopMallocManager(void) {
    enableTracking = false;
    
    do_lockHashmap
    if (NULL != _apmAddressHashmap) {
        delete _apmAddressHashmap;
    }
    
    if (NULL != _apmStackHashmap) {
        delete _apmStackHashmap;
    }
    
    if (_singleLimitCallback) {
        _singleLimitCallback = nil;
    }
    
    if (_funcLimitCallback) {
        _funcLimitCallback = nil;
    }
    do_unlockHashmap
}

void APMMallocManager::recordMallocStack(vm_address_t address, uint32_t size, size_t stack_num_to_skip) {
    base_ptr_log base_ptr;
    base_stack_t base_stack;
    // 堆栈
    vm_address_t  *stack[MAX_STACK_DEPTH];
    // 堆栈crc
    uint64_t digest;

    // 导出堆栈
    uint32_t depth = (uint32_t)_stackDumper->recordBacktrace(true, stack_num_to_skip, stack, &digest, MAX_STACK_DEPTH);
    
    if (size >= _singleLimitSize) {
        // 发现单次大内存特殊处理后,直接返回
        if (_singleLimitCallback) {
            NSMutableString *stackInfo = [[NSMutableString alloc] init];
#if APM_SYMBOL_SWITCH
            char ** symbols = backtrace_symbols((void**)stack, (int)depth);
            for (int i = 0; i < depth; i++) {
                [stackInfo appendFormat:@"%s\n", symbols[i]];
            }
#else
            for (int i = 0; i < depth; i++) {
                [stackInfo appendFormat:@"0x%lx\n", (vm_address_t)stack[i]];
            }
#endif
            _singleLimitCallback(size, stackInfo);
        }
        return;
    }
    
    base_ptr.digest = digest;
    base_ptr.size = size;
    
    base_stack.stack = stack;
    base_stack.depth = depth;
    base_stack.size = size;
    
    do_lockHashmap
    bool funcOverLimit = NO;
    if (_apmAddressHashmap && _apmStackHashmap) {
        if (_apmAddressHashmap->insertPtr(address, &base_ptr)) {
            _apmStackHashmap->insertStackAndIncreaseCountIfExist(digest, &base_stack, &funcOverLimit);
        }
    }
    do_unlockHashmap

    if (funcOverLimit && _funcLimitCallback) {

        NSMutableString *string = [[NSMutableString alloc] init];
        
#if APM_SYMBOL_SWITCH
        char ** symbols = backtrace_symbols((void**)stack, (int)depth);
        for (int i = 0; i < depth; i++) {
            [string appendFormat:@"%s\n", symbols[i]];
        }
#else
        for (int i = 0; i < depth; i++) {
            [string appendFormat:@"0x%lx\n", (vm_address_t)stack[i]];
        }
#endif
        _funcLimitCallback(size, string);
    }
}

void APMMallocManager::removeMallocStack(vm_address_t address) {
    do_lockHashmap
    if (_apmAddressHashmap) {
        uint32_t size = 0;
        uint64_t digest = 0;
        if (_apmAddressHashmap->removePtr(address, &size, &digest)) {
            _apmStackHashmap->removeIfCountIsZero(digest, size, 1);
        }
    }
    do_unlockHashmap
}

uintptr_t APMMallocManager::getMemoryZone() {
    return (uintptr_t)g_apm_hashmap_zone;
}
