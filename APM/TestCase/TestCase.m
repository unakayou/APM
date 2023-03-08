//
//  OOMLauncher.m
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import "TestCase.h"
#import "APMToastView.h"
#import "APMRebootMonitor.h"
#import "APMController.h"

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
    
    TestCase *blockResumeCase = [[TestCase alloc] init];
    blockResumeCase.name = @"Main Thread Block Resume";
    blockResumeCase.caseBlock = ^{
        [TestCase mainThreadBlockResume];
    };
    
    TestCase *crashCase = [TestCase new];
    crashCase.name = @"Objective-C Crash";
    crashCase.caseBlock = ^{
        [TestCase OCCrash];
    };
    
    TestCase *cpuHigh = [TestCase new];
    cpuHigh.name = @"CPU高占用";
    cpuHigh.caseBlock = ^{
        [APMToastView showToastViewWithMessage:@"CPU高占用"];
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
    TestCase *chunkMalloc = [TestCase new];
    chunkMalloc.name = @"开辟大块内存";
    chunkMalloc.caseBlock = ^{
        [TestCase chunkMemoryMalloc];
    };
    
    TestCase *funcMallocLimit = [TestCase new];
    funcMallocLimit.name = @"单函数内存超限";
    funcMallocLimit.caseBlock = ^{
        [TestCase funcMallocLimit];
    };
    
    TestCase *leakedCase = [TestCase new];
    leakedCase.name = @"内存泄漏";
    leakedCase.caseBlock = ^{
        [TestCase leakedTestCase];
    };
    
    NSMutableArray *allTestCase = [NSMutableArray new];
    [allTestCase addObject:oomCase];
    [allTestCase addObject:blockCase];
    [allTestCase addObject:blockResumeCase];
    [allTestCase addObject:crashCase];
    [allTestCase addObject:cpuHigh];
    [allTestCase addObject:exitCase];
//    [allTestCase addObject:startCPU];
//    [allTestCase addObject:stopCPU];
//    [allTestCase addObject:startCase];
//    [allTestCase addObject:stopCase];
//    [allTestCase addObject:startThread];
//    [allTestCase addObject:stopThread];
    [allTestCase addObject:chunkMalloc];
    [allTestCase addObject:funcMallocLimit];
    [allTestCase addObject:leakedCase];
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

+ (void)mainThreadBlockResume {
    [APMToastView showToastViewWithMessage:@"卡顿开始"];
    [APMRebootMonitor applicationMainThreadBlocked];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDate *lastDate = [NSDate date];
        while (1) {
            NSDate *currentDate = [NSDate date];
            if (([currentDate timeIntervalSince1970] - [lastDate timeIntervalSince1970]) > 3.0f) {
                [APMToastView showToastViewWithMessage:@"卡顿结束"];
                [APMRebootMonitor applicationMainThreadBlockeResumed];
                break;
            }
        }
    });
}

+ (void)chunkMemoryMalloc {
    [APMToastView showToastViewWithMessage:@"大块内存申请中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        void *chunkMalloc = malloc(10 * 1024 * 1024);
        free(chunkMalloc);
        [APMToastView showToastViewWithMessage:@"大块内存申请完毕"];
    });
}

static void *tmpArray[1000];
+ (void)funcMallocLimit {
    [APMToastView showToastViewWithMessage:@"连续小内存申请中"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (int i = 0; i < 1000; i++) {
            void *tmp = malloc(1024 * 20);
            memset(tmp, 0, 1024 * 5);
            tmpArray[i] = tmp;
        }
        [APMToastView showToastViewWithMessage:@"连续小内存申请完毕"];
    });
}

+ (void)leakedTestCase {
    [APMToastView showToastViewWithMessage:@"产生泄漏"];

    char *tmp;
    int size = 1024 * 5;
    tmp = malloc(size);
    memset(tmp, 1, size);
    NSLog(@"创造泄漏 %p", tmp);
    tmp = NULL;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [APMToastView showToastViewWithMessage:@"检测泄漏"];
        [APMController leakDump];
    });
}

@end
