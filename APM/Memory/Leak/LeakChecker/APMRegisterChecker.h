//
//  APMRegisterChecker.h
//  APM
//
//  Created by unakayou on 2022/4/29.
//
//  寄存器查询指针

#import "APMMemoryChecker.h"

class APMRegisterChecker : public APMMemoryChecker {
public:
    APMRegisterChecker(APMLeakManager *leak_manager) : APMMemoryChecker(leak_manager){};
    bool startPtrCheck();
};
