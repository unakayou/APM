//
//  APMRebootAnalyzer.h
//  APM
//
//  Created by unakayou on 2022/3/14.
//
//  获取上次启动状态

#import <Foundation/Foundation.h>
#import "APMDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface APMRebootMonitor : NSObject
@property (nonatomic, assign, class, readonly) APMRebootType rebootType;
@property (nonatomic,   weak, class, readonly) NSString *rebootTypeString;

/// 开始
+ (void)start;

/// 停止
+ (void)stop;

/// 卡顿 (需要卡顿模块调用)
+ (void)applicationMainThreadBlocked;
+ (void)applicationMainThreadBlockeResumed;

/// 崩溃 (需要崩溃模块调用)
+ (void)applicationCrashed;

/// 可能发生OOM时调用.用于记录当前内存值
+ (void)applicationWillOOM:(double)memoryValue;
@end

NS_ASSUME_NONNULL_END
