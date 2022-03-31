//
//  APMMemoryStatisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMMemoryStatisticCenter.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"
#import "APMSharedThread.h"

#define DEFAULT_LIMIT_MEMORY_PERCENT 0.5;
#define APM_MEMORY_STATISITCSCENTER_TIMER_KEY @"apmmemorystatisitcscentertimerkey"

static int _limitMemoryUsage;
static MemoryCallbackHandler _memoryHandler;
@implementation APMMemoryStatisticCenter

+ (void)start {
    if (_limitMemoryUsage <= 0) {
        _limitMemoryUsage = [APMDeviceInfo totalMemory] * DEFAULT_LIMIT_MEMORY_PERCENT;
    }
    
    __weak typeof (self) weakSelf = self;
    [[APMSharedThread shareDefaultThread] start];
    [[APMSharedThread shareDefaultThread] scheduledTimerWithKey:APM_MEMORY_STATISITCSCENTER_TIMER_KEY
                                                   timeInterval:1
                                                        repeats:YES
                                                          block:^(APMSharedThread * _Nonnull thread) {
        [weakSelf updateMemory];
    }];
}

+ (void)updateMemory {
    Float32 physFootprintMemory = [APMDeviceInfo physFootprintMemory];
    if (physFootprintMemory >= _limitMemoryUsage) {
        APMLogDebug(@"⚠️ 警告:内存即将达到阈值");
        
        // 记录可能产生OOM的内存增长
        [APMRebootMonitor applicationWillOOM:physFootprintMemory];
    }
    if (_memoryHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _memoryHandler(physFootprintMemory);
        });
    }
}

+ (void)stop {
    _memoryHandler = nil;
    [[APMSharedThread shareDefaultThread] invalidateTimerWithKey:APM_MEMORY_STATISITCSCENTER_TIMER_KEY];
}

+ (void)setOverFlowLimitMemoryUsage:(uint32_t)limitMemoryUsage {
    _limitMemoryUsage = limitMemoryUsage;
}

+ (void)setMemoryInfoHandler:(MemoryCallbackHandler)memoryHandler {
    _memoryHandler = [memoryHandler copy];
}

@end
