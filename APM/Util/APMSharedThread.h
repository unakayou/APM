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

/// 添加Timer (立刻 run)
- (BOOL)addTimer:(NSTimer *)timer;

/// 删除Timer (立刻停止)
- (void)removeTimer:(NSTimer *)timer;

/// 执行任务 (功能未完善)
- (BOOL)executeTask:(void (^)(void))task;
@end

NS_ASSUME_NONNULL_END
