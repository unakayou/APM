//
//  APMMemoryStatisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMMemoryStatisitcsCenter.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"
#import "APMSharedThread.h"

#define DEFAULT_LIMIT_MEMORY_PERCENT 0.5;

static NSTimer *_timer;
static int _maxMemoryUsage;
static MemoryCallbackHandler _memoryHandler;

@implementation APMMemoryStatisitcsCenter

+ (void)start {
    // Timer不存在 或 Timer已经停止
    if (!_timer || !_timer.isValid) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateMemory) userInfo:nil repeats:YES];
    }
    
    if (_maxMemoryUsage <= 0) {
        _maxMemoryUsage = [APMDeviceInfo getTotalMemory] * DEFAULT_LIMIT_MEMORY_PERCENT;
    }
    
    [[APMSharedThread shareDefaultThread] start];
    [[APMSharedThread shareDefaultThread] addTimer:_timer];
}

+ (void)updateMemory {
    Float32 physFootprintMemory = [APMDeviceInfo physFootprintMemory];
    if (physFootprintMemory >= _maxMemoryUsage) {
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
    [[APMSharedThread shareDefaultThread] removeTimer:_timer];
    
    _timer = nil;
    _memoryHandler = nil;
}

+ (void)setOverFlowLimitMemoryUsage:(uint32_t)maxMemoryUsage {
    _maxMemoryUsage = maxMemoryUsage;
}

+ (void)setMemoryInfoHandler:(MemoryCallbackHandler)memoryHandler {
    _memoryHandler = [memoryHandler copy];
}

@end
