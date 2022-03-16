//
//  APMMemoryUtil.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  获取内存工具类

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMMemoryUtil : NSObject

/// 获取主模块UUID
+ (NSString *)mainMachOUUID;

/// 当前内存占用 (单位MB)
+ (double)physFootprintMemory;

/// 系统总内存 (单位MB)
+ (double)getTotalMemory;
@end

NS_ASSUME_NONNULL_END
