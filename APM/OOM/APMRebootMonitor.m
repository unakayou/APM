//
//  APMRebootAnalyzer.m
//  APM
//
//  Created by unakayou on 2022/3/14.
//

#import <UIKit/UIKit.h>
#import <pthread.h>
#import "APMLogManager.h"
#import "APMRebootInfo.h"
#import "APMDeviceInfo.h"
#import "APMRebootMonitor.h"

@implementation APMRebootMonitor
@dynamic rebootType, rebootTypeString;
static double _lastOverLimitMemory; // 上次OOM时的内存占用
static APMRebootType _rebootType = APMRebootTypeBegin;
static pthread_mutex_t _rebootMonitorLock;

+ (void)checkRebootType {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    
    // ⚠️ 判断顺序不可变
    if (info.isAppCrashed) {
        // 崩溃退出
        _rebootType = APMRebootTypeCrash;
    } else if (info.isAppQuitByUser) {
        // 用户退出
        _rebootType = APMRebootTypeQuitByUser;
    } else if (info.isAppQuitByExit) {
        // exit()
        _rebootType = APMRebootTypeQuitByExit;
    } else if ([self appVersionChange]) {
        // 判断App image是否有修改
        _rebootType = APMRebootTypeAppVersionChange;
    } else if ([self osVersionChange]) {
        // 系统升级
        _rebootType = APMRebootTypeOSVersionChange;
    } else if ([self osReboot]) {
        // 系统重启
        _rebootType = APMRebootTypeOSReboot;
    } else if (info.isAppEnterBackground) {
        // 后台OOM或Jestam
        _rebootType = APMRebootTypeBOOM;
    } else if (info.isAppEnterForeground) {
        if (info.isAppMainThreadBlocked) {
            // 前台卡死
            _rebootType = APMRebootTypeANR;
        } else {
            // 前台OOM
            _lastOverLimitMemory = info.overLimitMemory;
            _rebootType = APMRebootTypeFOOM;
        }
    } else {
        _rebootType = APMRebootTypeUnKnow;
    }
    
    APMLogDebug(@"⚠️ 重启类型: %@", APMRebootMonitor.rebootTypeString);
    
    info.appLaunchTimeStamp = (uint64_t)time(NULL);
    info.appUUID = [APMDeviceInfo mainMachOUUID];
    info.osVersion = [APMDeviceInfo systemVersion];
    info.overLimitMemory = 0;
    
    info.appCrashed = NO;
    info.appQuitByUser = NO;
    info.appQuitByExit = NO;
    info.appEnterBackground = NO;
    info.appEnterForeground = NO;
    info.appMainThreadBlocked = NO;
    
    // 启动后统计完毕,重置info一次
    [info saveInfo];
}

/// 根据MachO uuid判断 image是否有修改
+ (BOOL)appVersionChange {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    NSString *lastMainMachOUUID = info.appUUID;
    NSString *mainMachOUUID = [APMDeviceInfo mainMachOUUID];
    APMLogDebug(@"\n⚠️ UUID\n上次: %@\n本次: %@", lastMainMachOUUID, mainMachOUUID);
    return (lastMainMachOUUID != nil && ![lastMainMachOUUID isEqualToString:mainMachOUUID]);
}

/// 系统版本升级
+ (BOOL)osVersionChange {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    NSString *lastVersion = info.osVersion;
    NSString *currentVersion = [APMDeviceInfo systemVersion];
    APMLogDebug(@"\n⚠️ 版本\n上次: %@\n本次: %@", lastVersion, currentVersion);
    return ![lastVersion isEqualToString:currentVersion];
}

/// 系统重启
+ (BOOL)osReboot {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    uint64_t lastLaunchTimeStamp = info.appLaunchTimeStamp;
    uint64_t systemStartTimeStamp = [APMDeviceInfo systemLaunchTimeStamp];
    APMLogDebug(@"\n⚠️ 时间戳\n上次: %llu\n本次: %llu", systemStartTimeStamp, systemStartTimeStamp);
    return systemStartTimeStamp > lastLaunchTimeStamp;
}

/// 进后台
+ (void)applicationEnterBackground {
    APMLogDebug(@"⚠️ 进入后台");
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appEnterBackground = YES;
    info.appEnterForeground = NO;
    [info saveInfo];
}

/// 进前台
+ (void)applicationEnterForeground {
    APMLogDebug(@"⚠️ 进入前台");
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appEnterForeground = YES;
    info.appEnterBackground = NO;
    [info saveInfo];
}

/// 用户退出
+ (void)applicationQuitByUser {
    APMLogDebug(@"⚠️ 上滑退出");
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appQuitByUser = YES;
    [info saveInfo];
}

/// exit() 退出回调
void exitCallback(void) {
    APMLogDebug(@"⚠️ exit() 退出\n");
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appQuitByExit = YES;
    [info saveInfo];
}

void exitCallbackNull(void) {
    return;
}

/// 卡顿
+ (void)applicationMainThreadBlocked {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appMainThreadBlocked = YES;
    [info saveInfo];
}

+ (void)applicationCrashed {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.appCrashed = YES;
    [info saveInfo];
}

+ (void)applicationWillOOM:(double)memoryValue {
    APMRebootInfo *info = [APMRebootInfo lastBootInfo];
    info.overLimitMemory = memoryValue;
    [info saveInfo];
}

#pragma mark - 初始化
+ (void)notificationRegister {
    // 进后台
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];
    
    // 从活动状态进入非活动状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterBackground)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    // 程序进入前台, 未处于活动状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    // 程序进入前台, 处于活动状态
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationEnterForeground)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    // 程序被用户退出
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationQuitByUser)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];
    
    atexit(exitCallback);
}

#pragma mark - Public
+ (void)start {
    pthread_mutex_lock(&_rebootMonitorLock);
    if (_rebootType == APMRebootTypeBegin) {
        [self notificationRegister];
        [self checkRebootType];
    }
    pthread_mutex_unlock(&_rebootMonitorLock);
}

+ (void)stop {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    atexit(exitCallbackNull);
}

+ (APMRebootType)rebootType {
    return _rebootType;
}

+ (NSString *)rebootTypeString {
    NSString *rebootTypeString;
    switch (APMRebootMonitor.rebootType) {
        case APMRebootTypeUnKnow:
            rebootTypeString = @"未知";
            break;
        case APMRebootTypeBegin:
            rebootTypeString = @"错误";
            break;
        case APMRebootTypeQuitByUser:
            rebootTypeString = @"用户退出";
            break;
        case APMRebootTypeOSReboot:
            rebootTypeString = @"系统重启";
            break;
        case APMRebootTypeAppVersionChange:
            rebootTypeString = @"App更新";
            break;
        case APMRebootTypeOSVersionChange:
            rebootTypeString = @"系统更新";
            break;
        case APMRebootTypeQuitByExit:
            rebootTypeString = @"Exit()";
            break;
        case APMRebootTypeCrash:
            rebootTypeString = @"崩溃退出";
            break;
        case APMRebootTypeANR:
            rebootTypeString = @"卡死退出";
            break;
        case APMRebootTypeFOOM: {
            rebootTypeString = [NSString stringWithFormat:@"前台OOM (%.2fMB)", _lastOverLimitMemory];
        }
            break;
        case APMRebootTypeBOOM:
            rebootTypeString = @"后台退出";
            break;
        default:
            rebootTypeString = @"错误";
            break;
    }
    return rebootTypeString;
}
@end
