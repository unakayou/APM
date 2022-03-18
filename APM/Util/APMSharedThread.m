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
@property (nonatomic, strong) NSHashTable *timerHashTable;
@end

@implementation APMSharedThread

#pragma mark - Public
static pthread_mutex_t _sharedThreadLock;
- (void)start {
    pthread_mutex_lock(&_sharedThreadLock);
    if (_insideThread == nil) {
        // 创建后立刻启动线程,进行等待
        self.insideThread = [[NSThread alloc] initWithTarget:self selector:@selector(_start) object:nil];
        [_insideThread setName:[NSString stringWithFormat:@"%@", self.class]];
        [_insideThread start];
    }
    pthread_mutex_unlock(&_sharedThreadLock);
}

- (void)stop {
    if (!_insideThread) return;
    [self performSelector:@selector(_stop) onThread:_insideThread withObject:nil waitUntilDone:NO];
}

- (BOOL)addTimer:(NSTimer *)timer {
    if (!_insideThread || !timer) return NO;
    [self performSelector:@selector(_addTimer:) onThread:_insideThread withObject:timer waitUntilDone:NO];
    return YES;    
}

- (void)removeTimer:(NSTimer *)timer {
    if (!timer) return;
    [self performSelector:@selector(_removeTimer:) onThread:_insideThread withObject:timer waitUntilDone:NO];
}

- (BOOL)executeTask:(void (^)(void))task {
    if (!_insideThread || !task) return NO;
    [self performSelector:@selector(_executeTask:) onThread:_insideThread withObject:task waitUntilDone:NO];
    return YES;
}

#pragma mark - Private

/// 线程启动RunLoop
- (void)_start {
    self.shouldKeepRunning = YES;
    self.timerHashTable = [NSHashTable weakObjectsHashTable];
    self.runLoop = [NSRunLoop currentRunLoop];
    [_runLoop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    APMLogDebug(@"⚠️ 线程启动 - %@", [NSThread currentThread]);
    while (_shouldKeepRunning && [_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)_stop {
    _insideThread.deallocObject = [DeallocLogObject new];
    _insideThread.deallocObject.lastWord = [NSString stringWithFormat:@"线程结束 - %@", [NSThread currentThread]];
    
    NSArray *timerArray = _timerHashTable.allObjects;
    for (int i = (int)timerArray.count - 1; i >= 0; i--) {
        NSTimer *timer = (NSTimer *)[timerArray objectAtIndex:i];
        if ([timer isValid]) {
            [timer invalidate];
        }
    }
    self.runLoop = nil;
    self.insideThread = nil;
    self.shouldKeepRunning = NO;
    [_timerHashTable removeAllObjects];
    CFRunLoopStop(CFRunLoopGetCurrent());
}

- (void)_addTimer:(NSTimer *)timer {
    if (![_timerHashTable containsObject:timer]) {
        [_timerHashTable addObject:timer];
    
#if DEBUG
        if (!timer.deallocObject) {
            timer.deallocObject = [[DeallocLogObject alloc] init];
            timer.deallocObject.lastWord = [NSString stringWithFormat:@"Timer销毁 - %@", timer];
        }
#endif
        APMLogDebug(@"⚠️ Timer 加入 RunLoop - %@ ", timer);
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    }
}

- (void)_removeTimer:(NSTimer *)timer {
    if ([timer isValid]) {
        [timer invalidate];
    }
    [_timerHashTable removeObject:timer];
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

- (instancetype)initSingleton {
    if (self = [super init]) {
        
    }
    return self;
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
