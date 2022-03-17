//
//  APMMemoryStatisitcsThread.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMSharedThread.h"
#import "APMLogManager.h"
#import <pthread.h>

@interface APMSharedThread ()
@property (nonatomic, strong) NSRunLoop *runLoop;
@property (nonatomic, strong) NSThread *insideThread;
@property (nonatomic, assign) BOOL shouldKeepRunning;
@property (nonatomic, strong) NSPointerArray *timerPointArray;
@end

@implementation APMSharedThread

#pragma mark - Public
- (void)start {
    [self startNewThread];
}

- (void)stop {
    [self performSelector:@selector(_stop) onThread:_insideThread withObject:nil waitUntilDone:NO];
}

- (void)addTimer:(NSTimer *)timer {
    [self performSelector:@selector(_addTimer:) onThread:_insideThread withObject:timer waitUntilDone:NO];
}

- (void)executeTask:(void (^)(void))task {
    [self performSelector:@selector(_executeTask:) onThread:_insideThread withObject:task waitUntilDone:NO];
}

#pragma mark - Private
- (instancetype)initSingleton {
    if (self = [super init]) {
        self.timerPointArray = [NSPointerArray weakObjectsPointerArray];
    }
    return self;
}

/// 创建真实线程
static pthread_mutex_t _sharedThreadLock;
- (void)startNewThread {
    pthread_mutex_lock(&_sharedThreadLock);
    if (_insideThread == nil) {
        // 创建后立刻启动线程,进行等待
        self.insideThread = [[NSThread alloc] initWithTarget:self selector:@selector(threadLaunch) object:nil];
        [_insideThread setName:[NSString stringWithFormat:@"%@", self.class]];
        [_insideThread start];

        _insideThread.deallocObject = [DeallocLogObject new];
        _insideThread.deallocObject.name = @"InsideThread";
    }
    pthread_mutex_unlock(&_sharedThreadLock);
}

/// 线程启动RunLoop
- (void)threadLaunch {
    _shouldKeepRunning = YES;
    APMLogDebug(@"%s - %@", __FUNCTION__, [NSThread currentThread]);
    
    self.runLoop = [NSRunLoop currentRunLoop];
    [_runLoop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    
    while (_shouldKeepRunning && [_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)_stop {
    self.insideThread = nil;
    self.shouldKeepRunning = NO;
    for (int i = (int)_timerPointArray.count - 1; i >= 0; i--) {
        NSTimer *timer = (NSTimer *)[_timerPointArray pointerAtIndex:i];
        if ([timer isValid]) {
            [timer invalidate];
        }
        [_timerPointArray removePointerAtIndex:i];
    }
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)_addTimer:(NSTimer *)timer {
    [_timerPointArray addPointer:(__bridge void * _Nullable)(timer)];
    timer.deallocObject = [[DeallocLogObject alloc] init];
    timer.deallocObject.name = [NSString stringWithFormat:@"APMSharedThread - %@", timer];

    APMLogDebug(@"⚠️ %@ - %@ 启动", self.class, timer);
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)_executeTask:(void(^)(void))task {
    task();
}

#pragma mark - 单例初始化
+ (instancetype)shareDefaultThread {
    static dispatch_once_t _onceToken;
    static APMSharedThread *_thread = nil;
    dispatch_once(&_onceToken, ^{
        _thread = [[super allocWithZone:NULL] initSingleton];
    });
    return _thread;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [APMSharedThread shareDefaultThread];
}

- (id)copyWithZone:(NSZone *)zone {
    return [APMSharedThread shareDefaultThread];
}

- (id)mutableCopyWithZone:(NSZone *)zone {
    return [APMSharedThread shareDefaultThread];
}

- (instancetype)init {
    return [APMSharedThread shareDefaultThread];
}

- (void)addObserver {
    CFRunLoopObserverRef observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, kCFRunLoopAllActivities, YES, 0, ^(CFRunLoopObserverRef observer, CFRunLoopActivity activity) {
        switch (activity) {
            case kCFRunLoopEntry:
                NSLog(@"SharedThread RunLoop - 进入");
                break;
            case kCFRunLoopExit:
                NSLog(@"SharedThread RunLoop - 退出");
                break;
            default:
                break;
        }
    });
    CFRunLoopAddObserver(CFRunLoopGetCurrent(), observer, kCFRunLoopDefaultMode);
}
@end
