//
//  APMMemoryStatisitcsCenter.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMMemoryStatisitcsCenter.h"
#import "APMMemoryUtil.h"
#import "APMRebootMonitor.h"
#import "APMMemoryStatisitcsThread.h"

@interface APMMemoryStatisitcsCenter() {
    NSTimer *_timer;                        // 刷新内存
    APMMemoryStatisitcsThread *_thread;     // 开辟新线程
    NSRunLoop * _runLoop;                   // 新线程的runLoop
    BOOL _shouldKeepRunning;                // 是否继续运行runLoop
}
@property (nonatomic, assign) double maxMemoryValue;
@property (nonatomic, copy) MemoryCallbackHandler memoryHandler;    
@end

@implementation APMMemoryStatisitcsCenter

- (instancetype)initSingleton {
    if (self = [super init]) {
        self.maxMemoryValue = [APMMemoryUtil getTotalMemory] / 2;
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
    _shouldKeepRunning = YES;
    
    if (!_thread) {
        _thread = [[APMMemoryStatisitcsThread alloc] initWithTarget:self selector:@selector(threadLaunch) object:nil];
        _thread.name = [NSString stringWithFormat:@"%@", self.class];
        [_thread start];
    }
}

// 线程启动runLoop
- (void)threadLaunch {
    if (!_timer) {
        _timer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(updateMemory) userInfo:nil repeats:YES];
    }
        
    _runLoop = [NSRunLoop currentRunLoop];
    [_runLoop addTimer:_timer forMode:NSRunLoopCommonModes];
    while (_shouldKeepRunning && [_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
    APMLogDebug(@"RunLoop 结束");
}

- (void)stop {
    [self performSelector:@selector(__stop) onThread:_thread withObject:nil waitUntilDone:NO];
}

// 让子线程执行停止
- (void)__stop {
    APMLogDebug(@"停止内存监测");
    if (_timer.isValid) {
        [_timer invalidate];
    }
    
    _timer = nil;
    _thread = nil;
    _runLoop = nil;
    _shouldKeepRunning = NO;
    CFRunLoopStop(CFRunLoopGetCurrent());
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
