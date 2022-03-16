//
//  APMMemoryStatisitcsCenter.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  监控内存

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef  void (^MemoryCallbackHandler)(double memory);

@interface APMMemoryStatisitcsCenter : NSObject

+ (instancetype)shareMemoryCenter;

/// 开始监测
- (void)start;

/// 停止监测
- (void)stop;

/// 设置OOM触定阈值.默认为当前设备物理内存50%
- (void)setOverFlowLimitMemoryValue:(double)memoryValue;

/// 内存刷新回调
- (void)setMemoryInfoHandler:(MemoryCallbackHandler _Nonnull)memoryHandler;
@end

NS_ASSUME_NONNULL_END
