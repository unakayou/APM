//
//  APMPathUtil.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  路径工具类

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface APMPathUtil : NSObject

/// 根目录: Library/Caches/com.platform.apmsdk/
+ (NSString *)rootPath;

/// 重启信息路径: Library/Caches/com.platform.apmsdk/rebootInfo.dat
+ (NSString *)rebootInfoArchPatch;
@end

NS_ASSUME_NONNULL_END
