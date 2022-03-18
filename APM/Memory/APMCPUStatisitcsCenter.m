//
//  APMCPUStatisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/18.
//

#import "APMCPUStatisitcsCenter.h"
#import "APMSharedThread.h"
#import "APMDeviceInfo.h"

@implementation APMCPUStatisitcsCenter

#define DEFUTALT_MAX_CPU_USAGE_PERCENT 0.8

static NSTimer *_timer;                                             // 循环检测CPU
static CPUCallbackHandler _usageHandler;                            // CPU占用回调
static float _maxCPUUsagePercent = DEFUTALT_MAX_CPU_USAGE_PERCENT;  // 默认CPU警告阈值

+ (void)start {
    if (!_timer || !_timer.isValid) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateCPUUsage) userInfo:nil repeats:YES];
    }
    [[APMSharedThread shareDefaultThread] start];
    [[APMSharedThread shareDefaultThread] addTimer:_timer];
}

+ (void)updateCPUUsage {
    float usagepercent = [APMDeviceInfo currentCPUUsagePercent];
    if (usagepercent >= _maxCPUUsagePercent) {
        // todo: 记录堆栈等,写文件
        APMLogDebug(@"⚠️ 警告:CPU占用即将达到阈值");
    }
    if (_usageHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _usageHandler(usagepercent);
        });
    }
}

+ (void)stop {
    [[APMSharedThread shareDefaultThread] removeTimer:_timer];
    
    _timer = nil;
    _usageHandler = nil;
}

+ (void)setLimitCPUUSagePercent:(float)maxCPUUsagePercent {
    _maxCPUUsagePercent = maxCPUUsagePercent;
}

+ (void)setCPUUsageHandler:(CPUCallbackHandler)usageHandler {
    _usageHandler = [usageHandler copy];
}
@end
