//
//  APMController.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  主入口

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMController : NSObject

/// 开启CPU监控
+ (void)startCPUMonitor;
+ (void)stopCPUMonitor;

/// 开启内存监控
+ (void)startMemoryMonitor;
+ (void)stopMemoryMonitor;

/// 开启OOM监控
+ (void)startOOMMonitor;
+ (void)stopOOMMonitor;

/// 开启malloc监控
+ (void)startMallocMonitor;
+ (void)stopMallocMonitor;

@end

NS_ASSUME_NONNULL_END
