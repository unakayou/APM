//
//  APMMemoryStatisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMMemoryStatisitcsCenter.h"
#import "APMMemoryUtil.h"
#import "APMRebootMonitor.h"
#import "APMSharedThread.h"

@interface APMMemoryStatisitcsCenter()
@property (nonatomic, assign) double maxMemoryValue;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) APMSharedThread *sharedThread;        // 使用共享线程
@property (nonatomic,   copy) MemoryCallbackHandler memoryHandler;
@end

@implementation APMMemoryStatisitcsCenter

- (instancetype)initSingleton {
    if (self = [super init]) {
        self.maxMemoryValue = [APMMemoryUtil getTotalMemory] / 2;
        self.sharedThread = [APMSharedThread shareDefaultThread];
        [_sharedThread start];
    }
    return self;
}

- (void)setOverFlowLimitMemoryValue:(double)memoryValue {
    self.maxMemoryValue = memoryValue;
}

- (void)setMemoryInfoHandler:(MemoryCallbackHandler)memoryHandler {
    self.memoryHandler = memoryHandler;
}

- (void)start {
    self.timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateMemory) userInfo:nil repeats:YES];
    [_sharedThread addTimer:_timer];
}

- (void)stop {
    if ([_timer isValid]) {
        [_timer invalidate];
        self.timer = nil;
    }
}

- (void)updateMemory {
    double physFootprintMemory = [APMMemoryUtil physFootprintMemory];
    if (physFootprintMemory >= _maxMemoryValue) {
        APMLogDebug(@"⚠️ 警告:内存即将达到阈值");
        [APMRebootMonitor applicationWillOOM:physFootprintMemory];
    }
    if (self.memoryHandler) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.memoryHandler(physFootprintMemory);
        });
    }
}

#pragma mark - 单例初始化
+ (instancetype)shareMemoryCenter {
    static dispatch_once_t _onceToken;
    static APMMemoryStatisitcsCenter *_center = nil;
    dispatch_once(&_onceToken, ^{
        _center = [[super allocWithZone:NULL] initSingleton];
    });
    return _center;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [APMMemoryStatisitcsCenter shareMemoryCenter];
}

- (id)copyWithZone:(NSZone *)zone {
    return [APMMemoryStatisitcsCenter shareMemoryCenter];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [APMMemoryStatisitcsCenter shareMemoryCenter];
}

- (instancetype)init {
    return [APMMemoryStatisitcsCenter shareMemoryCenter];
}
@end
