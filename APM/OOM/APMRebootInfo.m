//
//  APMRebootInfo.m
//  APM
//
//  Created by unakayou on 2022/3/9.
//

#import "APMRebootInfo.h"
#import "APMPathUtil.h"

@implementation APMRebootInfo

+ (instancetype)lastBootInfo {
    static APMRebootInfo *_lastBootInfo = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        @try {
            _lastBootInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[APMPathUtil rebootInfoArchPatch]];
        } @catch (NSException *exception) {
            APMLogDebug(@"%@",exception);
        } @finally {
            if (_lastBootInfo == nil) {
                _lastBootInfo = [[APMRebootInfo alloc] init];
            }
        }
    });
    return _lastBootInfo;
}

- (BOOL)saveInfo {
    BOOL bRet = NO;
    @try {
        bRet = [NSKeyedArchiver archiveRootObject:self toFile:[APMPathUtil rebootInfoArchPatch]];
    } @catch (NSException *exception) {
        APMLogDebug(@"%@",exception);
    } @finally {
        if (!bRet) {
            APMLogDebug(@"保存启动信息失败");
        }
    }
    return bRet;
}

@end
