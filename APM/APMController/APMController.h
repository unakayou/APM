//
//  APMController.h
//  APM
//
//  Created by unakayou on 2022/3/23.
//
//  主入口

#import <Foundation/Foundation.h>
#import "APMDefines.h"

NS_ASSUME_NONNULL_BEGIN
typedef  void (^CPUCallbackHandler)(double usage);
typedef  void (^MemoryCallbackHandler)(Float32 memory);
typedef  void (^FPSCallbackHandler)(int fps);

@interface APMController : NSObject

/// 启动 (最后只暴露本启动接口)
+ (void)startWithAppid:(NSString *)appid config:(id)config;

/// 启动时间
+ (NSTimeInterval)launchTime;

/// CPU监控
+ (void)startCPUMonitor;
+ (void)stopCPUMonitor;
+ (void)setCPUUsageHandler:(CPUCallbackHandler _Nonnull)usageHandler;

+ (void)startFPSMonitor;
+ (void)stopFPSMonitor;
+ (void)setFPSValueHandler:(FPSCallbackHandler _Nonnull)FPSHandler;

/// 内存监控
+ (void)startMemoryMonitor;
+ (void)stopMemoryMonitor;
+ (void)setMemoryInfoHandler:(MemoryCallbackHandler _Nonnull)memoryHandler;

/// OOM监控
+ (void)startOOMMonitor;
+ (void)stopOOMMonitor;
+ (APMRebootType)rebootType;
+ (NSString *)rebootTypeString;

/// malloc监控
+ (void)startMallocMonitor;
+ (void)stopMallocMonitor;

@end

NS_ASSUME_NONNULL_END
