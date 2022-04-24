//
//  APMLeakManager.h
//  APM
//
//  Created by unakayou on 2022/4/21.
//
//  内存泄漏检测

#import "APMAddressHashmap.h"
#import "APMStackDumper.h"
#import "APMLeakedHashmap.h"
#import "APMLeakStackHashmap.h"
#import <os/lock.h>

class APMLeakManager {
public:
    APMLeakManager();
    ~APMLeakManager();
    
    void startLeakManager();
    void stopLeakManager();
    
    void recordMallocStack(vm_address_t address,uint32_t size,const char*name,size_t stack_num_to_skip);
    void removeMallocStack(vm_address_t address);
    
    uintptr_t getMemoryZone();
    
    bool enableTracking = false;
private:
    size_t max_stack_depth = 10;
    APMStackDumper *_stack_dumper;                              // 堆栈导出工具
    APMAddresshashmap *_apm_address_hashmap = NULL;             // 存储空间地址 key: address
    APMLeakStackHashmap *_apm_leak_stack_hashmap = NULL;        // 存储堆栈详情 key: 堆栈CRC
    APMLeakedHashmap *_apm_leaked_hashmap = NULL;               // 临时存储发现的泄漏地址 key: 堆栈CRC
    os_unfair_lock _leak_hashmap_unfair_lock = OS_UNFAIR_LOCK_INIT;
};
