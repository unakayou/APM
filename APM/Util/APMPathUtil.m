//
//  APMPathUtil.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMPathUtil.h"
#define APM_SDK_DOMAIN @"com.platform.apmsdk"

@implementation APMPathUtil
+ (NSString *)rootPath {
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    rootPath = [rootPath stringByAppendingPathComponent:APM_SDK_DOMAIN];
    if ([[NSFileManager defaultManager] fileExistsAtPath:rootPath] == NO) {
        [[NSFileManager defaultManager] createDirectoryAtPath:rootPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return rootPath;
}

+ (NSString *)rebootInfoArchPatch {
    NSString *rootPath = [self rootPath];
    NSString *rebootInfoArchPath = [rootPath stringByAppendingPathComponent:@"rebootInfo.dat"];
    return rebootInfoArchPath;
}
@end
