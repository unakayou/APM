//
//  APMPathUtil.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  路径工具类

#import <Foundation/Foundation.h>

@interface APMPathUtil : NSObject

/// 根目录: Library/Caches/com.platform.apmsdk/
+ (NSString *)rootPath;

/// 重启信息路径: Library/Caches/com.platform.apmsdk/rebootInfo.dat
+ (NSString *)rebootInfoArchPath;

/// Malloc地址记录
+ (NSString *)mallocInfoPath;
@end
