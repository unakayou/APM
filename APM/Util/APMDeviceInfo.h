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

@end

NS_ASSUME_NONNULL_END
