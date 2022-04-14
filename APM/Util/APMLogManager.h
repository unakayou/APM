//
//  APMLogUtil.h
//  APM
//
//  Created by unakayou on 2022/3/14.
//
//  日志输出工具类

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

#define APMLogDebug(...) NSLog(__VA_ARGS__, nil)

@interface APMLogManager : NSObject

@end

NS_ASSUME_NONNULL_END
