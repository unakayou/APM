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
#import "APMMallocLoggerHook.h"

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
+ (void)startMallocMonitorWithFunctionLimitSize:(size_t)functionLimitSize singleLimitSize:(size_t)singleLimitSize {
    if (NULL == g_apmMallocManager) {
        g_apmMallocManager = new APMMallocManager();
        g_apmMallocManager->setWriterParamarters([APMPathUtil mallocInfoPath], 1024 * 1024);
        g_apmMallocManager->setMallocFuncLimitSize(functionLimitSize);
        
        // 先初始化 malloc_manager, 再设置 malloc_logger
        startMallocLogger();
    }
}

+ (void)stopMallocMonitor {
    // 先还原 malloc_logger,再释放 malloc_manager
    stopMallocLogger();
    
    if (NULL != g_apmMallocManager) {
        delete g_apmMallocManager;
        g_apmMallocManager = NULL;
    }
}

@end
