//
//  APMDeviceInfo.h
//  APM
//
//  Created by unakayou on 2022/3/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMDeviceInfo : NSObject
/// 系统版本号
+ (NSString *)systemVersion;

/// 系统开机时间戳
+ (uint64_t)systemLaunchTimeStamp;

/// 从屏幕点击App,到现在时间, 单位:毫秒
+ (NSTimeInterval)processStartTime;

/// 当前CPU占用百分比 (0.0f - 1.0f)
+ (Float32)currentCPUUsagePercent;

/// 获取主模块UUID
+ (NSString *)mainMachOUUID;

/// 当前内存占用 (单位MB)
+ (Float32)physFootprintMemory;

/// 系统总内存 (单位MB)
+ (Float32)totalMemory;

@end

NS_ASSUME_NONNULL_END
