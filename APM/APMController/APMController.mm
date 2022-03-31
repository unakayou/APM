//
//  APMController.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMController.h"
#import "APMPathUtil.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"
#import "APMMallocManager.h"
#import "APMCPUStatisticCenter.h"
#import "APMFPSStatisticCenter.h"
#import "APMMemoryStatisticCenter.h"

@implementation APMController

+ (void)startWithAppid:(NSString *)appid config:(id)config {
    APMLogDebug(@"真正的初始化...");
}

+ (NSTimeInterval)launchTime {
    NSTimeInterval launchTime = [APMDeviceInfo processStartTime];
    return launchTime;
}

+ (void)startCPUMonitor {
    [APMCPUStatisticCenter start];
}

+ (void)stopCPUMonitor {
    [APMCPUStatisticCenter stop];
}

+ (void)setCPUUsageHandler:(CPUCallbackHandler)usageHandler {
    [APMCPUStatisticCenter setCPUUsageHandler:usageHandler];
}

+ (void)startFPSMonitor {
    [APMFPSStatisticCenter start];
}

+ (void)stopFPSMonitor {
    [APMFPSStatisticCenter stop];
}

+ (void)setFPSValueHandler:(FPSCallbackHandler)FPSHandler {
    [APMFPSStatisticCenter setFPSValueHandler:FPSHandler];
}

+ (void)startMemoryMonitor {
    [APMMemoryStatisticCenter start];
}

+ (void)stopMemoryMonitor {
    [APMMemoryStatisticCenter stop];
}

+ (void)setMemoryInfoHandler:(MemoryCallbackHandler)memoryHandler {
    [APMMemoryStatisticCenter setMemoryInfoHandler:memoryHandler];
}

+ (void)startOOMMonitor {
    [APMRebootMonitor start];
}

+ (void)stopOOMMonitor {
    [APMRebootMonitor stop];
}

+ (APMRebootType)rebootType {
    return [APMRebootMonitor rebootType];
}

+ (NSString *)rebootTypeString {
    return [APMRebootMonitor rebootTypeString];
}

APMMallocManager *g_apmMallocManager;
+ (void)startMallocMonitor {
    if (NULL == g_apmMallocManager) {
        g_apmMallocManager = new APMMallocManager();
        g_apmMallocManager->initLogger([APMPathUtil mallocInfoPath], 100);
        g_apmMallocManager->startMallocStackMonitor(0);
    }
}

+ (void)stopMallocMonitor {
    
}

@end
