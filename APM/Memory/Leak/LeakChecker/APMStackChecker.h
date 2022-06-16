//
//  APMStackChecker.h
//  APM
//
//  Created by unakayou on 2022/4/24.
//
//  堆栈指针查找

#import "APMMemoryChecker.h"

class APMStackChecker : public APMMemoryChecker {
public:
    APMStackChecker(APMLeakManager *leak_manager):APMMemoryChecker(leak_manager){};
    void startPtrCheck(size_t bt);
private:
    bool find_thread_sp(thread_t thread,vm_address_t *sp);
    bool find_thread_fp(thread_t thread,vm_address_t *fp,size_t bt_count);
};
