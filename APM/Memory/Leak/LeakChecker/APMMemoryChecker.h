//
//  APMMemoryChecker.h
//  APM
//
//  Created by unakayou on 2022/4/24.
//
//  匹配地址与指针

#import "APMLeakManager.h"

class APMMemoryChecker {
public:
    APMMemoryChecker(APMLeakManager *leak_manager):leak_manager(leak_manager){};
    ~APMMemoryChecker();
    
    /// 查找rang是否在addressMap中
    void check_ptr_in_vmrange(vm_range_t range);
protected:
    APMLeakManager *leak_manager;
};
