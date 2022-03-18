//
//  APMCPUStatisitcsCenter.h
//  APM
//
//  Created by unakayou on 2022/3/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef  void (^CPUCallbackHandler)(double usage);

@interface APMCPUStatisitcsCenter : NSObject

/// 开始
+ (void)start;

/// 停止
+ (void)stop;

/// 设置阈值,默认值 0.8
+ (void)setLimitCPUUSagePercent:(float)maxCPUUsagePercent;

/// CPU占用刷新回调
+ (void)setCPUUsageHandler:(CPUCallbackHandler _Nonnull)usageHandler;

@end

NS_ASSUME_NONNULL_END
