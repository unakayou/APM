//
//  APMLeakManager.m
//  APM
//
//  Created by unakayou on 2022/4/21.
//

#import "APMLeakManager.h"
#import "APMRapidCRC.h"
#import "APMStackChecker.h"
#import "APMRegisterChecker.h"
#import "APMHeapChecker.h"
#import "APMSegmentChecker.h"
#import "APMThreadSuspendTool.h"

#define do_lockHashmap os_unfair_lock_lock(&_leak_hashmap_unfair_lock);
#define do_unlockHashmap os_unfair_lock_unlock(&_leak_hashmap_unfair_lock);
extern malloc_zone_t *g_apm_hashmap_zone;
extern APMLeakManager *g_apmLeakManager;

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
    
    if (_objcFilter == NULL) {
        _objcFilter = new CObjcFilter();
        _objcFilter->initBlackClass();
    }
    
    _stack_checker = new APMStackChecker(this);
    _segment_checker = new APMSegmentChecker(this);
    _heap_checker = new APMHeapChecker(this);
    _register_checker = new APMRegisterChecker(this);
}

APMLeakManager::~APMLeakManager() {
    if (NULL != _stack_dumper) {
        delete _stack_dumper;
    }
    
    if(_objcFilter != NULL){
        delete _objcFilter;
    }
    
    delete _stack_checker;
    delete _segment_checker;
    delete _heap_checker;
    delete _register_checker;

}

