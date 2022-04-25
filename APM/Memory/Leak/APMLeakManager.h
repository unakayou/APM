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

class APMStackChecker;

typedef void (^LeakExamineCallback)(NSString *leakData,size_t leak_num);

class APMLeakManager {
public:
    APMLeakManager();
    ~APMLeakManager();
    
    /// 开始停止监听
    void startLeakManager();
    void stopLeakManager();
    
    /// 记录、删除开辟空间以及堆栈详情
    void recordMallocStack(vm_address_t address,uint32_t size,const char*name,size_t stack_num_to_skip);
    void removeMallocStack(vm_address_t address);
    
    /// 导出泄漏
    void startLeakDump(LeakExamineCallback callback);
    
    /// 查找指针是否存在于addressHashmap
    bool findPtrInMemoryRegion(vm_address_t address);
    
    /// 泄漏所用内存空间
    uintptr_t getMemoryZone();
    
    /// 监控开启状态
    bool enableTracking = false;
private:
    APMStackChecker *_stack_checker;                            // 堆栈指针查找
    
    size_t max_stack_depth = 10;
    APMStackDumper *_stack_dumper;                              // 堆栈导出工具
    APMAddresshashmap *_apm_address_hashmap = NULL;             // 存储空间地址 key: address
    APMLeakStackHashmap *_apm_leak_stack_hashmap = NULL;        // 存储堆栈详情 key: 堆栈CRC
    APMLeakedHashmap *_apm_leaked_hashmap = NULL;               // 临时存储发现的泄漏地址 key: 堆栈CRC
    os_unfair_lock _leak_hashmap_unfair_lock = OS_UNFAIR_LOCK_INIT;
};
