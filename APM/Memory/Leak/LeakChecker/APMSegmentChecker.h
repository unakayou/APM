//
//  APMSegmentChecker.h
//  APM
//
//  Created by unakayou on 2022/5/9.
//
//  全局指针

#import "APMMemoryChecker.h"
#import <vector>

typedef struct {
    const char *image_name;
    const char *sect_name;
    vm_address_t beginAddr;
    vm_size_t size;
} dataSegment;

class APMSegmentChecker : public APMMemoryChecker {
public:
    APMSegmentChecker(APMLeakManager *leak_manager) : APMMemoryChecker(leak_manager){};
    
    // 获取所有segment
    void initAllSegments();
    
    // 释放
    void removeAllSegments();
    
    // 开始查询
    void startPtrCheck();
private:
    // 所有segment数组
    std::vector<dataSegment> segments;
};
