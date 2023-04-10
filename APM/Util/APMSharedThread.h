//
//  APMMemoryStatisitcsThread.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  共享使用的线程

#import <Foundation/Foundation.h>
@class APMSharedThreadTimer;
typedef void(^APMSharedThreadTimerCallback)(APMSharedThreadTimer *);

@interface APMSharedThreadTimer : NSObject
@property (nonatomic, copy)   NSString *key;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, assign) NSTimeInterval interval;
@property (nonatomic, copy)   APMSharedThreadTimerCallback callback;
@end

@interface APMSharedThread : NSObject

+ (instancetype)shareDefaultThread;

- (void)setName:(NSString *)name;

/// 启动线程
- (void)start;

/// 停止线程
- (void)stop;

/// 创建一个Timer
- (APMSharedThreadTimer *)scheduledTimerWithKey:(NSString *)key
                                   timeInterval:(NSTimeInterval)interval
                                        repeats:(BOOL)repeats
                                          block:(void (^)(APMSharedThreadTimer *timer))block;

/// 停止Timer
- (void)invalidateTimerWithKey:(NSString *)key;

/// 执行任务 (功能未完善)
- (BOOL)executeTask:(void (^)(void))task;

@end

