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
#import "APMObjcFilter.h"
#import <os/lock.h>

class APMRegisterChecker;
class APMSegmentChecker;
class APMStackChecker;
class APMHeapChecker;

typedef void (^LeakExamineCallback)(NSString *leakData,size_t leak_num);

class APMLeakManager {
public:
    APMLeakManager();
    ~APMLeakManager();
    
    /// 开始停止监听
    void startLeakManager();
    void stopLeakManager();
    
    /// 设置泄漏回调
    void setLeakExamineCallback(LeakExamineCallback callback);
    
    /// 记录、删除开辟空间以及堆栈详情 stack_num_to_skip栈顶过滤条数
    void recordMallocStack(vm_address_t address,uint32_t size,const char*name,size_t stack_num_to_skip);
    void removeMallocStack(vm_address_t address);
    
    /// 导出泄漏
    void startLeakDump();
    
    /// 查找指针是否存在于addressHashmap
    bool findPtrInMemoryRegion(vm_address_t address);
    
    /// 泄漏所用内存空间
    uintptr_t getMemoryZone();
    
    /// 监控开启状态
    bool enableTracking = false;
    
    /// 是否正在检测泄漏
    bool isLeakChecking = false;
private:
    APMRegisterChecker *_register_checker;                      // 寄存器指针查找
    APMSegmentChecker *_segment_checker;                        // 全局指针查找
    APMStackChecker *_stack_checker;                            // 栈指针查找
    APMHeapChecker *_heap_checker;                              // 堆指针查找
    
    size_t max_stack_depth = 50;
    CObjcFilter *_objcFilter = NULL;                            // OC对象检测工具
    APMStackDumper *_stack_dumper = NULL;                       // 堆栈导出工具
    APMAddresshashmap *_apm_leak_address_hashmap = NULL;        // 存储空间地址 key: address
    APMLeakStackHashmap *_apm_leak_stack_hashmap = NULL;        // 存储堆栈详情 key: 堆栈CRC
    APMLeakedHashmap *_apm_leaked_hashmap = NULL;               // 临时存储发现的泄漏地址 key: 堆栈CRC
    os_unfair_lock _leak_hashmap_unfair_lock = OS_UNFAIR_LOCK_INIT;
    
    void get_all_leak_ptrs();                                   // 获取所有泄漏地址
    NSString *get_all_leak_stack(size_t *total_count);          // 获取所有泄漏堆栈
    
    LeakExamineCallback _leakExamineCallback;                   // 泄漏回调
};