void APMLeakManager::startLeakManager() {
    do_lockHashmap
    if (NULL == _apm_leak_address_hashmap) {
        _apm_leak_address_hashmap = new APMAddresshashmap(50000, g_apm_hashmap_zone);
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
    if (NULL != _apm_leak_address_hashmap) {
        delete _apm_leak_address_hashmap;
    }
    
    if (NULL != _apm_leak_stack_hashmap) {
        delete _apm_leak_stack_hashmap;
    }
    
    if (NULL != _apm_leaked_hashmap) {
        delete _apm_leaked_hashmap;
    }
    do_unlockHashmap
}

void APMLeakManager::setLeakExamineCallback(LeakExamineCallback callback) {
    if (callback) {
        _leakExamineCallback = callback;
    }
}

void APMLeakManager::recordMallocStack(vm_address_t address,uint32_t size,const char*name,size_t stack_num_to_skip) {
    base_leaked_stack_t base_stack;
    base_ptr_log base_ptr;
    uint64_t digest;
    vm_address_t *stack[max_stack_depth];
    
    if (size == (1024 * 3)) {
        printf("捕获到测试用例开辟的\n");
    }
    
    base_stack.depth = _stack_dumper->recordBacktrace(true, stack_num_to_skip, stack, &digest, max_stack_depth);
    if (base_stack.depth > 0) {
        base_stack.stack = stack;
        base_stack.extra.name = name;
        base_stack.extra.size = size;
        
        base_ptr.digest = digest;
        base_ptr.size = 0;
        
        do_lockHashmap
        if (_apm_leak_address_hashmap && _apm_leak_stack_hashmap) {
            if (_apm_leak_address_hashmap->insertPtr(address, &base_ptr)) {
                _apm_leak_stack_hashmap->insertStackAndIncreaseCountIfExist(digest, &base_stack);
            }
        }
        do_unlockHashmap
    }
}

void APMLeakManager::removeMallocStack(vm_address_t address) {
    do_lockHashmap
    if (_apm_leak_address_hashmap && _apm_leak_stack_hashmap) {
        uint32_t size = 0;
        uint64_t digest = 0;
        if (_apm_leak_address_hashmap->removePtr(address, &size, &digest)) {
            _apm_leak_stack_hashmap->removeIfCountIsZero(digest, size);
        }
    }
    do_unlockHashmap
}

bool APMLeakManager::findPtrInMemoryRegion(vm_address_t address) {
    ptr_log_t *ptr_log = _apm_leak_address_hashmap->lookupPtr(address);
    if(ptr_log != NULL){
        ptr_log->hits++;    // 表示匹配上了一次
        return true;
    }
    return false;
}

void APMLeakManager::startLeakDump() {
    enableTracking = false;
    
    if (NULL == _stack_checker) {
        _stack_checker = new APMStackChecker(g_apmLeakManager);
    }
    
    if (suspendAllChildThreads()) {
        
        // 查找指针
        _register_checker->startPtrCheck();
        _stack_checker->startPtrCheck(2);
        _segment_checker->startPtrCheck();
        _heap_checker->startPtrCheck();

        size_t total_size = 0;
        NSString *stackData = get_all_leak_stack(&total_size);
        
        resumeAllChildThreads();
        _segment_checker->removeAllSegments();
        if (_leakExamineCallback) {
            _leakExamineCallback(stackData, total_size);
        }
    }
    enableTracking = true;
}

// 筛选泄漏,拼接字符串
NSString* APMLeakManager::get_all_leak_stack(size_t *total_count) {
    // 筛选泄漏主要逻辑
    get_all_leak_ptrs();
    
    NSMutableString *stackData = [[NSMutableString alloc] init];
    size_t total = 0;
    
    // 遍历已发现的泄漏表
    for (size_t i = 0; i < _apm_leaked_hashmap->getEntryNum(); i++) {
        base_entry_t *entry = _apm_leaked_hashmap->getHashmapEntry() + i;
        leaked_ptr_t *current = (leaked_ptr_t *)entry->root;
        while (current != NULL) {
            // 从leaked表中拿堆栈crc去找完整堆栈
            merge_leaked_stack_t *merge_stack = _apm_leak_stack_hashmap->lookupStack(current->digest);
            if (merge_stack == NULL) {
                current = current->next;
                continue;
            }
            total += current->leak_count;
            [stackData appendString:@"---------------------------------------\n"];
            [stackData appendFormat:@"[发现泄漏]:\n地址:0x%lx\n名字:%s\n泄漏次数:%d\n堆栈详情:\n",
             current->address, merge_stack->extra.name, current->leak_count];
            for (size_t j = 0; j < merge_stack->depth; j++) {
                vm_address_t address = (vm_address_t)merge_stack->stack[j];
                segImageInfo segImage;
                if (_stack_dumper->getImageByAddr(address, &segImage)) {
                    [stackData appendFormat:@"\"%lu %s 0x%lx 0x%lx\"\n",j,(segImage.name != NULL) ? segImage.name : "unknown",segImage.loadAddr,(long)address];
                }
            }
            [stackData appendString:@"\n"];
            current = current->next;
        }
    }
    [stackData insertString:[NSString stringWithFormat:@"LeakChecker find %lu leak object\n",total] atIndex:0];
    *total_count = total;
    return stackData;
}

// 筛选泄漏,加入到_apm_leaked_hashmap中
void APMLeakManager::get_all_leak_ptrs() {
    for (size_t i = 0; i < _apm_leak_address_hashmap->getEntryNum(); i++) {
        // 获取第i个下挂链表入口
        base_entry_t *entry = _apm_leak_address_hashmap->getHashmapEntry() + i;
        
        // 获取下挂链表第一个
        ptr_log_t *current = (ptr_log_t *)entry->root;
        
        // 遍历下挂链表
        while (current != NULL) {
            // 根据crc去stack表中查找
            merge_leaked_stack_t *merge_stack = _apm_leak_stack_hashmap->lookupStack(current->digest);
            
            // 没匹配到,找链表下一个
            if (merge_stack == NULL) {
                current = current->next;
                continue;
            }
            
            // 匹配到了
            if (merge_stack->extra.name != NULL) {
                if (current->hits == 0) {
                    // size为0,说明没有指针指向,所以添加到泄漏map中
                    _apm_leaked_hashmap->insertLeakPtrAndIncreaseCountIfExist(current->digest, current);
                    
                    // 从address表中删除
                    vm_address_t address = current->address;
                    _apm_leak_address_hashmap->removePtr(address, NULL, NULL);
                }
                current->hits = 0;
            } else {
                vm_address_t address = current->address;
                const char* name = _objcFilter->getObjectNameExceptBlack((void *)address);   // 判断是否为OC对象，获取类名
                if(name != NULL){
                    if(current->hits == 0){
                        merge_stack->extra.name = name;
                        _apm_leaked_hashmap->insertLeakPtrAndIncreaseCountIfExist(current->digest, current);
                        vm_address_t address = (vm_address_t)(0x100000000 | current->address);
                        _apm_leak_address_hashmap->removePtr(address,NULL,NULL);
                    }
                    current->size = 0;
                } else {
                    _apm_leak_address_hashmap->removePtr(current->address,NULL,NULL);
                }
            }
            current = current->next;
        }
    }
}

uintptr_t APMLeakManager::getMemoryZone() {
    return (uintptr_t)g_apm_hashmap_zone;
}
