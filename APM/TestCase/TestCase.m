//
//  OOMLauncher.m
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import "TestCase.h"
#import "APMToastView.h"
#import "APMRebootMonitor.h"

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
    
    TestCase *exitCase = [TestCase new];
    exitCase.name = @"Exit(0)";
    exitCase.caseBlock = ^{
        [TestCase exitCase];
    };
    
    NSMutableArray *allTestCase = [NSMutableArray new];
    [allTestCase addObject:oomCase];
    [allTestCase addObject:blockCase];
    [allTestCase addObject:crashCase];
    [allTestCase addObject:exitCase];
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
