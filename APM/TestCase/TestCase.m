//
//  OOMLauncher.m
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import "TestCase.h"
#import "APMToastView.h"
#import "APMRebootMonitor.h"
#import "APMSharedThread.h"
#import "APMCPUStatisitcsCenter.h"
#import "APMMemoryStatisitcsCenter.h"

@implementation TestCase

+ (NSArray<TestCase *> *)allTestCase {
    TestCase *oomCase = [[TestCase alloc] init];
    oomCase.name = @"Out of memory";
    oomCase.caseBlock = ^{
        [TestCase OOMCase];
    };
    
    TestCase *blockCase = [[TestCase alloc] init];
    blockCase.name = @"Main Thread ANR";
    blockCase.caseBlock = ^{
        [TestCase mainThreadBlock];
    };
    
    TestCase *crashCase = [TestCase new];
    crashCase.name = @"Objective-C Crash";
    crashCase.caseBlock = ^{
        [TestCase OCCrash];
    };
    
    TestCase *cpuHigh = [TestCase new];
    cpuHigh.name = @"CPU高占用";
    cpuHigh.caseBlock = ^{
        for (int i = 0; i < 100; i++) {
            dispatch_queue_t queue = dispatch_queue_create([NSString stringWithFormat:@"Queue-%d",i].UTF8String, DISPATCH_QUEUE_CONCURRENT);
            dispatch_async(queue, ^{
                while (1);
            });
        }
    };
    
    TestCase *exitCase = [TestCase new];
    exitCase.name = @"Exit(0)";
    exitCase.caseBlock = ^{
        [TestCase exitCase];
    };
    
//    TestCase *startCPU = [TestCase new];
//    startCPU.name = @"重启CPU监控";
//    startCPU.caseBlock = ^{
//        [APMCPUStatisitcsCenter start];
//    };
//
//    TestCase *stopCPU = [TestCase new];
//    stopCPU.name = @"停止CPU监控";
//    stopCPU.caseBlock = ^{
//        [APMCPUStatisitcsCenter stop];
//    };
//    
//    TestCase *startCase = [TestCase new];
//    startCase.name = @"重启内存监控";
//    startCase.caseBlock = ^{
//        [APMMemoryStatisitcsCenter  start];
//    };
//
//    TestCase *stopCase = [TestCase new];
//    stopCase.name = @"停止内存监控";
//    stopCase.caseBlock = ^{
//        [APMMemoryStatisitcsCenter  stop];
//    };
//
//    TestCase *startThread = [TestCase new];
//    startThread.name = @"重启共享线程";
//    startThread.caseBlock = ^{
//        [[APMSharedThread shareDefaultThread] start];
//    };
//
//    TestCase *stopThread = [TestCase new];
//    stopThread.name = @"退出共享线程";
//    stopThread.caseBlock = ^{
//        [[APMSharedThread shareDefaultThread] stop];
//    };
//    
    NSMutableArray *allTestCase = [NSMutableArray new];
    [allTestCase addObject:oomCase];
    [allTestCase addObject:blockCase];
    [allTestCase addObject:crashCase];
    [allTestCase addObject:cpuHigh];
    [allTestCase addObject:exitCase];
    
//    [allTestCase addObject:startCPU];
//    [allTestCase addObject:stopCPU];
//    [allTestCase addObject:startCase];
//    [allTestCase addObject:stopCase];
//    [allTestCase addObject:startThread];
//    [allTestCase addObject:stopThread];

    return allTestCase;
}

+ (void)OOMCase {
    [APMToastView showToastViewWithMessage:@"开始OOM"];
    dispatch_queue_t queue = dispatch_queue_create("OOMTestQueue", DISPATCH_QUEUE_SERIAL);
    dispatch_async(queue, ^{
        while (1) {
            int size = 1024 * 1024 * 200;
            void *tmp = malloc(size);
            memset(tmp, 0, size);
            sleep(1);
        }
    });
}

+ (void)exitCase {
    [APMToastView showToastViewWithMessage:@"即将退出"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        exit(0);
    });
}

+ (void)OCCrash {
    [APMToastView showToastViewWithMessage:@"即将触发OC崩溃"];
    [APMRebootMonitor applicationCrashed];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSMutableArray *array = (NSMutableArray *)@[@"1", @"2"];
        [array addObject:@"3"];
    });
}

+ (void)mainThreadBlock {
    [APMToastView showToastViewWithMessage:@"卡顿开始"];
    [APMRebootMonitor applicationMainThreadBlocked];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDate *lastDate = [NSDate date];
        while (1) {
            NSDate *currentDate = [NSDate date];
            if (([currentDate timeIntervalSince1970] - [lastDate timeIntervalSince1970]) > 3.0f) {
                NSLog(@"卡顿结束，即将退出");
                _exit(0);
            }
        }
    });
}

@end
