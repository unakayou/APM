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
#define APM_CPU_STATISITCS_CENTER_TIMER_KEY @"APMCPUSTATISITCSCENTERTIMERKEY"

static CPUCallbackHandler _usageHandler;                            // CPU占用回调
static float _maxCPUUsagePercent = DEFUTALT_MAX_CPU_USAGE_PERCENT;  // 默认CPU警告阈值

+ (void)start {
    __weak typeof (self) weakSelf = self;
    [[APMSharedThread shareDefaultThread] start];
    [[APMSharedThread shareDefaultThread] scheduledTimerWithKey:APM_CPU_STATISITCS_CENTER_TIMER_KEY
                                                   timeInterval:1
                                                        repeats:YES
                                                          block:^(APMSharedThread * _Nonnull thread) {
        [weakSelf updateCPUUsage];
    }];
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
    _usageHandler = nil;
    [[APMSharedThread shareDefaultThread] invalidateTimerWithKey:APM_CPU_STATISITCS_CENTER_TIMER_KEY];
}

+ (void)setLimitCPUUSagePercent:(float)maxCPUUsagePercent {
    _maxCPUUsagePercent = maxCPUUsagePercent;
}

+ (void)setCPUUsageHandler:(CPUCallbackHandler)usageHandler {
    _usageHandler = [usageHandler copy];
}
@end
