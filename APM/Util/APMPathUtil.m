//
//  APMPathUtil.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMPathUtil.h"
#define APM_SDK_DOMAIN @"com.platform.apmsdk"

@implementation APMPathUtil

/// 确保文件夹存在
+ (BOOL)insurePathExist:(NSString *)path {
    if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
        return [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return YES;
}

+ (NSString *)rootPath {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    rootPath = [rootPath stringByAppendingPathComponent:APM_SDK_DOMAIN];
    if ([self insurePathExist:rootPath]) {
        return rootPath;
    } else {
        return nil;
    }
}

#define REBOOT_INFO_FILE @"rebootInfo.dat"
+ (NSString *)rebootInfoArchPath {
    NSString *rootPath = [self rootPath];
    NSString *rebootInfoArchPath = [rootPath stringByAppendingPathComponent:REBOOT_INFO_FILE];
    return rebootInfoArchPath;
}

#define MALLOC_INFO_DIR  @"MallocInfo"
+ (NSString *)mallocInfoPath {
    NSString *rootPath = [self rootPath];
    NSString *mallocInfoPath = [rootPath stringByAppendingPathComponent:MALLOC_INFO_DIR];
    [self insurePathExist:mallocInfoPath];

    NSString *fileName = [NSString stringWithFormat:@"%@-%.0f",MALLOC_INFO_DIR.lowercaseString, [[NSDate date] timeIntervalSince1970]];
    mallocInfoPath = [mallocInfoPath stringByAppendingPathComponent:fileName];
    return mallocInfoPath;
}

@end
