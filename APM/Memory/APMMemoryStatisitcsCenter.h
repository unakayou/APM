//
//  APMMemoryStatisitcsCenter.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  监控内存

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef  void (^MemoryCallbackHandler)(Float32 memory);

@interface APMMemoryStatisitcsCenter : NSObject

/// 开始
+ (void)start;

/// 停止
+ (void)stop;

/// 设置OOM触定阈值.单位MB
+ (void)setOverFlowLimitMemoryUsage:(uint32_t)maxMemoryUsage;

/// 内存刷新回调
+ (void)setMemoryInfoHandler:(MemoryCallbackHandler _Nonnull)memoryHandler;

@end

NS_ASSUME_NONNULL_END
