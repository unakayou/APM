//
//  APMMemoryStatisitcsThread.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  共享使用的线程

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMSharedThread : NSObject

+ (instancetype)shareDefaultThread;

/// 启动线程
- (void)start;

/// 停止线程
- (void)stop;

/// 创建一个Timer
- (APMSharedThread *)scheduledTimerWithKey:(NSString *)key
                              timeInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     block:(void (^)(APMSharedThread *thread))block;

/// 停止Timer
- (void)invalidateTimerWithKey:(NSString *)key;

/// 执行任务 (功能未完善)
- (BOOL)executeTask:(void (^)(void))task;

@end

NS_ASSUME_NONNULL_END
