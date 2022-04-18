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
typedef void (^CPUCallbackHandler)(double usage);
typedef void (^MemoryCallbackHandler)(Float32 memory);
typedef void (^FPSCallbackHandler)(int fps);
typedef void (^MallocExceedCallback)(size_t bytes, NSString *stack);

@interface APMController : NSObject

/// 启动 (最后只暴露本启动接口)
+ (void)startWithAppid:(NSString *)appid config:(id)config;

/// 启动时间
+ (NSTimeInterval)launchTime;

/// CPU监控 (性能消耗: 中等)
+ (void)startCPUMonitor;
+ (void)stopCPUMonitor;
+ (void)setCPUUsageHandler:(CPUCallbackHandler _Nonnull)usageHandler;

/// FPS监控 (性能消耗: 中等)
+ (void)startFPSMonitor;
+ (void)stopFPSMonitor;
+ (void)setFPSValueHandler:(FPSCallbackHandler _Nonnull)FPSHandler;

/// 内存监控 (性能消耗: 低)
+ (void)startMemoryMonitor;
+ (void)stopMemoryMonitor;
+ (void)setMemoryInfoHandler:(MemoryCallbackHandler _Nonnull)memoryHandler;

/// OOM监控 (性能消耗: 极低)
+ (void)startOOMMonitor;
+ (void)stopOOMMonitor;
+ (APMRebootType)rebootType;
+ (NSString *)rebootTypeString;

/// malloc监控 (性能消耗: 高)
/// @param functionLimitSize 单独函数累积开辟内存阈值
/// @param singleLimitSize 单次开辟内存阈值
+ (void)startMallocMonitorWithFunctionLimitSize:(size_t)functionLimitSize singleLimitSize:(size_t)singleLimitSize;

/// 函数累积开辟超限
/// @param callback 回调
+ (void)setFunctionMallocExceedCallback:(MallocExceedCallback)callback;

/// 单次开辟直接超限
/// @param callback 回调
+ (void)setSingleMallocExceedCallback:(MallocExceedCallback)callback;

/// 停止监控.降低性能消耗
+ (void)stopMallocMonitor;

/// 内存泄漏检测 (性能消耗: 极高)
+ (void)leakExamine;
@end

NS_ASSUME_NONNULL_END
