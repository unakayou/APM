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
private:

};
