//
//  APMMemoryStatisitcsThread.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMSharedThread.h"
#import "APMLogManager.h"
#import "APMDefines.h"
#import <pthread.h>

typedef void(^APMSharedThreadTimerCallback)(APMSharedThread *);
@interface APMSharedThreadTimer : NSObject
@property (nonatomic, copy)   NSString *key;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, copy)   APMSharedThreadTimerCallback callback;
@end

@implementation APMSharedThreadTimer
@end

@interface APMSharedThread ()
@property (nonatomic, strong) NSRunLoop *runLoop;
@property (nonatomic, strong) NSThread *insideThread;
@property (nonatomic, assign) BOOL shouldKeepRunning;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSTimer *>*timerDictionary;
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

/// 创建Timer, 需要waitUntilDone = YES
- (APMSharedThread *)scheduledTimerWithKey:(NSString *)key
                              timeInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     block:(void (^)(APMSharedThread * _Nonnull))block {
    if (!_insideThread || !key.length || interval <= 0 || !block) return nil;
    
    APMSharedThreadTimer *timer = [APMSharedThreadTimer new];
    timer.key = key;
    timer.interval = interval;
    timer.repeats = repeats;
    timer.callback = block;
    [self performSelector:@selector(_addTimer:) onThread:_insideThread withObject:timer waitUntilDone:YES];
    return self;
}

/// 停止Timer,需要waitUntilDone = YES
- (void)invalidateTimerWithKey:(NSString *)key {
    if (!key.length) return;
    [self performSelector:@selector(_invalidateTimerWithKey:) onThread:_insideThread withObject:key waitUntilDone:YES];
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
    self.runLoop = [NSRunLoop currentRunLoop];
    self.timerDictionary = [NSMutableDictionary new];
    
    [_runLoop addPort:[NSPort port] forMode:NSRunLoopCommonModes];
    APMLogDebug(@"⚠️ 线程启动 - %@", [NSThread currentThread]);
    while (_shouldKeepRunning && [_runLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);
}

- (void)_stop {
#if APM_DEALLOC_LOG_SWITCH
    _insideThread.deallocObject = [DeallocLogObject new];
    _insideThread.deallocObject.lastWord = [NSString stringWithFormat:@"线程销毁 - %@", [NSThread currentThread]];
#endif
    
    NSArray <NSString *>*keyArray = _timerDictionary.allKeys;
    for (int i = 0; i < keyArray.count; i++) {
        NSString *key = keyArray[i];
        NSTimer *timer = _timerDictionary[key];
        if ([timer isValid]) {
            [timer invalidate];
        }
        [_timerDictionary removeObjectForKey:key];
    }
    self.runLoop = nil;
    self.insideThread = nil;
    self.timerDictionary = nil;
    self.shouldKeepRunning = NO;
    CFRunLoopStop(CFRunLoopGetCurrent());
}

/// 创建新Timer添加到RunLoop中
- (void)_addTimer:(APMSharedThreadTimer *)timerObj {
    // 如果同一个Key存在之前的Timer,则覆盖之前的Timer.
    if ([_timerDictionary objectForKey:timerObj.key]) {
        [self _invalidateTimerWithKey:timerObj.key];
    }
    __weak typeof(self) weakSelf = self;
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timerObj.interval
                                                     repeats:timerObj.repeats
                                                       block:^(NSTimer * _Nonnull timer) {
        timerObj.callback(weakSelf);
    }];
//    APMLogDebug(@"⚠️ %@ - 加入 RunLoop", timer);
    [_timerDictionary setObject:timer forKey:timerObj.key];

#if APM_DEALLOC_LOG_SWITCH
    if (!timer.deallocObject) {
        timer.deallocObject = [[DeallocLogObject alloc] init];
        timer.deallocObject.lastWord = [NSString stringWithFormat:@"Timer销毁 - %@", timer];
    }
#endif
}

- (void)_invalidateTimerWithKey:(NSString *)key {
    NSTimer *timer = [_timerDictionary objectForKey:key];
    if (timer.isValid) {
        [timer invalidate];
    }
    [_timerDictionary removeObjectForKey:key];
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
    if (self = [super init]) {}
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
