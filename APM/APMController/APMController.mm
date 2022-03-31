//
//  APMController.m
//  APM
//
//  Created by unakayou on 2022/3/23.
//

#import "APMController.h"
#import "APMPathUtil.h"
#import "APMMallocManager.h"

@implementation APMController

+ (void)startCPUMonitor {
    
}

+ (void)stopCPUMonitor {
    
}

+ (void)startMemoryMonitor {
    
}

+ (void)stopMemoryMonitor {
    
}

+ (void)startOOMMonitor {
    
}

+ (void)stopOOMMonitor {
    
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
