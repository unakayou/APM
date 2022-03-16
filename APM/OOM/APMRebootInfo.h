//
//  APMRebootInfo.h
//  APM
//
//  Created by unakayou on 2022/3/9.
//
//  重启信息,用于判断OOM

#import <Foundation/Foundation.h>
#import "APMBaseEncodeModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface APMRebootInfo : APMBaseEncodeModel
@property (nonatomic, assign, getter=isAppEnterForeground)   BOOL appEnterForeground;   // 进入前台
@property (nonatomic, assign, getter=isAppEnterBackground)   BOOL appEnterBackground;   // 进入后台
@property (nonatomic, assign, getter=isAppCrashed)           BOOL appCrashed;           // 崩溃
@property (nonatomic, assign, getter=isAppQuitByExit)        BOOL appQuitByExit;        // exit()退出
@property (nonatomic, assign, getter=isAppQuitByUser)        BOOL appQuitByUser;        // 用户手动退出
@property (nonatomic, assign, getter=isAppMainThreadBlocked) BOOL appMainThreadBlocked; // 主线程卡死退出
@property (nonatomic, assign) double overLimitMemory;       // 上次超过阈值内存值
@property (nonatomic, assign) uint64_t appLaunchTimeStamp;  // 启动时间戳,判断是否重启
@property (nonatomic, strong) NSString *appUUID;            // 主模块UUID,判断是否修改过image
@property (nonatomic, strong) NSString *osVersion;          // 版本号,判断是否升级
+ (instancetype)lastBootInfo;
- (BOOL)saveInfo;
@end

NS_ASSUME_NONNULL_END
